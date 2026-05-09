#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


APP_LABEL = "NetherSX2 Cheat Helper"
DISPLAY_NAME = "NetherSX2 Patch Cheat Helper"
SHORT_NAME = "NetherSX2 Helper"

ROOT = Path(__file__).resolve().parents[1]
BRANDING_DIR = ROOT / "branding"
ANDROID_RES_DIR = BRANDING_DIR / "android" / "res"
GITHUB_ASSETS_DIR = ROOT / ".github" / "assets"
PREVIEW_DIR = BRANDING_DIR / "preview"

SCALE = 4
BASE = 512
WORK = BASE * SCALE

COLORS = {
    "bg_top": (8, 16, 24),
    "bg_bottom": (19, 44, 47),
    "panel": (14, 26, 36),
    "panel_2": (20, 42, 46),
    "cyan": (31, 210, 198),
    "green": (190, 245, 82),
    "amber": (255, 184, 76),
    "white": (244, 250, 248),
    "ink": (5, 12, 18),
}


def font(size: int, bold: bool = True) -> ImageFont.FreeTypeFont:
    candidates = [
        r"C:\Windows\Fonts\segoeuib.ttf" if bold else r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def ensure_dirs() -> None:
    for path in [
        ANDROID_RES_DIR / "drawable",
        ANDROID_RES_DIR / "mipmap",
        ANDROID_RES_DIR / "mipmap-anydpi",
        ANDROID_RES_DIR / "mipmap-mdpi",
        ANDROID_RES_DIR / "mipmap-hdpi",
        ANDROID_RES_DIR / "mipmap-xhdpi",
        ANDROID_RES_DIR / "mipmap-xxhdpi",
        ANDROID_RES_DIR / "mipmap-xxxhdpi",
        GITHUB_ASSETS_DIR,
        PREVIEW_DIR,
    ]:
        path.mkdir(parents=True, exist_ok=True)


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def circle_mask(size: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse((0, 0, size - 1, size - 1), fill=255)
    return mask


def background(size: int = WORK, rounded: bool = True) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gradient = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    d = ImageDraw.Draw(gradient)
    for y in range(size):
        t = y / max(size - 1, 1)
        r = int(COLORS["bg_top"][0] * (1 - t) + COLORS["bg_bottom"][0] * t)
        g = int(COLORS["bg_top"][1] * (1 - t) + COLORS["bg_bottom"][1] * t)
        b = int(COLORS["bg_top"][2] * (1 - t) + COLORS["bg_bottom"][2] * t)
        d.line((0, y, size, y), fill=(r, g, b, 255))

    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay, "RGBA")
    od.ellipse((-size * 0.18, -size * 0.16, size * 0.88, size * 0.90), fill=(31, 210, 198, 26))
    od.ellipse((size * 0.34, size * 0.44, size * 1.24, size * 1.22), fill=(190, 245, 82, 22))
    od.polygon(
        [(size * 0.72, 0), (size, 0), (size, size * 0.18), (size * 0.44, size)],
        fill=(255, 184, 76, 12),
    )

    panel = Image.alpha_composite(gradient, overlay)

    if rounded:
        mask = rounded_mask(size, size // 5)
        image.paste(panel, (0, 0), mask)
    else:
        image = panel
    return image


def draw_foreground(size: int = WORK) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    s = size / WORK

    def xy(values: tuple[float, ...]) -> tuple[int, ...]:
        return tuple(int(v * s) for v in values)

    white = (*COLORS["white"], 255)
    cyan = (*COLORS["cyan"], 255)
    green = (*COLORS["green"], 255)
    ink = (*COLORS["ink"], 255)
    shadow = (0, 0, 0, 110)

    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow, "RGBA")
    gd.rounded_rectangle(xy((408, 344, 1640, 1704)), radius=int(280 * s), fill=(31, 210, 198, 56))
    gd.ellipse(xy((1030, 1180, 1690, 1770)), fill=(190, 245, 82, 62))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(max(1, int(48 * s)))))

    d.rounded_rectangle(
        xy((440, 354, 1608, 1674)),
        radius=int(250 * s),
        fill=(*COLORS["panel"], 246),
        outline=(31, 210, 198, 210),
        width=max(3, int(20 * s)),
    )
    d.rounded_rectangle(
        xy((520, 434, 1528, 1594)),
        radius=int(192 * s),
        outline=(244, 250, 248, 32),
        width=max(2, int(7 * s)),
    )

    n_font = font(int(900 * s), bold=True)
    d.text(xy((1024, 880)), "N", font=n_font, fill=shadow, anchor="mm")
    d.text(xy((1002, 846)), "N", font=n_font, fill=white, anchor="mm")

    d.rounded_rectangle(
        xy((1104, 1230, 1532, 1468)),
        radius=int(119 * s),
        fill=green,
        outline=(244, 250, 248, 130),
        width=max(3, int(12 * s)),
    )
    d.ellipse(xy((1316, 1268, 1494, 1446)), fill=ink)
    d.rounded_rectangle(xy((1172, 1318, 1286, 1374)), radius=int(28 * s), fill=(5, 18, 21, 145))

    d.line(xy((1234, 1548, 1376, 1548)), fill=cyan, width=max(8, int(30 * s)))
    d.line(xy((1376, 1548, 1496, 1548)), fill=(255, 184, 76, 255), width=max(8, int(30 * s)))
    return img


