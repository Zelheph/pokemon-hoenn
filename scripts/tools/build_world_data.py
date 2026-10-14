"""Produit le graphe et les plans JSON de Hoenn pour generate_world.gd."""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
MAPS = DATA / "maps"
MAPS.mkdir(parents=True, exist_ok=True)

nodes: dict[str, dict] = {}
edges: list[dict] = []

def zone(id: str, name: str, kind: str, biome: str = "grass", size: tuple[int, int] = (30, 20), **extra: object) -> None:
    nodes[id] = {"id": id, "name": name, "kind": kind, "biome": biome, "size": list(size), **extra}

def link(a: str, b: str, kind: str = "path", label: str = "") -> None:
    edge = {"a": a, "b": b, "kind": kind}
    if label:
        edge["label"] = label
    edges.append(edge)

# Agglomérations et zones de route officielles ROSA.
towns = [
    ("bourg_en_vol", "Bourg-en-Vol", ["Maison du héros", "Maison du rival", "Laboratoire du Professeur Seko"]),
    ("rosyeres", "Rosyères", ["Centre Pokémon", "Boutique Pokémon"]),
    ("clementi_ville", "Clémenti-Ville", ["Centre Pokémon", "Boutique Pokémon", "Arène de Clémenti-Ville"]),
    ("merouville", "Mérouville", ["Centre Pokémon", "Boutique Pokémon", "Devon SARL", "École des Dresseurs", "Arène de Mérouville"]),
    ("village_myokara", "Village Myokara", ["Centre Pokémon", "Boutique Pokémon", "Arène de Myokara"]),
    ("poivressel", "Poivressel", ["Centre Pokémon", "Boutique Pokémon", "Musée Océanographique", "Centre de Concours"]),
    ("lavandia", "Lavandia", ["Centre Pokémon", "Boutique Pokémon", "Cycles Rodolphe", "Arène de Lavandia"]),
    ("vergazon", "Vergazon", ["Centre Pokémon", "Boutique Pokémon"]),
    ("vermilava", "Vermilava", ["Centre Pokémon", "Boutique Pokémon", "Arène de Vermilava", "Sources chaudes"]),
    ("autequia", "Autéquia", ["Centre Pokémon", "Boutique Pokémon", "Maison du Professeur Kosmo"]),
    ("cimetronelle", "Cimetronelle", ["Centre Pokémon", "Boutique Pokémon", "Arène de Cimetronelle"]),
    ("nenucrique", "Nénucrique", ["Centre Pokémon", "Boutique Pokémon", "Centre Commercial Nénucrique", "Musée de Nénucrique", "Centre de Concours", "Planque de la Team"]),
    ("algatia", "Algatia", ["Centre Pokémon", "Boutique Pokémon", "Centre Spatial", "Arène d'Algatia"]),
    ("atalanopolis", "Atalanopolis", ["Centre Pokémon", "Boutique Pokémon", "Arène d'Atalanopolis"]),
    ("pacifiville", "Pacifiville", ["Centre Pokémon", "Boutique Pokémon"]),
    ("eternara", "Éternara", ["Centre Pokémon", "Boutique Pokémon"]),
]
for id, name, _buildings in towns:
    zone(id, name, "town", "town")

for route in (101, 102, 103, 104, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 123):
    biome = "grass"
    if route in (111,): biome = "desert"
    if route in (112,): biome = "mountain"
    if route in (113,): biome = "ash"
    zone(f"route_{route}", f"Route {route}", "route", biome)
for channel in range(105, 110):
    zone(f"chenal_{channel}", f"Chenal {channel}", "route", "sea")
for channel in (122, *range(124, 135)):
    zone(f"chenal_{channel}", f"Chenal {channel}", "route", "sea")

