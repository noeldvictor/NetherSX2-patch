#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


APP_LABEL = "NetherSX2 Thor Experiment"
DISPLAY_NAME = "NetherSX2 Thor Experiment"
SHORT_NAME = "Thor Experiment"

ROOT = Path(__file__).resolve().parents[1]
BRANDING_DIR = ROOT / "branding"
ANDROID_RES_DIR = BRANDING_DIR / "android" / "res"
GITHUB_ASSETS_DIR = ROOT / ".github" / "assets"
PREVIEW_DIR = BRANDING_DIR / "preview"
DOCS_ASSETS_DIR = ROOT / "docs" / "assets"

SCALE = 4
BASE = 512
WORK = BASE * SCALE

COLORS = {
    "bg_top": (8, 11, 18),
    "bg_bottom": (22, 31, 44),
    "panel": (17, 25, 34),
    "panel_2": (24, 39, 43),
    "cyan": (58, 220, 226),
    "green": (191, 255, 101),
    "amber": (255, 181, 73),
    "coral": (255, 77, 109),
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
        DOCS_ASSETS_DIR,
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
    od.polygon(
        [(size * 0.58, 0), (size, 0), (size, size), (size * 0.30, size)],
        fill=(*COLORS["cyan"], 24),
    )
    od.polygon(
        [(0, size * 0.70), (size * 0.44, size), (0, size)],
        fill=(*COLORS["green"], 18),
    )
    od.polygon(
        [(0, 0), (size * 0.28, 0), (size * 0.10, size * 0.34), (0, size * 0.42)],
        fill=(*COLORS["coral"], 18),
    )
    od.line((size * 0.18, size * 0.82, size * 0.86, size * 0.16), fill=(244, 250, 248, 20), width=max(1, size // 40))

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
    amber = (*COLORS["amber"], 255)
    coral = (*COLORS["coral"], 255)
    ink = (*COLORS["ink"], 255)
    shadow = (0, 0, 0, 110)

    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow, "RGBA")
    gd.ellipse(xy((410, 300, 1640, 1420)), fill=(*COLORS["cyan"], 58))
    gd.rounded_rectangle(xy((520, 1340, 1544, 1590)), radius=int(132 * s), fill=(*COLORS["green"], 62))
    gd.polygon(xy((1180, 300, 1510, 300, 1280, 840, 1510, 840, 930, 1640, 1130, 980, 900, 980)), fill=(*COLORS["amber"], 56))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(max(1, int(52 * s)))))

    n_font = font(int(980 * s), bold=True)
    two_font = font(int(450 * s), bold=True)
    thor_font = font(int(230 * s), bold=True)

    d.rounded_rectangle(xy((460, 360, 1588, 1240)), radius=int(170 * s), outline=(244, 250, 248, 72), width=max(4, int(18 * s)))
    d.line(xy((620, 1260, 1420, 1260)), fill=(244, 250, 248, 70), width=max(4, int(20 * s)))

    d.text(xy((842, 810)), "N", font=n_font, fill=shadow, anchor="mm")
    d.text(xy((812, 770)), "N", font=n_font, fill=white, anchor="mm")
    d.text(xy((1274, 970)), "2", font=two_font, fill=shadow, anchor="mm")
    d.text(xy((1252, 936)), "2", font=two_font, fill=cyan, anchor="mm")

    d.polygon(xy((1170, 292, 1475, 292, 1292, 732, 1510, 732, 965, 1432, 1118, 880, 910, 880)), fill=amber)
    d.polygon(xy((1218, 360, 1395, 360, 1218, 790, 1390, 790, 1082, 1188, 1188, 830, 1038, 830)), fill=(5, 12, 18, 128))

    d.rounded_rectangle(
        xy((540, 1370, 1510, 1548)),
        radius=int(92 * s),
        fill=green,
        outline=(244, 250, 248, 150),
        width=max(3, int(14 * s)),
    )
    d.rounded_rectangle(xy((662, 1424, 992, 1486)), radius=int(31 * s), fill=(5, 18, 21, 170))
    d.ellipse(xy((1168, 1392, 1450, 1520)), fill=ink)
    d.text(xy((1018, 1698)), "THOR", font=thor_font, fill=white, anchor="mm")
    d.line(xy((580, 1610, 930, 1610)), fill=cyan, width=max(8, int(32 * s)))
    d.line(xy((960, 1610, 1230, 1610)), fill=coral, width=max(8, int(32 * s)))
    d.line(xy((1260, 1610, 1488, 1610)), fill=amber, width=max(8, int(32 * s)))
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
    d.text((400, 110), "NetherSX2 Thor", font=font(104, True), fill=title_color)
    d.text((406, 238), "AI-assisted experiment fork", font=font(54, True), fill=sub_color)
    d.rounded_rectangle((400, 326, 704, 346), radius=10, fill=(*COLORS["green"], 255))
    d.rounded_rectangle((728, 326, 946, 346), radius=10, fill=(*COLORS["coral"], 255))
    d.rounded_rectangle((970, 326, 1160, 346), radius=10, fill=(*COLORS["amber"], 255))
    return img


