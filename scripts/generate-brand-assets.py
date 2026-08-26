from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "CxLogoV1.png"
OUTPUT = ROOT / "assets" / "brand"
OUTPUT.mkdir(parents=True, exist_ok=True)


def crop_logo(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    white = Image.new("RGB", rgb.size, "white")
    bbox = ImageChops.difference(rgb, white).getbbox()
    if bbox is None:
        raise ValueError("The source logo does not contain visible artwork.")
    left, top, right, bottom = bbox
    pad = int(max(right - left, bottom - top) * 0.07)
    return rgb.crop((
        max(0, left - pad),
        max(0, top - pad),
        min(rgb.width, right + pad),
        min(rgb.height, bottom + pad),
    ))


def square_logo(mark: Image.Image, size: int, inset: float = 0.08) -> Image.Image:
    canvas = Image.new("RGB", (size, size), "white")
    available = int(size * (1 - inset * 2))
    resized = mark.copy()
    resized.thumbnail((available, available), Image.Resampling.LANCZOS)
    x = (size - resized.width) // 2
    y = (size - resized.height) // 2
    canvas.paste(resized, (x, y))
    return canvas


def fit_font(path: str, text: str, max_width: int, initial_size: int) -> ImageFont.FreeTypeFont:
    size = initial_size
    while size > 18:
        font = ImageFont.truetype(path, size)
        if font.getbbox(text)[2] <= max_width:
            return font
        size -= 2
    return ImageFont.truetype(path, size)


source = Image.open(SOURCE).convert("RGBA")
mark = crop_logo(source)

for size in (16, 32, 48, 64, 180, 192, 256, 512):
    icon = square_logo(mark, size)
    icon.save(OUTPUT / f"cwe-logo-{size}.png", optimize=True)

# Keep conventional root-level fallbacks for clients that do not inspect HTML.
square_logo(mark, 180).save(ROOT / "apple-touch-icon.png", optimize=True)

square_logo(mark, 512).save(
    OUTPUT / "cwe-logo-512.webp",
    "WEBP",
    quality=92,
    method=6,
)

favicon = square_logo(mark, 256)
for favicon_path in (OUTPUT / "favicon.ico", ROOT / "favicon.ico"):
    favicon.save(
        favicon_path,
        sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )

width, height = 1200, 630


def social_background() -> Image.Image:
    background = Image.new("RGB", (width, height), "#071724")
    pixels = background.load()
    for y in range(height):
        for x in range(width):
            blend = (x / width) * 0.65 + (y / height) * 0.35
            r = int(7 + (18 - 7) * blend)
            g = int(23 + (59 - 23) * blend)
            b = int(36 + (91 - 36) * blend)
            pixels[x, y] = (r, g, b)
    return background


card = social_background()

draw = ImageDraw.Draw(card)
draw.rounded_rectangle((64, 104, 420, 460), radius=26, fill="#ffffff")
large_mark = square_logo(mark, 310, inset=0.03)
card.paste(large_mark, (87, 127))

bold = r"C:\Windows\Fonts\segoeuib.ttf"
regular = r"C:\Windows\Fonts\segoeui.ttf"
mono = r"C:\Windows\Fonts\consolab.ttf"
title_font = fit_font(bold, "CodingWithEase", 650, 70)
tagline_font = fit_font(bold, "Business software, engineered.", 650, 39)
body_font = ImageFont.truetype(regular, 25)
label_font = ImageFont.truetype(mono, 17)

draw.rectangle((480, 125, 532, 131), fill="#ff8a4c")
draw.text((548, 112), "ENGINEERING FRAMEWORK FOR .NET", font=label_font, fill="#ffad7f")
draw.text((480, 177), "CodingWithEase", font=title_font, fill="#ffffff")
draw.text((480, 277), "Business software,", font=tagline_font, fill="#ffffff")
draw.text((480, 326), "engineered.", font=tagline_font, fill="#ffad7f")
draw.text((480, 400), "Deterministic generation. Server-enforced security.", font=body_font, fill="#d6e2ea")
draw.text((480, 438), "Capability-guided AI. Executable evidence.", font=body_font, fill="#d6e2ea")
draw.text((64, 548), "coding-with-ease.net", font=label_font, fill="#aebfca")
draw.text((890, 548), "ELGIBE SOLUTIONS", font=label_font, fill="#ffad7f")

card.save(OUTPUT / "coding-with-ease-social-1200x630.png", optimize=True)
card.save(OUTPUT / "coding-with-ease-social-1200x630.webp", "WEBP", quality=92, method=6)

about_card = social_background()
about_draw = ImageDraw.Draw(about_card)
about_draw.rounded_rectangle((64, 104, 420, 460), radius=26, fill="#ffffff")
about_card.paste(large_mark, (87, 127))
about_draw.rectangle((480, 125, 532, 131), fill="#ff8a4c")
about_draw.text((548, 112), "THE STORY BEHIND THE FRAMEWORK", font=label_font, fill="#ffad7f")
about_draw.text((480, 177), "CodingWithEase", font=title_font, fill="#ffffff")
about_draw.text((480, 277), "Built from two worlds.", font=tagline_font, fill="#ffffff")
about_draw.text((480, 354), "Software engineering + factory operations.", font=body_font, fill="#d6e2ea")
about_draw.text((480, 411), "Why standard work belongs in software architecture.", font=body_font, fill="#d6e2ea")
about_draw.text((64, 548), "coding-with-ease.net/about.html", font=label_font, fill="#aebfca")
about_draw.text((880, 548), "BY LUCIAN BUMB", font=label_font, fill="#ffad7f")
about_card.save(OUTPUT / "about-coding-with-ease-1200x630.png", optimize=True)
about_card.save(OUTPUT / "about-coding-with-ease-1200x630.webp", "WEBP", quality=92, method=6)

print(f"Generated brand assets from {SOURCE.name} in {OUTPUT}")
