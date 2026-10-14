"""Rend des vues de contrôle des plans JSON avec les textures d'atlas du projet."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/atlas"
OUT.mkdir(parents=True, exist_ok=True)


def render(zone_id: str, title: str) -> Path:
    plan = json.loads((ROOT / f"data/maps/{zone_id}.json").read_text(encoding="utf-8"))
    tex = "emerald_interior_tilesets.png" if plan["tileset"] == "interior" else "emerald_exterior_tileset.png"
    atlas = Image.open(ROOT / "assets/tilesets" / tex).convert("RGBA")
    sky = Image.new("RGBA", (16, 16), "#6bb9e8")
    sky_draw = ImageDraw.Draw(sky)
    sky_draw.rectangle((2, 4, 8, 5), fill="#e9f7ff")
    sky_draw.rectangle((1, 6, 10, 7), fill="#e9f7ff")
    sky_draw.rectangle((4, 3, 7, 3), fill="#e9f7ff")
    sky_draw.rectangle((10, 11, 14, 11), fill="#9bd7f2")
    size = plan["size"]
    image = Image.new("RGBA", (size[0] * 16, size[1] * 16))
    for y, row in enumerate(plan["terrain"]):
        for x, symbol in enumerate(row):
            mapping = plan["tiles"].get(symbol)
            if not mapping:
                continue
            source_id, sx, sy = mapping
            source = sky if source_id == 1 else atlas
            image.alpha_composite(source.crop((sx * 16, sy * 16, (sx + 1) * 16, (sy + 1) * 16)), (x * 16, y * 16))
    if plan.get("buildings"):
        stamp_data = json.loads((ROOT / "data/building_stamps.json").read_text(encoding="utf-8"))
        stamps = {s["id"]: s for s in stamp_data["stamps"]}
        for building in plan["buildings"]:
            stamp = stamps[building["stamp"]]
            band = Image.open(ROOT / f"assets/tilesets/bands/band_{stamp['band']:02d}.png").convert("RGBA")
            variant_name = stamp.get("roof_variant")
            variant = Image.open(ROOT / "assets/tilesets/bands" / f"{variant_name}.png").convert("RGBA") if variant_name else None
            ox, oy = building["position"]
            for tile in stamp["tiles"]:
                dx, dy = tile["offset"]
                sx, sy = tile["atlas"]
                source = variant if variant is not None and tile["role"] == "roof" else band
                image.alpha_composite(source.crop((sx * 16, sy * 16, (sx + 1) * 16, (sy + 1) * 16)), ((ox + dx) * 16, (oy + dy) * 16))
    scale = 3
    image = image.resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST).convert("RGB")
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default()
    # Repère la position de départ et la porte de retour pour faciliter la vérification visuelle.
    spawn = plan.get("spawn", [10, 11] if plan["tileset"] == "interior" else None)
    if spawn is not None:
        x, y = spawn
        cx, cy = int((x + 0.5) * 16 * scale), int((y + 0.5) * 16 * scale)
        draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(218, 49, 58), outline="white", width=2)
    bar = Image.new("RGB", (image.width, 32), (28, 32, 42))
    ImageDraw.Draw(bar).text((8, 9), f"{title} · {size[0]} × {size[1]} tuiles · départ en rouge", fill="white", font=font)
    result = Image.new("RGB", (image.width, image.height + 32), (28, 32, 42))
    result.paste(bar, (0, 0)); result.paste(image, (0, 32))
    path = OUT / f"{zone_id}.png"
    result.save(path, optimize=True)
    return path


for zone, title in [
    ("route_101", "Route 101"),
    ("bourg_en_vol_interieur_01", "Maison du héros"),
    ("bourg_en_vol_interieur_02", "Maison du rival"),
    ("bourg_en_vol_interieur_03", "Laboratoire du Professeur Seko"),
]:
    path = render(zone, title)
    print(path)
