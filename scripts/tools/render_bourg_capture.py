"""Rendu statique de contrôle de Bourg-en-Vol, d'après les mêmes JSON et atlas que Godot."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
plan = json.loads((ROOT / "data/maps/bourg_en_vol.json").read_text(encoding="utf-8"))
stamp_data = json.loads((ROOT / "data/building_stamps.json").read_text(encoding="utf-8"))
stamps = {s["id"]: s for s in stamp_data["stamps"]}
texture = Image.open(ROOT / "assets/tilesets/emerald_exterior_tileset.png").convert("RGBA")
terrain = Image.new("RGBA", (plan["size"][0] * 16, plan["size"][1] * 16))
for y, row in enumerate(plan["terrain"]):
    for x, symbol in enumerate(row):
        tile = plan["tiles"].get(symbol)
        if tile and tile[0] == 0:
            sx, sy = tile[1] * 16, tile[2] * 16
            terrain.alpha_composite(texture.crop((sx, sy, sx + 16, sy + 16)), (x * 16, y * 16))
for building in plan.get("buildings", []):
    stamp = stamps[building["stamp"]]
    band_number = stamp["band"]
    band = Image.open(ROOT / f"assets/tilesets/bands/band_{band_number:02d}.png").convert("RGBA")
    variant_name = stamp.get("roof_variant")
    variant = Image.open(ROOT / "assets/tilesets/bands" / f"{variant_name}.png").convert("RGBA") if variant_name else None
    ox, oy = building["position"]
    for tile in stamp["tiles"]:
        dx, dy = tile["offset"]
        sx, sy = tile["atlas"]
        source = variant if (variant is not None and tile["role"] == "roof") else band
        crop = source.crop((sx * 16, sy * 16, (sx + 1) * 16, (sy + 1) * 16))
        terrain.alpha_composite(crop, ((ox + dx) * 16, (oy + dy) * 16))
scale = 2
image = terrain.resize((terrain.width * scale, terrain.height * scale), Image.Resampling.NEAREST).convert("RGB")
image.save(ROOT / "docs/atlas/bourg_en_vol.png", optimize=True)
print(f"Capture de contrôle : {image.width}×{image.height} px (zone 30×20 tuiles)")
