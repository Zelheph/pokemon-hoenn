# Inventaire des assets

Source inspectée : `/home/zeleph/Téléchargements` (fichiers non liés ignorés : cache `GLCache`). Les originaux restent intacts.

## Assets copiés

| Catégorie | Fichier | Format / dimensions | Détail |
|---|---|---:|---|
| fonts | `assets/fonts/emerald_font_reference.gif` | GIF 779×431 px | Police bitmap de référence |
| reference | `assets/reference/littleroot_town_reference.png` | PNG 912×616 px | Référence visuelle de Bourg-en-Vol (pas une carte jouable) |
| reference | `assets/reference/rydels_bike_shop_reference.png` | PNG 427×261 px | Référence de bâtiment |
| reference | `assets/reference/safari_zone_reference.png` | PNG 2100×1280 px | Référence de zone |
| sprites | `assets/sprites/characters/brendan_overworld_sheet.png` | PNG 337×228 px | Feuille joueur fournie ; spritesheet, frames d’origine à découper selon personnages/animations |
| sprites | `assets/sprites/characters/map_objects_sheet.png` | PNG 447×238 px | Objets de carte ; spritesheet, frames d’origine à découper selon personnages/animations |
| sprites | `assets/sprites/characters/may_overworld_sheet.png` | PNG 676×478 px | Feuille personnage jouable ; spritesheet, frames d’origine à découper selon personnages/animations |
| sprites | `assets/sprites/characters/npc_overworld_sheet.png` | PNG 856×695 px | PNJ ; spritesheet, frames d’origine à découper selon personnages/animations |
| sprites | `assets/sprites/pokemon/252.png` | PNG 96×96 px | Sprite frontal Treecko (source sprites-latest) ; sprite individuel, transparent |
| sprites | `assets/sprites/pokemon/255.png` | PNG 96×96 px | Sprite frontal Torchic (source sprites-latest) ; sprite individuel, transparent |
| sprites | `assets/sprites/pokemon/258.png` | PNG 96×96 px | Sprite frontal Mudkip (source sprites-latest) ; sprite individuel, transparent |
| tilesets | `assets/tilesets/emerald_exterior_tileset.png` | PNG 1408×1104 px | Planche extérieure Émeraude, source principale de tuiles ; grille visée 88×69 cases de 16×16 px (à vérifier/importer selon usage) |
| tilesets | `assets/tilesets/emerald_interior_tilesets.png` | PNG 3072×1024 px | Planches intérieures Émeraude ; grille visée 192×64 cases de 16×16 px (à vérifier/importer selon usage) |
| ui | `assets/ui/bag_reference.png` | PNG 664×264 px | Référence UI sac |
| ui | `assets/ui/battle_introductions_reference.png` | PNG 522×349 px | Référence UI combat |
| ui | `assets/ui/box_system_reference.png` | PNG 680×1216 px | Référence UI PC/boîtes |
| ui | `assets/ui/hoenn_map_reference.png` | PNG 240×272 px | Référence carte régionale |
| ui | `assets/ui/mail_reference.png` | PNG 726×648 px | Référence UI courrier |
| ui | `assets/ui/move_effects_reference.png` | PNG 491×1926 px | Référence effets visuels |
| ui | `assets/ui/pokedex_reference.png` | PNG 537×673 px | Référence Pokédex |
| ui | `assets/ui/pokemon_menu_reference.png` | PNG 840×480 px | Référence menu Pokémon |
| ui | `assets/ui/route_icons_reference.png` | PNG 547×348 px | Icônes routes |
| ui | `assets/ui/stat_effects_reference.png` | PNG 328×88 px | Icônes effets de stats |

## Taille des cases

Le projet cible une grille de **16×16 px** conformément à `AGENTS.md`. Les planches de tuiles sont des images d’extraction avec annotations et ne sont pas garanties comme atlas homogènes : aucun découpage n’a été figé à cette étape. Les références de lieux ne sont pas utilisées comme textures de carte.

## Sources examinées mais non copiées en bloc

`sprites-latest/sprites/pokemon` contient plus de 92 000 fichiers pour environ 12 Go (variantes/formes et générations). Seuls les trois sprites de départ Hoenn ont été copiés pour le prototype ; le reste demeure disponible dans Téléchargements et sera sélectionné lorsque les données/écrans le nécessiteront.

## Manques identifiés

- Sprite sheet joueur correctement découpé en frames 4 directions (présent comme source, mais cadrage à établir).
- Sons et musiques de jeu : aucun fichier audio détecté parmi les assets examinés.
- Polices utilisables comme ressource de production : seule une image GIF de référence est fournie.
- Sprites animés de combat, icônes d’objets prêts à l’emploi, effets UI originaux.
- Les images UI/cartes sont des références extraites du jeu et ne remplacent pas encore des composants d’interface adaptés au projet.
