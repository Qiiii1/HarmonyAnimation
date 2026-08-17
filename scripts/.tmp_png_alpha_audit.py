#!/usr/bin/env python3
import glob
import subprocess
import struct
import sys
import zlib
from collections import Counter


def paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def decode_rgba(source):
    if isinstance(source, bytes):
        data = source
    else:
        with open(source, "rb") as f:
            data = f.read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    pos = 8
    chunks = []
    width = height = None
    while pos < len(data):
        n = struct.unpack(">I", data[pos:pos + 4])[0]
        kind = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + n]
        pos += 12 + n
        if kind == b"IHDR":
            width, height, depth, color_type, compression, filtering, interlace = struct.unpack(">IIBBBBB", body)
            assert (depth, color_type, compression, filtering, interlace) == (8, 6, 0, 0, 0)
        elif kind == b"IDAT":
            chunks.append(body)
        elif kind == b"IEND":
            break
    raw = zlib.decompress(b"".join(chunks))
    stride = width * 4
    rows = []
    p = 0
    previous = bytearray(stride)
    for _ in range(height):
        filter_type = raw[p]
        p += 1
        encoded = raw[p:p + stride]
        p += stride
        row = bytearray(stride)
        for i, value in enumerate(encoded):
            left = row[i - 4] if i >= 4 else 0
            above = previous[i]
            upper_left = previous[i - 4] if i >= 4 else 0
            if filter_type == 0:
                predictor = 0
            elif filter_type == 1:
                predictor = left
            elif filter_type == 2:
                predictor = above
            elif filter_type == 3:
                predictor = (left + above) // 2
            elif filter_type == 4:
                predictor = paeth(left, above, upper_left)
            else:
                raise ValueError(filter_type)
            row[i] = (value + predictor) & 255
        rows.append(row)
        previous = row
    return width, height, rows


def compare_head(path):
    old_data = subprocess.check_output(["git", "show", f"HEAD:{path}"])
    old_w, old_h, old_rows = decode_rgba(old_data)
    new_w, new_h, new_rows = decode_rgba(path)
    assert (old_w, old_h) == (new_w, new_h)
    changed = 0
    changed_alpha_gt_32 = 0
    changed_alpha_gt_15 = 0
    changed_rgb = 0
    changed_to_nonzero_alpha = 0
    removed_predicate_misses = 0
    max_removed_alpha = -1
    old_changed = Counter()
    new_changed = Counter()
    for old_row, new_row in zip(old_rows, new_rows):
        for i in range(0, len(old_row), 4):
            old = tuple(old_row[i:i + 4])
            new = tuple(new_row[i:i + 4])
            if old == new:
                continue
            changed += 1
            r, g, b, a = old
            nr, ng, nb, na = new
            changed_alpha_gt_32 += a > 32
            changed_alpha_gt_15 += a > 15
            changed_rgb += (r, g, b) != (nr, ng, nb)
            changed_to_nonzero_alpha += na != 0
            removed_predicate_misses += not (a <= 15 and max(r, g, b) <= 16)
            max_removed_alpha = max(max_removed_alpha, a)
            old_changed[old] += 1
            new_changed[new] += 1
    print(path.rsplit('/', 1)[-1],
          "changed", changed,
          "oldAlpha>32", changed_alpha_gt_32,
          "oldAlpha>15", changed_alpha_gt_15,
          "RGBchanged", changed_rgb,
          "newAlpha!=0", changed_to_nonzero_alpha,
          "predicateMiss", removed_predicate_misses,
          "maxOldAlpha", max_removed_alpha,
          "topOld", old_changed.most_common(4),
          "topNew", new_changed.most_common(2))


