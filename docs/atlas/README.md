# Découpe de l’Exterior Tileset

La planche `assets/tilesets/emerald_exterior_tileset.png` mesure 1408 × 1104 px. Elle se découpe sans reste en **11 bandes de 128 px de large**, soit 8 colonnes de tuiles de 16 × 16 px chacune. Les bandes sont indexées de gauche à droite à partir de 1.

Les aperçus `bande_01.png` à `bande_11.png` montrent chaque bande agrandie ×4. Les nombres en haut sont les coordonnées X locales (0–7) ; les nombres à gauche sont les coordonnées Y (0–68). Les cases bleu marine uniformes sont vides et ne sont pas posées par les stamps. Les blocs ne traversent jamais une limite de bande.

Les morceaux de la bande 1 du toit rival sont une variante colorée dérivée dans `assets/tilesets/bands/band_01_rival_roof.png`. La planche fournie et les autres bandes n’ont pas été modifiées.

Les images de stamps dans `stamps/` montrent les assemblages retenus à l’échelle ×8, avec une grille de 16 px. Le catalogue source est `data/building_stamps.json`.
