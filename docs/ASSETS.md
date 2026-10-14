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
| tilesets | `assets/tilesets/emerald_exterior_tileset.png` | PNG 1408×1104 px | Planche extérieure Émeraude ; grille vérifiée 88×69 cases de 16×16 px |
| tilesets | `assets/tilesets/emerald_exterior.tres` | TileSet atlas 88×69, région 16×16 px | 11 coordonnées de terrain utilisées par les cartes, découpées depuis la planche PNG d’origine |
| tilesets | `assets/tilesets/bands/band_01.png` à `band_11.png` | PNG, chacune 128×1104 px | Bandes indépendantes, chacune 8×69 cases de 16×16 px |
| tilesets (variante) | `assets/tilesets/bands/band_01_rival_roof.png` | PNG, 128×1104 px | Copie recolorée des seules cellules de toit du stamp rival |
| tilesets | `assets/tilesets/emerald_interior_tilesets.png` | PNG 3072×1024 px | Planches intérieures Émeraude ; grille vérifiée 192×64 cases de 16×16 px |
| tilesets | `assets/tilesets/emerald_interior.tres` | TileSet atlas 192×64, région 16×16 px | 7 coordonnées utilisées pour sols, murs et grottes |
| tilesets (placeholder) | `assets/tilesets/placeholder_sky.svg` | SVG 16×16 px | Tuile de ciel pour le Grand Ciel, absente des planches fournies |

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

## Exterior Tileset : bandes et bâtiments

La planche extérieure 1408×1104 est découpée en 11 bandes verticales indépendantes de 128×1104 px (8×69 cases de 16×16). La planche source reste intacte. Les images zoomées avec grille et coordonnées sont dans `docs/atlas/bande_01.png` à `bande_11.png`. Les cases bleu marine uniformes sont vides et exclues du catalogue.

Les bâtiments de Bourg-en-Vol sont assemblés en stamps enregistrés dans `data/building_stamps.json`, avec chaque case référencée dans la bande correspondante, ainsi que les cellules solides, la porte et son approche. Les bandes sont des sources d’atlas TileSet séparées (source_id 10 à 20); le toit recoloré de la maison rivale utilise la source_id 30. Les aperçus ×8 annotés sont dans `docs/atlas/stamps/`. Ces trois assemblages sont des compositions à partir des tuiles fournies, pas des façades déjà présentes en un seul bloc.

## Taille des cases et identifiants de terrain

Les deux planches sont alignées sur une grille réelle de **16×16 px** : extérieure 88×69, intérieure 192×64. `scripts/tools/build_tilesets.gd` vérifie les dimensions, crée les ressources `TileSet` atlas et sélectionne des coordonnées source pour les cases utilisées. Les coordonnées ci-dessous sont des coordonnées d’atlas (x, y), avec `source_id` 0 pour la planche et 1 pour le ciel provisoire.

| Symbole du plan JSON | Terrain | TileSet | Source | Coordonnée atlas |
|---|---|---|---:|---:|
| G / g | Herbe et variante | extérieur | 0 | (87,14) / (87,13) |
| P / p | Pavés / chemin | extérieur | 0 | (84,22) / (83,22) |
| W / w | Eau et variante de vague | extérieur | 0 | (28,56) / (28,58) |
| T / H | Arbre / haie | extérieur | 0 | (5,4) |
| F | Fleurs | extérieur | 0 | (5,0) |
| D | Sable | extérieur | 0 | (26,66) |
| R / M | Roche / relief | extérieur | 0 | (61,40) |
| B | Mur / bâtiment | extérieur | 0 | (48,59) |
| I / P / B | Sol, chemin intérieur, mur | intérieur | 0 | (184,40) / (184,39) / (184,38) |
| C / R / M | Sol de grotte et relief | intérieur | 0 | (180,53) / (178,42) / (176,42) |
| S | Ciel | placeholder | 1 | (0,0) |

`generate_world.gd` choisit le TileSet extérieur ou intérieur selon le plan JSON et applique ces identifiants, au lieu d’un atlas de terrain dessiné pour le projet. `generate_test_zone.gd` utilise également `emerald_exterior.tres` : sa zone de test contient de l’herbe (0, 87,14) et des chemins pavés (0, 84,22). Les autres collisions restent gérées par les symboles de terrain bloquants du plan.

La planche est un rip composite avec des espaces et annotations; l’atlas `.tres` contient les cases réellement utilisées à leur coordonnée d’origine, plutôt que de considérer chaque partie de l’image comme un tile valide. Les références de lieux ne sont pas utilisées comme textures de carte.
## Sources examinées mais non copiées en bloc

`sprites-latest/sprites/pokemon` contient plus de 92 000 fichiers pour environ 12 Go (variantes/formes et générations). Seuls les trois sprites de départ Hoenn ont été copiés pour le prototype ; le reste demeure disponible dans Téléchargements et sera sélectionné lorsque les données/écrans le nécessiteront.

## Manques identifiés

- Assets graphiques dédiés au ciel : seul ce terrain utilise le placeholder SVG, faute de tuile correspondante dans les deux planches.

- Sprite sheet joueur correctement découpé en frames 4 directions (présent comme source, mais cadrage à établir).
- Sons et musiques de jeu : aucun fichier audio détecté parmi les assets examinés.
- Polices utilisables comme ressource de production : seule une image GIF de référence est fournie.
- Sprites animés de combat, icônes d’objets prêts à l’emploi, effets UI originaux.
- Les images UI/cartes sont des références extraites du jeu et ne remplacent pas encore des composants d’interface adaptés au projet.
