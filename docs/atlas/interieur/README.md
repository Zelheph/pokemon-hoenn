# Planche intérieure Émeraude

La planche source mesure 3072×1024 px, soit une grille globale de 192×64 cases de 16×16 px. Elle est présentée en 24 bandes verticales de 8×64 cases dans les fichiers `bande_01.png` à `bande_24.png`. Sur chaque image, x et y sont les coordonnées locales de la bande; pour retrouver la coordonnée globale, ajouter `8 × (numéro de bande − 1)` à x.

## Éléments identifiés et utilisés

Coordonnées globales de l’atlas, `source_id=0` dans `emerald_interior.tres` :

| Rôle | Coordonnées | Utilisation / observation |
|---|---:|---|
| Mur du fond | (3,25) | Panneau jaune de la pièce domestique |
| Plinthe | (3,26) | Bande basse verte du mur domestique |
| Sol domestique | (2,28) | Dallage gris clair, uniforme dans les maisons |
| Tapis | (3,33), (4,33) | Deux motifs tissés posés devant la sortie |
| Fenêtre | (1,2) | Vitrage bleu encadré, posé sur le mur du fond |
| Étagère | (3,27), (3,28) | Haut et bas de la bibliothèque |
| Télévision | (2,18) | Écran vert sur son meuble |
| Plante | (4,28) | Plante en pot |
| Petite table | (5,29) | Meuble bas rond près du mur |
| Lit | (18–20,47–49) | Composition 3×3, palette crème et jaune |
| Escalier | (22–23,39–40) | Composition 2×2 visible dans la bande 03 |
| Sol du laboratoire | (2,32) | Dallage gris de la zone technique |
| Étagère de laboratoire | (0–1,35) | Deux cases de rayonnage côte à côte |
| Terminal | (2,38) | Poste informatique |
| Bureau / paillasse | (3–4,36) | Deux cases de plan de travail |
| Écran de recherche | (1,41) | Écran vert sur support |
| Plante de laboratoire | (4,40) | Plante en pot de la zone technique |

Les maisons mesurent 10×8 cases et le laboratoire 14×10. Le premier rang dessine le mur du fond, le deuxième sa plinthe, le sol est uniforme et les meubles sont disposés le long des murs ou des côtés. Les deux tuiles de tapis sont devant la porte en bas. Les meubles intérieurs ont leurs propres collisions. La porte elle-même est une Area2D; elle charge uniquement l’intérieur indiqué par le graphe et le plan JSON.

Les vues restent des images de la planche fournie; les objets ne sont pas redessinés. Les pièces assemblent des tuiles de plusieurs bandes quand nécessaire, mais chaque coordonnée désigne une seule case 16×16 de la planche, sans recadrage qui chevauche deux bandes.