# Connexions de la carte régionale, d'après la table française des routes.
for a,b in [
    ("bourg_en_vol","route_101"),("route_101","rosyeres"),
    ("rosyeres","route_102"),("route_102","clementi_ville"),
    ("rosyeres","route_103"),("route_103","route_110"),
    ("clementi_ville","route_104"),("route_104","merouville"),
    ("route_104","chenal_105"),("chenal_105","chenal_106"),("chenal_106","village_myokara"),
    ("village_myokara","chenal_107"),("chenal_107","chenal_108"),("chenal_108","chenal_109"),("chenal_109","poivressel"),
    ("poivressel","route_110"),("route_110","lavandia"),
    ("lavandia","route_111"),("route_111","route_112"),("route_111","route_113"),
    ("route_112","vermilava"),("route_113","autequia"),("autequia","route_114"),("route_114","route_115"),("route_115","merouville"),
    ("merouville","route_116"),("route_116","vergazon"),("vergazon","route_117"),("route_117","lavandia"),
    ("lavandia","route_118"),("route_118","route_119"),("route_119","cimetronelle"),
    ("cimetronelle","route_120"),("route_120","route_121"),("route_121","nenucrique"),("route_121","chenal_122"),("chenal_122","route_123"),("route_123","route_118"),
    ("nenucrique","chenal_124"),("chenal_124","algatia"),("chenal_124","chenal_125"),("chenal_125","algatia"),("chenal_124","chenal_126"),
    ("chenal_126","chenal_127"),("chenal_126","atalanopolis"),("algatia","chenal_127"),("chenal_127","chenal_128"),
    ("chenal_128","eternara"),("chenal_128","chenal_129"),("chenal_129","chenal_130"),("chenal_130","chenal_131"),("chenal_131","pacifiville"),
    ("pacifiville","chenal_132"),("chenal_132","chenal_133"),("chenal_133","chenal_134"),("chenal_134","poivressel")
]: link(a,b)

# Bâtiments : chaque intérieur est une scène indépendante reliée à la ville.
for town_id, town_name, buildings in towns:
    for index, building in enumerate(buildings):
        room_id = f"{town_id}_interieur_{index+1:02d}"
        if "Arène" in building: kind = "gym"
        elif "Centre Pokémon" in building: kind = "interior"
        elif "Boutique" in building or "Cycles" in building or "Commercial" in building: kind = "shop"
        elif "Musée" in building or "Spatial" in building or "Devon" in building or "École" in building: kind = "interior"
        else: kind = "interior"
        zone(room_id, building, kind, "interior", size=(20, 14), parent=town_id)
        link(town_id, room_id, "door")

