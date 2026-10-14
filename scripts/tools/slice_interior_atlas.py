"""Découpe la planche d'intérieur en bandes verticales annotées."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/tilesets/emerald_interior_tilesets.png"
OUTPUT = ROOT / "docs/atlas/interieur"
TILE_SIZE = 16
BAND_WIDTH = 8 * TILE_SIZE
SCALE = 4

image = Image.open(SOURCE).convert("RGBA")
if image.size != (3072, 1024):
    raise SystemExit(f"Dimensions inattendues : {image.size}, attendu 3072×1024 px")
font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
font = ImageFont.truetype(font_path, 14)
OUTPUT.mkdir(parents=True, exist_ok=True)

for index in range(image.width // BAND_WIDTH):
    band = image.crop((index * BAND_WIDTH, 0, (index + 1) * BAND_WIDTH, image.height))
    band = band.resize((band.width * SCALE, band.height * SCALE), Image.Resampling.NEAREST)
    draw = ImageDraw.Draw(band)
    for x in range(9):
        draw.line((x * TILE_SIZE * SCALE, 0, x * TILE_SIZE * SCALE, band.height), fill=(255, 0, 255, 210), width=1)
    for y in range(65):
        yy = y * TILE_SIZE * SCALE
        draw.line((0, yy, band.width, yy), fill=(255, 0, 255, 210), width=1)
        if y < 64:
            draw.text((2, yy + 2), str(y), font=font, fill=(255, 255, 0), stroke_width=1, stroke_fill=(0, 0, 0))
    for x in range(8):
        draw.text((x * TILE_SIZE * SCALE + 2, 2), str(x), font=font, fill=(255, 255, 0), stroke_width=1, stroke_fill=(0, 0, 0))
    band.save(OUTPUT / f"bande_{index + 1:02d}.png", optimize=True)

preview = Image.new("RGB", (4 * 152, 6 * 1056), (34, 34, 42))
preview_draw = ImageDraw.Draw(preview)
preview_font = ImageFont.truetype(font_path, 14)
for index in range(image.width // BAND_WIDTH):
    x = (index % 4) * 152 + 12
    y = (index // 4) * 1056 + 24
    strip = image.crop((index * BAND_WIDTH, 0, (index + 1) * BAND_WIDTH, image.height)).convert("RGB")
    preview.paste(strip, (x, y))
    preview_draw.text((x, y - 18), f"Bande {index + 1:02d} · atlas x={index * 8}–{index * 8 + 7}", font=preview_font, fill="white")
preview.save(OUTPUT / "planche_apercu.png", optimize=True)

print(f"{image.width // BAND_WIDTH} bandes annotées enregistrées dans {OUTPUT}")
