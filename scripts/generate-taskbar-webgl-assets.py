from __future__ import annotations

import base64
import json
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
RAWFILE_HTML = ROOT / "entry/src/main/resources/rawfile/taskbar_up_webgl.html"
RAW_TEXTURE_MARKER = "window.TASKBAR_UP_WEBGL_RAW_TEXTURES = "
RAW_TEXTURE_END_MARKER = ";\n</script>"

SHARP_BACKGROUND_SIZE = (836, 1812)
BLUR_LAYER_SIZE = (418, 906)
CARD_SIZE = (501, 1080)
ICON_SIZE = (96, 96)


@dataclass(frozen=True)
class AssetSpec:
    source: str
    output: str
    size: tuple[int, int]


BACKGROUND_2 = AssetSpec(
    "entry/src/main/resources/base/media/Background5.png",
    "entry/src/main/resources/rawfile/taskbar_up_webgl_background5.png",
    SHARP_BACKGROUND_SIZE,
)
BACKGROUND_2_SOFT = AssetSpec(
    "entry/src/main/resources/base/media/BlurBackground.png",
    "entry/src/main/resources/rawfile/taskbar_up_webgl_blur_background.png",
    BLUR_LAYER_SIZE,
)
BACKGROUND_3 = AssetSpec(
    "entry/src/main/resources/base/media/Background3.png",
    "entry/src/main/resources/rawfile/taskbar_up_webgl_background3.png",
    SHARP_BACKGROUND_SIZE,
)
BACKGROUND_3_SOFT = AssetSpec(
    "entry/src/main/resources/base/media/BlurIcon.png",
    "entry/src/main/resources/rawfile/taskbar_up_webgl_blur_icon.png",
    BLUR_LAYER_SIZE,
)

CARDS = [
    AssetSpec("entry/src/main/resources/base/media/Card1.png", "entry/src/main/resources/rawfile/taskbar_up_webgl_card1.png", CARD_SIZE),
    AssetSpec("entry/src/main/resources/base/media/Card2.png", "entry/src/main/resources/rawfile/taskbar_up_webgl_card2.png", CARD_SIZE),
    AssetSpec("entry/src/main/resources/base/media/Card3.png", "entry/src/main/resources/rawfile/taskbar_up_webgl_card3.png", CARD_SIZE),
    AssetSpec("entry/src/main/resources/base/media/Card4.png", "entry/src/main/resources/rawfile/taskbar_up_webgl_card4.png", CARD_SIZE),
    AssetSpec("entry/src/main/resources/base/media/card5.png", "entry/src/main/resources/rawfile/taskbar_up_webgl_card5.png", CARD_SIZE),
    AssetSpec("entry/src/main/resources/base/media/card6.png", "entry/src/main/resources/rawfile/taskbar_up_webgl_card6.png", CARD_SIZE),
]

ICONS = [
    AssetSpec("entry/src/main/resources/base/media/icon1.png", "entry/src/main/resources/rawfile/taskbar_up_webgl_icon1.png", ICON_SIZE),
    AssetSpec("entry/src/main/resources/base/media/icon2.png", "entry/src/main/resources/rawfile/taskbar_up_webgl_icon2.png", ICON_SIZE),
    AssetSpec("entry/src/main/resources/base/media/icon3.png", "entry/src/main/resources/rawfile/taskbar_up_webgl_icon3.png", ICON_SIZE),
    AssetSpec("entry/src/main/resources/base/media/icon4.png", "entry/src/main/resources/rawfile/taskbar_up_webgl_icon4.png", ICON_SIZE),
    AssetSpec("entry/src/main/resources/base/media/icon5.png", "entry/src/main/resources/rawfile/taskbar_up_webgl_icon5.png", ICON_SIZE),
    AssetSpec("entry/src/main/resources/base/media/icon6.png", "entry/src/main/resources/rawfile/taskbar_up_webgl_icon6.png", ICON_SIZE),
]


def unpremultiply_after_resize(premultiplied: np.ndarray) -> np.ndarray:
    alpha = premultiplied[..., 3:4]
    rgb = np.where(alpha > 0, premultiplied[..., :3] * 255.0 / np.maximum(alpha, 1.0), 0)
    out = np.empty_like(premultiplied)
    out[..., :3] = rgb
    out[..., 3:4] = alpha
    return np.clip(np.rint(out), 0, 255).astype(np.uint8)