# Sites remarquables ROSA, rattachés à leur route, ville ou chenal d'accès.
sites = [
    ("bois_clementi","Bois Clémenti","forest","route_104"),
    ("grotte_ilot","Grotte de l'Îlot","cave","chenal_105"),
    ("grotte_granite","Grotte Granite","cave","chenal_106"),
    ("piste_cyclable","Piste Cyclable du Bord de Mer","route","route_110"),
    ("maison_pieges","Maison des Pièges","interior","route_110"),
    ("desert_central","Désert Central","desert","route_111"),
    ("ruines_desert","Ruines Désert","cave","desert_central"),
    ("mont_chimnee","Mont Chimnée","mountain","route_112"),
    ("chemin_ardent","Chemin Ardent","cave","route_112"),
    ("sentier_sinuroc","Sentier Sinuroc","mountain","mont_chimnee"),
    ("site_meteore","Site Météore","cave","route_114"),
    ("tunnel_merazon","Tunnel Mérazon","cave","route_116"),
    ("centre_meteo","Centre Météo","interior","route_119"),
    ("grotte_zenith","Grotte Zénith","cave","route_120"),
    ("tombeau_antique","Tombeau Antique","cave","route_120"),
    ("parc_safari","Parc Safari","forest","route_121"),
    ("mont_memoria","Mont Mémoria","mountain","chenal_122"),
    ("grotte_trefonds","Grotte Tréfonds","cave","chenal_125"),
    ("lavandia_sea","Lavandia Sea","sea","chenal_108"),
    ("new_lavandia","New Lavandia","cave","lavandia"),
    ("planque_aqua","Planque Aqua (Saphir Alpha)","cave","nenucrique"),
    ("planque_magma","Planque Magma (Rubis Oméga)","cave","nenucrique"),
    ("caverne_fondmer","Caverne Fondmer","cave","chenal_128"),
    ("sanctuaire","Sanctuaire","cave","chenal_134"),
    ("grotte_origine","Grotte Origine","cave","atalanopolis"),
    ("pilier_celeste","Pilier Céleste","mountain","route_131" if "route_131" in nodes else "chenal_131"),
    ("route_victoire","Route Victoire","cave","eternara"),
    ("la_marina","La Marina","interior","poivressel"),
    ("atoll_combat","Atoll de Combat","island","poivressel"),
    ("ile_sud","Île du Sud","island","route_118"),
    ("maison_marco","Maison de M. Marco","interior","route_104"),
    ("fleuriste_jolie_fleur","Fleuriste Jolie Fleur","interior","route_104"),
    ("maison_bord_mer","Maison du Bord de Mer","interior","chenal_109"),
    ("pension_pokemon","Pension Pokémon","interior","route_117"),
    ("maison_fossile","Maison du Fossile","interior","route_114"),
    ("maison_cendres","Maison du Ramasseur de Cendres","interior","route_113"),
    ("maison_tresors","Maison du Chercheur de Trésors","interior","chenal_124"),
]
for id,name,biome,parent in sites:
    zone(id,name,"site",biome,size=(24,16))
    if id not in ("sanctuaire", "atoll_combat"):
        link(parent,id,"branch")

zone("ligue_hoenn", "Ligue Pokémon de Hoenn", "league", "interior")
link("route_victoire","ligue_hoenn","path")
link("nenucrique","atoll_combat","boat","Bateau")
link("poivressel","atoll_combat","boat","Bateau")
link("chenal_134","sanctuaire","dive","Plongée")

# Lieux mirages et Grand Ciel : zones optionnelles du Grand Envol.
zone("grand_ciel", "Grand Ciel", "sky", "sky", size=(24,16))
link("route_118","grand_ciel","sky","Grand Envol")
mirages = [
    ("ile_mirage","Île Mirage","island"),("grotte_mirage","Grotte Mirage","cave"),
    ("foret_mirage","Forêt Mirage","forest"),("mont_mirage","Mont Mirage","mountain"),
    ("foret_impenetrable","Forêt Impénétrable","forest"),("grotte_oubliee","Grotte Oubliée","cave"),
    ("faille_dimensionnelle","Faille Dimensionnelle","sky"),("plaine_sans_nom","Plaine Sans Nom","grass"),
    ("gros_nuages_noirs","Gros nuages noirs","sky"),("grotte_evanescente","Grotte Évanescente","cave"),
    ("gouffre_informe","Gouffre Informe","cave"),("ile_arc","Île de l'Arc","island")
]
for id,name,biome in mirages:
    zone(id,name,"mirage",biome,size=(24,16))
    link("grand_ciel",id,"mirage","Grand Envol")

# Fabrique des plans complets de terrain et d'éléments de décor.
TILE = {"G":[0,0],"g":[1,0],"P":[2,0],"p":[3,0],"W":[4,0],"w":[5,0],"T":[6,0],"F":[7,0],"R":[0,1],"D":[1,1],"C":[2,1],"I":[3,1],"B":[4,1],"H":[5,1],"S":[6,1],"M":[7,1]}

