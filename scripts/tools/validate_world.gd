extends SceneTree

const WORLD_PATH := "res://data/world.json"
const SCENE_DIR := "res://scenes/hoenn/"

func _initialize() -> void:
	var file := FileAccess.open(WORLD_PATH, FileAccess.READ)
	if file == null:
		push_error("world.json introuvable")
		quit(1)
		return
	var manifest: Dictionary = JSON.parse_string(file.get_as_text()) as Dictionary
	var nodes: Array = manifest["nodes"]
	var edges: Array = manifest["edges"]
	var expected_transitions: Dictionary = {}
	for node_data: Dictionary in nodes:
		expected_transitions[str(node_data["id"])] = 0
	for edge_value: Variant in edges:
		var edge: Dictionary = edge_value
		expected_transitions[str(edge["a"])] += 1
		expected_transitions[str(edge["b"])] += 1
	var failures := 0
	for node_data: Dictionary in nodes:
		var id := str(node_data["id"])
		var path := SCENE_DIR + id + ".tscn"
		var packed := load(path) as PackedScene
		if packed == null:
			push_error("Scène absente ou illisible : " + path)
			failures += 1
			continue
		var root := packed.instantiate()
		var terrain := root.get_node_or_null("Terrain") as TileMapLayer
		if terrain == null:
			push_error("TileMapLayer absent : " + id)
			failures += 1
		else:
			var expected_cells := int(node_data["size"][0]) * int(node_data["size"][1])
			if terrain.get_used_cells().size() != expected_cells:
				push_error("Nombre de cases incorrect : %s (%d/%d)" % [id, terrain.get_used_cells().size(), expected_cells])
				failures += 1
		if root.get_node_or_null("Player") == null:
			push_error("Joueur absent : " + id)
			failures += 1
		var transition_count := root.find_children("Transition_*", "Area2D", false, false).size()
		if transition_count != int(expected_transitions[id]):
			push_error("Transitions incorrectes : %s (%d/%d)" % [id, transition_count, expected_transitions[id]])
			failures += 1
		root.free()
	if failures == 0:
		print("Validation réussie : %d zones, %d transitions directionnelles." % [nodes.size(), edges.size() * 2])
		quit(0)
	else:
		push_error("%d erreur(s) dans le monde." % failures)
		quit(1)
