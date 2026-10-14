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
    for furniture in plan.get("furniture", []):
        x, y = furniture["cell"]
        sx, sy = furniture["atlas"]
        image.alpha_composite(atlas.crop((sx * 16, sy * 16, (sx + 1) * 16, (sy + 1) * 16)), (x * 16, y * 16))
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
    font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    title_font = ImageFont.truetype(font_path, 15)
    if plan["tileset"] == "interior":
        # Vue de pièce comme dans le jeu : caméra fixe au centre et fond noir autour.
        zoom = 2
        room = image.resize((image.width * zoom, image.height * zoom), Image.Resampling.NEAREST).convert("RGB")
        view = Image.new("RGB", (480, 320), "black")
        view.paste(room, ((480 - room.width) // 2, (320 - room.height) // 2))
        image = view
        scale = zoom
        offset_x, offset_y = (480 - room.width) // 2, (320 - room.height) // 2
    else:
        scale = 2
        image = image.resize((image.width * scale, image.height * scale), Image.Resampling.NEAREST).convert("RGB")
        offset_x, offset_y = 0, 0
    draw = ImageDraw.Draw(image)
    # Les acteurs statiques reprennent le dessin simple de WorldActor.gd.
    def point(cell):
        return offset_x + int((cell[0] + 0.5) * 16 * scale), offset_y + int((cell[1] + 0.5) * 16 * scale)

    for sign in [plan.get("sign", {})]:
        if sign.get("cell"):
            cx, cy = point(sign["cell"])
            k = scale
            draw.rectangle((cx - 2*k, cy - 4*k, cx + 2*k, cy + 12*k), fill="#755237")
            draw.rectangle((cx - 7*k, cy - 11*k, cx + 7*k, cy - 3*k), fill="#f0d48a")
            draw.rectangle((cx - 5*k, cy - 9*k, cx + 5*k, cy - 5*k), fill="#855d35")
    for npc in plan.get("npcs", []):
        cx, cy = point(npc["cell"])
        k = scale
        draw.rectangle((cx - 5*k, cy - 8*k, cx + 5*k, cy), fill="#f1c59a")
        draw.rectangle((cx - 5*k, cy - 9*k, cx + 5*k, cy - 6*k), fill="#473747")
        draw.rectangle((cx - 6*k, cy, cx + 6*k, cy + 9*k), fill="#e9c659")
        draw.rectangle((cx - 5*k, cy + 9*k, cx - 1*k, cy + 14*k), fill="#394056")
        draw.rectangle((cx + 1*k, cy + 9*k, cx + 5*k, cy + 14*k), fill="#394056")
    for item in plan.get("items", []):
        cx, cy = point(item["cell"])
        k = scale
        draw.rectangle((cx - 4*k, cy - 4*k, cx + 4*k, cy + 4*k), fill="#e9c659")
        draw.rectangle((cx - 2*k, cy - 6*k, cx + 2*k, cy + 6*k), fill="#fff1b3")
        draw.rectangle((cx - 6*k, cy - 2*k, cx + 6*k, cy + 2*k), fill="#fff1b3")
    # Reproduit un petit sprite lisible au point de départ indiqué par le plan.
    spawn = plan.get("spawn", [10, 11] if plan["tileset"] == "interior" else None)
    if spawn is not None:
        x, y = spawn
        cx, cy = offset_x + int((x + 0.5) * 16 * scale), offset_y + int((y + 0.5) * 16 * scale)
        k = scale
        draw.rectangle((cx - 6*k, cy - 8*k, cx + 6*k, cy + 5*k), fill="#f4c69a")
        draw.rectangle((cx - 6*k, cy - 9*k, cx + 6*k, cy - 6*k), fill="#362a3c")
        draw.rectangle((cx - 6*k, cy + 5*k, cx + 6*k, cy + 13*k), fill="#2878b8")
        draw.rectangle((cx - 6*k, cy + 13*k, cx - 1*k, cy + 15*k), fill="#263448")
        draw.rectangle((cx + 1*k, cy + 13*k, cx + 6*k, cy + 15*k), fill="#263448")
    result = Image.new("RGB", (max(480, image.width), image.height + 32), (28, 32, 42))
    header = ImageDraw.Draw(result)
    caption = f"{title} · {size[0]} × {size[1]} cases"
    header.text((8, 8), caption, fill="white", font=title_font)
    result.paste(image, (0, 32))
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