def bleed_transparent_rgb(rgba: np.ndarray) -> None:
    height, width, _ = rgba.shape
    pixel_count = width * height
    flat = rgba.reshape((pixel_count, 4))
    filled = flat[:, 3] > 32
    if not filled.any() or filled.all():
        return

    queue = np.empty(pixel_count, dtype=np.int32)
    seed_indices = np.flatnonzero(filled)
    tail = len(seed_indices)
    queue[:tail] = seed_indices
    head = 0

    while head < tail:
        pixel_index = int(queue[head])
        head += 1
        x = pixel_index % width
        y = pixel_index // width
        source_rgb = flat[pixel_index, :3]
        neighbors = (
            pixel_index - 1 if x > 0 else -1,
            pixel_index + 1 if x + 1 < width else -1,
            pixel_index - width if y > 0 else -1,
            pixel_index + width if y + 1 < height else -1,
        )
        for neighbor in neighbors:
            if neighbor < 0 or filled[neighbor]:
                continue
            flat[neighbor, :3] = source_rgb
            filled[neighbor] = True
            queue[tail] = neighbor
            tail += 1

    low_alpha_dark = (
        (flat[:, 3] > 0)
        & (flat[:, 3] <= 32)
        & (flat[:, 0] < 8)
        & (flat[:, 1] < 8)
        & (flat[:, 2] < 8)
    )
    flat[low_alpha_dark, :3] = 32


def render_asset(spec: AssetSpec) -> np.ndarray:
    source = Image.open(ROOT / spec.source).convert("RGBA")
    source_arr = np.asarray(source, dtype=np.float32)
    alpha = source_arr[..., 3:4] / 255.0
    premultiplied = np.empty_like(source_arr)
    premultiplied[..., :3] = source_arr[..., :3] * alpha
    premultiplied[..., 3:4] = source_arr[..., 3:4]

    premultiplied_image = Image.fromarray(np.clip(np.rint(premultiplied), 0, 255).astype(np.uint8), "RGBA")
    resized = premultiplied_image.resize(spec.size, Image.Resampling.LANCZOS)
    rgba = unpremultiply_after_resize(np.asarray(resized, dtype=np.float32))
    bleed_transparent_rgb(rgba)
    return rgba


def write_png(rgba: np.ndarray, path: str) -> None:
    Image.fromarray(rgba, "RGBA").save(ROOT / path, optimize=True)


def make_raw_asset(spec: AssetSpec) -> dict[str, object]:
    rgba = render_asset(spec)
    write_png(rgba, spec.output)
    height, width, _ = rgba.shape
    return {
        "width": width,
        "height": height,
        "rgba": base64.b64encode(rgba.tobytes()).decode("ascii"),
    }


def inject_raw_textures(payload: dict[str, object]) -> None:
    html = RAWFILE_HTML.read_text(encoding="utf-8")
    start = html.index(RAW_TEXTURE_MARKER) + len(RAW_TEXTURE_MARKER)
    end = html.index(RAW_TEXTURE_END_MARKER, start)
    payload_json = json.dumps(payload, separators=(",", ":"), sort_keys=True)
    RAWFILE_HTML.write_text(html[:start] + payload_json + html[end:], encoding="utf-8")


def main() -> None:
    payload = {
        "background2": make_raw_asset(BACKGROUND_2),
        "background2Soft": make_raw_asset(BACKGROUND_2_SOFT),
        "background3": make_raw_asset(BACKGROUND_3),
        "background3Soft": make_raw_asset(BACKGROUND_3_SOFT),
        "cards": [make_raw_asset(spec) for spec in CARDS],
        "icons": [make_raw_asset(spec) for spec in ICONS],
    }
    inject_raw_textures(payload)

    summary = {
        "background2": {key: payload["background2"][key] for key in ("width", "height")},
        "background2Soft": {key: payload["background2Soft"][key] for key in ("width", "height")},
        "background3": {key: payload["background3"][key] for key in ("width", "height")},
        "background3Soft": {key: payload["background3Soft"][key] for key in ("width", "height")},
        "cards": [{key: card[key] for key in ("width", "height")} for card in payload["cards"]],
        "icons": [{key: icon[key] for key in ("width", "height")} for icon in payload["icons"]],
    }
    Path("/private/tmp/taskbar-webgl-assets-summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True),
        encoding="utf-8",
    )
    print("Generated and injected taskbar WebGL assets")


if __name__ == "__main__":
    main()