def summarize(path):
    w, h, rows = decode_rgba(path)
    alpha_bins = Counter()
    transparent_rgb = Counter()
    low_lumas = []
    edge_samples = []
    bbox = [w, h, -1, -1]
    low_black = 0
    low_nonzero = 0
    semi_black = 0
    semi_total = 0
    opaque_black = 0
    opaque_total = 0
    premul_violations = 0
    alpha_exact = Counter()
    category_bbox = {
        "low_black": [w, h, -1, -1],
        "mid_black": [w, h, -1, -1],
        "colored": [w, h, -1, -1],
    }
    low_black_rows = Counter()
    for y, row in enumerate(rows):
        for x in range(w):
            r, g, b, a = row[4*x:4*x+4]
            alpha_exact[a] += 1
            if a == 0:
                alpha_bins["0"] += 1
                transparent_rgb[(r, g, b)] += 1
            elif a == 255:
                alpha_bins["255"] += 1
                opaque_total += 1
                if max(r, g, b) <= 16:
                    opaque_black += 1
            else:
                alpha_bins["1-15" if a <= 15 else "16-63" if a <= 63 else "64-127" if a <= 127 else "128-254"] += 1
                semi_total += 1
                if max(r, g, b) <= 16:
                    semi_black += 1
                if max(r, g, b) > a:
                    premul_violations += 1
                if a <= 31:
                    low_lumas.append((54*r + 183*g + 19*b) / 256)
                    if max(r, g, b) <= 16:
                        low_black += 1
                        low_black_rows[y] += 1
                        box = category_bbox["low_black"]
                        box[0], box[1], box[2], box[3] = min(box[0], x), min(box[1], y), max(box[2], x), max(box[3], y)
                    else:
                        low_nonzero += 1
            if 32 <= a <= 127 and max(r, g, b) <= 16:
                box = category_bbox["mid_black"]
                box[0], box[1], box[2], box[3] = min(box[0], x), min(box[1], y), max(box[2], x), max(box[3], y)
            if a > 0 and max(r, g, b) > 32:
                box = category_bbox["colored"]
                box[0], box[1], box[2], box[3] = min(box[0], x), min(box[1], y), max(box[2], x), max(box[3], y)
            if a:
                bbox[0] = min(bbox[0], x)
                bbox[1] = min(bbox[1], y)
                bbox[2] = max(bbox[2], x)
                bbox[3] = max(bbox[3], y)
            if 1 <= a <= 64:
                edge_samples.append((a, r, g, b, x, y))
    edge_samples.sort()
    print(path.rsplit('/', 1)[-1], f"{w}x{h}", "bbox", bbox)
    print("  alpha", dict(alpha_bins))
    print("  exact alpha top", alpha_exact.most_common(12))
    print("  transparent RGB", transparent_rgb.most_common(3))
    print("  low-alpha<=31", len(low_lumas), "black<=16", low_black, "nonblack", low_nonzero,
          "mean_luma", round(sum(low_lumas)/len(low_lumas), 1) if low_lumas else None)
    print("  semi black", f"{semi_black}/{semi_total}", "opaque black", f"{opaque_black}/{opaque_total}",
          "straight-alpha-evidence(maxRGB>A)", f"{premul_violations}/{semi_total}")
    print("  bboxes", category_bbox)
    if low_black_rows:
        heavy_rows = [(y, n) for y, n in low_black_rows.items() if n >= w // 4]
        print("  low-black rows", (min(low_black_rows), max(low_black_rows)),
              "heavy row range/count", (heavy_rows[0], heavy_rows[-1], len(heavy_rows)) if heavy_rows else None,
              "densest", low_black_rows.most_common(5))
    print("  smallest edge samples", edge_samples[:8])


compare_mode = "--compare-head" in sys.argv
paths = [arg for arg in sys.argv[1:] if arg != "--compare-head"] or glob.glob("entry/src/main/resources/base/media/module*.png")
for file_path in sorted(paths,
                        key=lambda p: int(p.rsplit("module", 1)[1].split(".", 1)[0])):
    if compare_mode:
        compare_head(file_path)
    else:
        summarize(file_path)
