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
- Commit : `76f0be2` — « Étape 2 : joueur sur grille et zone de test ».

## Zone de test
- `data/test_zone.json` décrit un plan 30×20.
- `scripts/tools/generate_test_zone.gd` construit et enregistre `scenes/hoenn/test_zone.tscn` avec un `TileMapLayer` de 600 cellules, les collisions et le point interactif.
- Ce prototype n’est pas la couverture de Hoenn. Le nom Bourg-en-Vol est utilisé pour cette zone de test d’après le nom officiel français de Littleroot Town.
- Validation dédiée : `scripts/tools/validate_test_zone.gd` confirme les 600 cellules, le joueur et l’interaction.

## Validation effectuée
- Godot 4.7.2 accessible avec `flatpak run org.godotengine.Godot`.
- Réussis : `--headless --path . --import`, `--check-only --script` sur le joueur et le générateur, validation de la scène, puis `--headless --path . --quit`.

## À faire ensuite
- Étape 3 : vérifier les noms français officiels et connexions, rédiger `docs/WORLD.md`, puis générer les cartes complètes, intérieurs, PNJ, transitions et objets. À commencer après que l’utilisateur dise « suivant ».
- Étape 4 : sous-étapes du Pokédex complet à définir et données officielles à sourcer.
- Étape 5 : combats et tests unitaires.
- Étape 6 : menus.
- Étape 7 : progression et scénario.
- Étape 8 : rencontres.
- Étape 9 : sauvegardes multi-emplacements.
- Étape 10 : audio.
- Étape 11 : polish, manette et export Windows.
