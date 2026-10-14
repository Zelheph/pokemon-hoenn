# Suivi du projet Pokémon Hoenn

## Étape 1 — terminée et commitée
- Inventaire des fichiers de Téléchargements et copie des assets de jeu identifiés dans `assets/`, classés par catégorie.
- `docs/ASSETS.md` et `docs/CREDITS.md` créés. Les originaux restent intacts.
- Arborescence de base et cinq autoloads (`GameState`, `SaveManager`, `AudioManager`, `SceneManager`, `DataManager`) configurés.
- `project.godot` réglé en 480×320, rendu pixel-art, grille cible 16×16.
- Commit : `09f272e` — « Étape 1 : inventaire et configuration du projet ».

## Étape 2 — terminée
- Joueur `CharacterBody2D` à déplacements par cases 16×16, quatre directions, animation pixel-art de marche et course (Maj).
- Collisions physiques avec les obstacles de la scène de test.
- Interaction avec un panneau devant le joueur (E ou Espace) et affichage de son dialogue.
- Commit : `b62a50f` — « Étape 2 : joueur sur grille et zone de test ».

## Zone de test
- `data/test_zone.json` décrit un plan 30×20.
- `scripts/tools/generate_test_zone.gd` construit et enregistre `scenes/hoenn/test_zone.tscn` avec un `TileMapLayer` de 600 cellules, les collisions et le point interactif.
- Ce prototype n’est pas la couverture de Hoenn. Le nom Bourg-en-Vol est utilisé pour cette zone de test d’après le nom officiel français de Littleroot Town.
- Validation dédiée : `scripts/tools/validate_test_zone.gd` confirme les 600 cellules, le joueur et l’interaction.

## Validation effectuée
- Godot 4.7.2 accessible avec `flatpak run org.godotengine.Godot`.
- Réussis : `--headless --path . --import`, `--check-only --script` sur le joueur et le générateur, validation de la scène, puis `--headless --path . --quit`.

## Étape 3 — terminée
- `docs/WORLD.md` recense les noms français et connexions de Hoenn, avec les sources consultées.
- `data/world.json` décrit 154 zones et 161 liaisons ; chaque zone a son plan de terrain complet (dimensions et rangées de tuiles) dans `data/maps/*.json`.
- `scripts/tools/build_world_data.py` génère les plans ; `scripts/tools/generate_world.gd` les convertit en scènes `.tscn` contenant un `TileMapLayer`, collisions, joueur, acteurs interactifs et Area2D de transition.
- Scènes créées pour villes, routes, chenaux, intérieurs, arènes, grottes, forêts, montagnes, sites, Ligue et lieux mirages. `SceneManager` réalise le fondu au noir et replace le joueur à l’entrée correspondante.
- Les dialogues, panneaux et objets sont des exemples génériques. Les plans sont originaux et schématiques, pas des copies exactes des cartes de ROSA. Les scènes utilisent les TileSet atlas réels extraits des planches fournies; seul le ciel reste un placeholder faute d’asset adapté.
- `scenes/main.tscn` démarre maintenant à Bourg-en-Vol ; la zone de test dédiée reste disponible.
- Commit : dédié à cette étape.

## Validation effectuée
- Godot 4.7.2 : `--headless --path . --import`, contrôle syntaxique du générateur et du validateur, génération des 154 scènes, validation des 154 couches remplies et des transitions, puis lancement headless du projet.

## Reprise des façades de la zone de test — terminée
- La planche extérieure est séparée en 11 bandes autonomes de 128 px (8×69 tuiles de 16 px) ; aperçu ×4 quadrillé et coordonnées locales dans `docs/atlas/bande_*.png`.
- `data/building_stamps.json` décrit deux petites maisons jumelles (toit du rival recoloré) et le grand laboratoire, cellule par cellule, avec position de porte, approche, cellules solides et traversables. Aperçus ×8 dans `docs/atlas/stamps/`.
- Le générateur crée les sources d’atlas distinctes pour chaque bande et pose les stamps sans franchir leurs limites. Les portes sont des Area2D vers les intérieurs; Bourg-en-Vol ne garde qu’une sortie nord vers la Route 101. Route 101 et Rosyères ont les ouvertures réciproques au nord/sud.
- Les scènes Bourg-en-Vol, Route 101 et Rosyères ont été régénérées. `docs/atlas/bourg_en_vol.png` donne le rendu complet de la carte (30×20 cases, 960×640 px).
- Vérifications terminées avec Godot 4.7.2 : import headless, contrôle syntaxique des scripts, validation des 154 scènes/322 transitions et chargement du projet sans erreur.
- Crédit ajouté dans `docs/CREDITS.md`. La maison du héros et celle du rival sont des stamps composites; les grands blocs officiels de Centres, boutiques et arènes sont réservés à un catalogue ultérieur.

## Étapes restantes
- Étape 4 : sous-étapes du Pokédex complet à définir et données officielles à sourcer.
- Étape 5 : combats et tests unitaires.
- Étape 6 : menus.
- Étape 7 : progression et scénario.
- Étape 8 : rencontres.
- Étape 9 : sauvegardes multi-emplacements.
- Étape 10 : audio.
- Étape 11 : polish, manette et export Windows.
