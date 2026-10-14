extends SceneTree

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/hoenn/test_zone.tscn") as PackedScene
	assert(packed != null, "Scène de test absente")
	var zone: Node = packed.instantiate()
	var terrain: TileMapLayer = zone.get_node("Terrain") as TileMapLayer
	assert(terrain != null, "TileMapLayer Terrain absent")
	assert(terrain.get_used_cells().size() == 600, "La carte doit contenir 600 tuiles")
	assert(zone.get_node_or_null("Player") is CharacterBody2D, "Joueur absent")
	assert(zone.get_node_or_null("PanneauTest/Interaction") is Area2D, "Point d'interaction absent")
	print("Zone validée : %d cellules, joueur, collisions et interaction présents." % terrain.get_used_cells().size())
	zone.free()
	quit()
