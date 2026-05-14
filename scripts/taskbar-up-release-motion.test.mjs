import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const helperPath = path.resolve(
  'entry/src/main/ets/pages/TaskbarUpReleaseMotion.ets'
);

function loadHelper() {
  const source = fs.readFileSync(helperPath, 'utf8');
  const withoutInterfaces = source.replace(/export interface[\s\S]*?\n}\n/g, '');
  const jsSource = withoutInterfaces
    .replace(/export const ([A-Za-z0-9_]+): [^=]+ =/g, 'const $1 =')
    .replace(/export function ([A-Za-z0-9_]+)\(([^)]*)\): [^{]+ \{/g, 'function $1($2) {')
    .replace(/\): [A-Za-z0-9_]+ \{/g, ') {')
    .replace(/([A-Za-z0-9_]+): number/g, '$1')
    .replace(/: TaskbarUpReleaseDurations/g, '');

  const context = {};
  vm.createContext(context);
  vm.runInContext(`${jsSource}
this.taskbarUpReleaseDurations = taskbarUpReleaseDurations;
this.taskbarUpReleaseEaseOut = taskbarUpReleaseEaseOut;
this.taskbarUpReleaseEaseIn = taskbarUpReleaseEaseIn;`, context);
  return context;
}

const {
  taskbarUpReleaseDurations,
  taskbarUpReleaseEaseOut,
  taskbarUpReleaseEaseIn
} = loadHelper();

const durations = taskbarUpReleaseDurations(1000, 0.3);
assert.equal(durations.forwardMs + durations.returnMs, 1000);
assert.equal(durations.forwardMs, 300);
assert.equal(durations.returnMs, 700);

assert.ok(
  taskbarUpReleaseEaseOut(0.5) > 0.5,
  'right-moving overshoot segment should start fast and slow down'
);
assert.ok(
  taskbarUpReleaseEaseIn(0.5) < 0.5,
  'return segment should start slow and speed up'
);
assert.equal(taskbarUpReleaseEaseOut(0), 0);
assert.equal(taskbarUpReleaseEaseOut(1), 1);
assert.equal(taskbarUpReleaseEaseIn(0), 0);
assert.equal(taskbarUpReleaseEaseIn(1), 1);