def hero() -> Image.Image:
    w, h = 1000, 326
    img = Image.new("RGBA", (w, h), (*COLORS["bg_top"], 255))
    d = ImageDraw.Draw(img, "RGBA")
    for y in range(h):
        t = y / max(h - 1, 1)
        r = int(COLORS["bg_top"][0] * (1 - t) + COLORS["bg_bottom"][0] * t)
        g = int(COLORS["bg_top"][1] * (1 - t) + COLORS["bg_bottom"][1] * t)
        b = int(COLORS["bg_top"][2] * (1 - t) + COLORS["bg_bottom"][2] * t)
        d.line((0, y, w, y), fill=(r, g, b, 255))

    # Soft faux-gameplay backdrop: readable, original, and intentionally not a game screenshot.
    horizon = h * 0.54
    d.polygon([(0, horizon), (w, horizon - 42), (w, h), (0, h)], fill=(8, 42, 50, 182))
    for i in range(16):
        x0 = -120 + i * 84
        d.line((x0, h, x0 + 420, int(horizon)), fill=(104, 231, 217, 28), width=2)
    for y in range(int(horizon) + 12, h, 25):
        d.line((0, y, w, y - 36), fill=(255, 255, 255, 12), width=1)
    d.polygon([(650, 190), (820, 32), (944, 206)], fill=(255, 255, 255, 20))
    d.polygon([(735, 174), (890, 64), (1010, 216)], fill=(255, 255, 255, 18))
    img = img.filter(ImageFilter.GaussianBlur(0.35))
    dim = Image.new("RGBA", (w, h), (2, 8, 14, 96))
    img = Image.alpha_composite(img, dim)
    d = ImageDraw.Draw(img, "RGBA")

    card = (36, 37, 560, 289)
    d.rounded_rectangle(card, radius=18, fill=(4, 12, 18, 230), outline=(*COLORS["cyan"], 255), width=2)
    d.text((64, 70), "NetherSX2 for AYN Thor", font=font(38, True), fill=(247, 244, 220, 255))
    d.text((64, 124), "Experiment", font=font(52, True), fill=(*COLORS["cyan"], 255))
    d.text((64, 188), "Personal-use Android fork. AI-assisted. No stability", font=font(21, False), fill=(241, 241, 232, 255))
    d.text((64, 214), "promise.", font=font(21, False), fill=(241, 241, 232, 255))
    d.text((64, 254), "Cheat toggles, Thor haptics, covers, Turnip drivers.", font=font(18, False), fill=(225, 233, 230, 238))

    d.rounded_rectangle((708, 54, 944, 130), radius=15, fill=(*COLORS["amber"], 255))
    d.text((730, 81), "VIBE CODED", font=font(28, True), fill=(*COLORS["ink"], 255))
    d.rounded_rectangle((708, 150, 944, 234), radius=15, fill=(*COLORS["cyan"], 255))
    d.text((730, 176), "FORK IT", font=font(30, True), fill=(*COLORS["ink"], 255))
    d.text((730, 210), "do not open issues here", font=font(17, False), fill=(*COLORS["ink"], 240))
    return img


def action_button(label: str, sublabel: str, fill: tuple[int, int, int], width: int = 520) -> Image.Image:
    h = 132
    img = Image.new("RGBA", (width, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    d.rounded_rectangle((0, 0, width - 1, h - 1), radius=24, fill=(*fill, 255))
    d.rounded_rectangle((4, 4, width - 5, h - 5), radius=21, outline=(255, 255, 255, 96), width=2)
    d.text((34, 28), label, font=font(36, True), fill=(*COLORS["ink"], 255))
    d.text((36, 78), sublabel, font=font(22, False), fill=(*COLORS["ink"], 230))
    return img


def write_text_assets() -> None:
    (ANDROID_RES_DIR / "drawable" / "ic_launcher_background.xml").write_text(
        """<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<vector xmlns:android=\"http://schemas.android.com/apk/res/android\" android:width=\"108dp\" android:height=\"108dp\" android:viewportWidth=\"108\" android:viewportHeight=\"108\">\n    <path android:fillColor=\"#0B141C\" android:pathData=\"M0,0h108v108h-108z\" />\n    <path android:fillColor=\"#143135\" android:pathData=\"M69,0h39v108h-72z\" />\n    <path android:fillColor=\"#173024\" android:pathData=\"M0,78l43,30h-43z\" />\n    <path android:fillColor=\"#1FD2C6\" android:fillAlpha=\"0.16\" android:pathData=\"M18,87 L88,20 L93,25 L23,92 Z\" />\n</vector>\n""",
        encoding="utf-8",
    )
    for name in ("ic_launcher", "ic_launcher_round"):
        background_ref = "@drawable/ic_launcher_background"
        (ANDROID_RES_DIR / "mipmap-anydpi" / f"{name}.xml").write_text(
            f"""<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<adaptive-icon xmlns:android=\"http://schemas.android.com/apk/res/android\">\n    <background android:drawable=\"{background_ref}\" />\n    <foreground android:drawable=\"@mipmap/ic_launcher_foreground\" />\n</adaptive-icon>\n""",
            encoding="utf-8",
        )
    (BRANDING_DIR / "brand.json").write_text(
        f"""{{\n  \"appLabel\": \"{APP_LABEL}\",\n  \"displayName\": \"{DISPLAY_NAME}\",\n  \"shortName\": \"{SHORT_NAME}\",\n  \"primary\": \"#080B12\",\n  \"accent\": \"#3ADCE2\",\n  \"cheatAccent\": \"#BFFF65\",\n  \"warningAccent\": \"#FFB549\",\n  \"experimentAccent\": \"#FF4D6D\"\n}}\n""",
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
    hero().save(GITHUB_ASSETS_DIR / "hero.png")
    hero().save(DOCS_ASSETS_DIR / "nethersx2-thor-experiment-banner.png")
    action_button("FORK IT", "no issue tracker support here", COLORS["cyan"], width=420).save(DOCS_ASSETS_DIR / "fork-it-button.png")
    composite_icon(1024).save(PREVIEW_DIR / "icon-1024.png")
    wordmark(False).save(PREVIEW_DIR / "wordmark-light.png")
    wordmark(True).save(PREVIEW_DIR / "wordmark-dark.png")
    hero().save(PREVIEW_DIR / "hero.png")
    write_text_assets()


if __name__ == "__main__":
    main()
