from json import load
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ATLAS = Image.open(ROOT / "assets/tilesets/emerald_exterior_tileset.png").convert("RGBA")
DATA = load((ROOT / "data/building_stamps.json").open(encoding="utf-8"))
OUT = ROOT / "docs/atlas/stamps"
OUT.mkdir(parents=True, exist_ok=True)
FONT = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
SCALE = 4
TILE = 16 * SCALE
EMPTY = (24, 40, 80, 255)

for stamp in DATA["stamps"]:
    width, height = stamp["size"]
    band = stamp["band"] - 1
    base = Image.open(ROOT / f"assets/tilesets/bands/band_{stamp['band']:02d}.png").convert("RGBA")
    variant_name = stamp.get("roof_variant")
    variant = Image.open(ROOT / "assets/tilesets/bands" / f"{variant_name}.png").convert("RGBA") if variant_name else None
    margin_x, margin_y = 54, 42
    title = f"{stamp['name']} — bande {stamp['band']:02d}, {width} x {height} tuiles"
    title_width = ImageDraw.Draw(Image.new("RGB", (1, 1))).textbbox((0, 0), title, font=FONT)[2]
    image = Image.new("RGBA", (max(margin_x + width*TILE + 4, title_width + margin_x), margin_y + height*TILE + 4), (245,245,245,255))
    draw = ImageDraw.Draw(image)
    draw.text((margin_x, 5), title, font=FONT, fill=(0,0,0,255))
    for tile in stamp["tiles"]:
        dx,dy = tile["offset"]
        sx,sy = tile["atlas"]
        source = variant if (variant is not None and tile["role"] == "roof") else base
        crop = source.crop((sx*16,sy*16,(sx+1)*16,(sy+1)*16))
        if all(pixel == EMPTY for pixel in crop.getdata()):
            continue
        image.alpha_composite(crop.resize((TILE,TILE),Image.Resampling.NEAREST),(margin_x+dx*TILE,margin_y+dy*TILE))
    draw = ImageDraw.Draw(image)
    for x in range(width+1):
        draw.line((margin_x+x*TILE,margin_y,margin_x+x*TILE,margin_y+height*TILE),fill=(255,0,220,255),width=1)
    for y in range(height+1):
        draw.line((margin_x,margin_y+y*TILE,margin_x+width*TILE,margin_y+y*TILE),fill=(255,0,220,255),width=1)
    dx,dy = stamp["door"]["position"]
    draw.rectangle((margin_x+dx*TILE+1,margin_y+dy*TILE+1,margin_x+(dx+1)*TILE-1,margin_y+(dy+1)*TILE-1),outline=(255,40,40,255),width=3)
    ax,ay = stamp["door"]["approach"]
    if ax < width and ay < height:
        draw.rectangle((margin_x+ax*TILE+1,margin_y+ay*TILE+1,margin_x+(ax+1)*TILE-1,margin_y+(ay+1)*TILE-1),outline=(30,100,255,255),width=3)
    image.convert("RGB").save(OUT / f"{stamp['id']}.png",optimize=True)
