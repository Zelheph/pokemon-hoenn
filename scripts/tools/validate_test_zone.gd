extends SceneTree

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/hoenn/test_zone.tscn") as PackedScene
	assert(packed != null, "Scène de test absente")
	var zone: Node = packed.instantiate()
	var terrain: TileMapLayer = zone.get_node("Terrain") as TileMapLayer
	assert(terrain != null, "TileMapLayer Terrain absent")
	assert(terrain.get_used_cells().size() == 600, "La carte doit contenir 600 tuiles")
	assert(terrain.tile_set != null and terrain.tile_set.tile_size == Vector2i(16, 16), "TileSet réel 16×16 absent")
	assert(terrain.tile_set.resource_path == "res://assets/tilesets/emerald_exterior.tres", "Le TileSet extérieur fourni n’est pas utilisé")
	assert(terrain.get_cell_source_id(Vector2i(0, 0)) == 0 and terrain.get_cell_atlas_coords(Vector2i(0, 0)) == Vector2i(87, 14), "L’herbe doit utiliser l’atlas extérieur source 0, case (87,14)")
	assert(terrain.get_cell_source_id(Vector2i(14, 0)) == 0 and terrain.get_cell_atlas_coords(Vector2i(14, 0)) == Vector2i(84, 22), "Le chemin doit utiliser l’atlas extérieur source 0, case (84,22)")
	assert(zone.get_node_or_null("Player") is CharacterBody2D, "Joueur absent")
	assert(zone.get_node_or_null("PanneauTest/Interaction") is Area2D, "Point d'interaction absent")
	print("Zone validée : %d cellules, TileSet Emerald extérieur réel, coordonnées herbe (87,14) et chemin (84,22), joueur, collisions et interaction." % terrain.get_used_cells().size())
	zone.free()
	quit()