def make_plan(n: dict) -> dict:
    width,height=n["size"]
    kind,biome=n["kind"],n["biome"]
    if kind in ("interior","shop","gym") or biome=="interior": base="I"
    elif biome=="sea": base="W"
    elif biome=="cave": base="C"
    elif biome in ("mountain","ash"): base="R"
    elif biome=="desert": base="D"
    elif biome=="sky": base="S"
    elif biome=="island": base="D"
    else: base="G"
    grid=[[base for _ in range(width)] for _ in range(height)]
    def put(x:int,y:int,v:str)->None:
        if 0<=x<width and 0<=y<height: grid[y][x]=v
    if kind in ("interior","shop","gym") or biome=="interior":
        for x in range(width): put(x,0,"I");put(x,height-1,"I")
        for y in range(height): put(0,y,"I");put(width-1,y,"I")
        for x in range(width//2-2,width//2+3):put(x,height-1,"P")
        for x in range(3,width-3,5):
            for y in range(3,height-3):
                if (x+y)%2==0: put(x,y,"B")
    else:
        # Bordure paysagère et chemins de liaison.
        for x in range(width):
            if base=="W":
                if x%5==1: put(x,height//2,"D")
            elif base=="G": put(x,0,"T");put(x,height-1,"T")
            else: put(x,0,"R");put(x,height-1,"R")
        for y in range(height):
            if base=="G":put(0,y,"T");put(width-1,y,"T")
            elif base!="W":put(0,y,"R");put(width-1,y,"R")
        # Tracé croisé adapté au biome; les accès restent toujours atteignables.
        if base=="W":
            for y in range(height):
                for x in range(width):
                    if (x//4+y//4)%3==0: put(x,y,"w")
            for x in range(2,width-2): put(x,height//2,"D" if x%4==0 else "P")
            for y in range(2,height-2): put(width//2,y,"D" if y%4==0 else "P")
        else:
            for x in range(1,width-1):put(x,height//2,"P")
            for y in range(1,height-1):put(width//2,y,"P")
            if base=="G":
                for y in range(2,height-2):
                    for x in range(2,width-2):
                        if (x*13+y*7+len(n["id"]))%11==0 and grid[y][x]=="G":put(x,y,"F")
            if base in ("R","C"):
                for y in range(2,height-2):
                    for x in range(2,width-2):
                        if (x*7+y*3+len(n["id"]))%13==0 and grid[y][x]==base:put(x,y,"R")
            if base=="D":
                for y in range(2,height-2):
                    for x in range(2,width-2):
                        if (x*3+y*5+len(n["id"]))%17==0:put(x,y,"R")
        if kind=="town":
            for x in range(4,width-4): put(x,height//2+3,"P")
            for y in range(height//2-1,height//2+4):put(width//2,y,"P")
            # Petits groupes de bâtiments (les portes sont créées par le générateur).
            for index in range(6):
                bx=3+(index%3)*8; by=3+(index//3)*7
                for y in range(by,by+3):
                    for x in range(bx,bx+4):put(x,y,"B")
                put(bx+1,by+3,"P");put(bx+2,by+3,"P")
        elif kind=="site" and base!="W":
            for y in range(2,height-2):
                for x in range(2,width-2):
                    if (x*5+y*11+len(n["name"]))%9==0 and grid[y][x]==base:put(x,y,"T" if base=="G" else "R")
    terrain=["".join(row) for row in grid]
    npcs=[{"name":"Voyageur","cell":[width//2+2,height//2-1],"dialogue":f"Bienvenue dans la zone : {n['name']}."}]
    items=[{"name":"Objet trouvé","cell":[width//2-2,height//2+1],"dialogue":"Tu as trouvé un objet. (Système d'inventaire à venir.)"}]
    return {"id":n["id"],"size":[width,height],"terrain":terrain,"tiles":TILE,"npcs":npcs,"items":items,"sign":{"cell":[width//2,height//2-2],"dialogue":n["name"]+" — prenez le temps d'explorer."}}

# Associe chaque bâtiment déclaré à une scène dédiée.
for town_id,town_name,buildings in towns:
    pass
manifest={"version":1,"tile_size":16,"nodes":list(nodes.values()),"edges":edges}
(DATA/"world.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
for n in nodes.values():
    (MAPS/f"{n['id']}.json").write_text(json.dumps(make_plan(n),ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(f"Graphe créé : {len(nodes)} zones, {len(edges)} liaisons, {len(nodes)} plans.")