def composite_icon(size: int, round_icon: bool = False) -> Image.Image:
    full = Image.alpha_composite(background(WORK, rounded=not round_icon), draw_foreground(WORK))
    if round_icon:
        out = Image.new("RGBA", (WORK, WORK), (0, 0, 0, 0))
        out.paste(full, (0, 0), circle_mask(WORK))
        full = out
    return full.resize((size, size), Image.Resampling.LANCZOS)


def foreground_icon(size: int) -> Image.Image:
    return draw_foreground(WORK).resize((size, size), Image.Resampling.LANCZOS)


def wordmark(dark: bool) -> Image.Image:
    w, h = 1400, 420
    bg = (7, 12, 18, 255) if dark else (246, 250, 248, 255)
    img = Image.new("RGBA", (w, h), bg)
    icon = composite_icon(288, round_icon=False)
    img.alpha_composite(icon, (64, 66))
    d = ImageDraw.Draw(img, "RGBA")
    title_color = (244, 250, 248, 255) if dark else (14, 26, 36, 255)
    sub_color = (*COLORS["cyan"], 255) if dark else (17, 118, 114, 255)
    d.text((400, 118), "NetherSX2", font=font(112, True), fill=title_color)
    d.text((406, 248), "Patch Cheat Helper", font=font(58, True), fill=sub_color)
    d.rounded_rectangle((400, 334, 820, 354), radius=10, fill=(*COLORS["green"], 255))
    d.rounded_rectangle((842, 334, 1060, 354), radius=10, fill=(*COLORS["amber"], 255))
    return img


def write_text_assets() -> None:
    (ANDROID_RES_DIR / "drawable" / "ic_launcher_background.xml").write_text(
        """<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<vector xmlns:android=\"http://schemas.android.com/apk/res/android\" android:width=\"108dp\" android:height=\"108dp\" android:viewportWidth=\"108\" android:viewportHeight=\"108\">\n    <path android:fillColor=\"#0B141C\" android:pathData=\"M0,0h108v108h-108z\" />\n    <path android:fillColor=\"#172D31\" android:pathData=\"M0,82 C24,60 45,52 70,56 C88,59 100,70 108,80 L108,108 L0,108 Z\" />\n    <path android:fillColor=\"#14292C\" android:pathData=\"M0,0 L108,0 L108,24 C78,21 54,30 34,48 C20,61 10,72 0,76 Z\" />\n</vector>\n""",
        encoding="utf-8",
    )
    for name in ("ic_launcher", "ic_launcher_round"):
        background_ref = "@drawable/ic_launcher_background"
        (ANDROID_RES_DIR / "mipmap-anydpi" / f"{name}.xml").write_text(
            f"""<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<adaptive-icon xmlns:android=\"http://schemas.android.com/apk/res/android\">\n    <background android:drawable=\"{background_ref}\" />\n    <foreground android:drawable=\"@mipmap/ic_launcher_foreground\" />\n</adaptive-icon>\n""",
            encoding="utf-8",
        )
    (BRANDING_DIR / "brand.json").write_text(
        f"""{{\n  \"appLabel\": \"{APP_LABEL}\",\n  \"displayName\": \"{DISPLAY_NAME}\",\n  \"shortName\": \"{SHORT_NAME}\",\n  \"primary\": \"#0B141C\",\n  \"accent\": \"#1FD2C6\",\n  \"cheatAccent\": \"#BEF552\",\n  \"warningAccent\": \"#FFB84C\"\n}}\n""",
        encoding="utf-8",
    )


def main() -> None:
    ensure_dirs()
    densities = {
        "mipmap-mdpi": (48, 108),
        "mipmap-hdpi": (72, 162),
        "mipmap-xhdpi": (96, 216),
        "mipmap-xxhdpi": (144, 324),
        "mipmap-xxxhdpi": (192, 432),
    }
    for density, (legacy_size, fg_size) in densities.items():
        out_dir = ANDROID_RES_DIR / density
        composite_icon(legacy_size).save(out_dir / "ic_launcher.png")
        composite_icon(legacy_size, round_icon=True).save(out_dir / "ic_launcher_round.png")
        foreground_icon(fg_size).save(out_dir / "ic_launcher_foreground.png")

    composite_icon(512).save(ANDROID_RES_DIR / "mipmap" / "logo.png")
    composite_icon(512).save(GITHUB_ASSETS_DIR / "logo_light.png")
    composite_icon(512).save(GITHUB_ASSETS_DIR / "logo_dark.png")
    wordmark(False).save(GITHUB_ASSETS_DIR / "wordmark_light.png")
    wordmark(True).save(GITHUB_ASSETS_DIR / "wordmark_dark.png")
    composite_icon(1024).save(PREVIEW_DIR / "icon-1024.png")
    wordmark(False).save(PREVIEW_DIR / "wordmark-light.png")
    wordmark(True).save(PREVIEW_DIR / "wordmark-dark.png")
    write_text_assets()


if __name__ == "__main__":
    main()
