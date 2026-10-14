# AGENTS.md - Jeu Pokémon Hoenn (Godot 4.x)

## Projet
Jeu de rôle 2D de type Pokémon, projet de fan non commercial.
Moteur : Godot 4.x, GDScript typé. Région : Hoenn, d'après la carte de Pokémon Rubis Oméga / Saphir Alpha.
Pixel-art : viewport 480x320, mise à l'échelle entière, filtre Nearest, grille 16x16.

## Règles de travail
- Tu n'as PAS accès à l'éditeur Godot. Crée tout en fichiers texte : scripts .gd, scènes .tscn, ressources .tres, project.godot.
- Après chaque modification, valide avec la ligne de commande :
  - godot --headless --path . --import
  - godot --headless --path . --check-only --script <fichier.gd> pour les scripts
  - godot --headless --path . --quit pour vérifier que le projet se charge sans erreur
  Si le binaire s'appelle autrement (godot4, Godot_v4...), trouve-le et note-le ici.
- Sur cette machine, Godot 4.7.2 est fourni par Flatpak : utiliser `flatpak run org.godotengine.Godot`.
- Corrige toutes les erreurs et warnings avant de conclure une tâche.
- Typage statique partout, signaux plutôt que références directes, commentaires en français.
- Données du jeu en JSON ou Resources, jamais codées en dur dans la logique.
- Un commit git par étape terminée, message clair en français.
- Écris des tests simples pour la logique pure : calcul de dégâts, table des types, capture, expérience, sauvegarde.
- Si une information est ambiguë, pose UNE question avant de continuer.
- Tiens à jour docs/PROGRESS.md à chaque étape.

## Assets
- Les assets fournis par l'utilisateur sont dans son dossier Téléchargements.
- Ne modifie, ne déplace et ne supprime JAMAIS les fichiers d'origine : COPIE-les dans res://assets/ classés par catégorie.
- Décompresse les archives si nécessaire.
- Pour un asset manquant, crée un placeholder nommé placeholder_*.
- Note les licences et crédits dans docs/CREDITS.md.

## Génération des cartes
- Les cartes doivent être de vrais fichiers .tscn avec des TileMapLayer remplis de tuiles.
- Écris un script générateur qui lit le TileSet et construit chaque zone à partir d'un plan JSON.
- Valide chaque carte après génération avec godot --headless --path . --import.
- Respecte docs/WORLD.md pour les connexions entre zones.

## Architecture cible
autoloads : GameState, SaveManager, AudioManager, SceneManager, DataManager
dossiers : assets/, data/, scenes/, scripts/, tests/, docs/
