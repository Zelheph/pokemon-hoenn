extends SceneTree

const PLAN_PATH: String = "res://data/maps/bourg_en_vol.json"
const STAMPS_PATH: String = "res://data/building_stamps.json"
const WORLD_PATH: String = "res://data/world.json"
const SCENE_PATH: String = "res://scenes/hoenn/"
const TILE_SIZE: int = 16

func _initialize() -> void:
	var errors: Array[String] = []
	var plan: Dictionary = _read_json(PLAN_PATH)
	var stamp_data: Dictionary = _read_json(STAMPS_PATH)
	var stamps: Dictionary = {}
	for value: Variant in stamp_data.get("stamps", []):
		var stamp: Dictionary = value
		stamps[str(stamp["id"])] = stamp
	var packed: PackedScene = load(SCENE_PATH + "bourg_en_vol.tscn") as PackedScene
	if packed == null:
		push_error("Scène Bourg-en-Vol illisible.")
		quit(1)
		return
	var scene: Node2D = packed.instantiate() as Node2D
	var terrain: TileMapLayer = scene.get_node("Terrain") as TileMapLayer
	var blocker: StaticBody2D = scene.get_node("TerrainCollisions") as StaticBody2D
	var actual_solids: Dictionary = {}
	for child: Node in blocker.get_children():
		var shape_node: CollisionShape2D = child as CollisionShape2D
		if shape_node != null:
			actual_solids[_cell_from_center(shape_node.position)] = true
	var expected_solids: Dictionary = {}
	var rows: Array = plan["terrain"]
	for y: int in range(rows.size()):
		var row: String = str(rows[y])
		for x: int in range(row.length()):
			if row.substr(x, 1) in ["T", "R", "B", "H", "W", "w"]:
				expected_solids[Vector2i(x, y)] = true
	for building_value: Variant in plan.get("buildings", []):
		var building: Dictionary = building_value
		var stamp: Dictionary = stamps[str(building["stamp"])]
		var origin_data: Array = building["position"]
		var origin := Vector2i(int(origin_data[0]), int(origin_data[1]))
		var width: int = int(stamp["size"][0])
		var height: int = int(stamp["size"][1])
		var covered: Dictionary = {}
		for tile_value: Variant in stamp["tiles"]:
			var tile: Dictionary = tile_value
			var offset_data: Array = tile["offset"]
			var offset := Vector2i(int(offset_data[0]), int(offset_data[1]))
			if offset.x < 0 or offset.y < 0 or offset.x >= width or offset.y >= height:
				errors.append("%s : tuile hors stamp %s" % [building["stamp"], offset])
				continue
			covered[offset] = true
			var cell: Vector2i = origin + offset
			var expected_source := 30 if str(stamp.get("roof_variant", "")) == "band_01_rival_roof" and str(tile["role"]) == "roof" else 10 + int(stamp["band"]) - 1
			if terrain.get_cell_source_id(cell) != expected_source or terrain.get_cell_atlas_coords(cell) != Vector2i(int(tile["atlas"][0]), int(tile["atlas"][1])):
				errors.append("%s : tuile posée différente du stamp en %s" % [building["stamp"], cell])
		for solid_value: Variant in stamp["solid_cells"]:
			var solid_data: Array = solid_value
			var cell := origin + Vector2i(int(solid_data[0]), int(solid_data[1]))
			expected_solids[cell] = true
		for traversable_value: Variant in stamp["traversable_cells"]:
			var pass_data: Array = traversable_value
			var cell := origin + Vector2i(int(pass_data[0]), int(pass_data[1]))
			if stamp["solid_cells"].has(pass_data):
				errors.append("%s : une cellule de porte/approche est également solide" % building["stamp"])
			if actual_solids.has(cell):
				errors.append("%s : cellule traversable bloquée en %s" % [building["stamp"], cell])
		var door: Dictionary = stamp["door"]
		var door_data: Array = door["position"]
		var door_cell := origin + Vector2i(int(door_data[0]), int(door_data[1]))
		var approach_data: Array = door["approach"]
		var approach := origin + Vector2i(int(approach_data[0]), int(approach_data[1]))
		if actual_solids.has(door_cell) or actual_solids.has(approach):
			errors.append("%s : porte ou case d'approche bloquée" % building["stamp"])
		var interior_id: String = str(building["interior_id"])
		var door_area: Area2D = scene.get_node_or_null("Transition_" + interior_id) as Area2D
		if door_area == null or not door_area.is_in_group("zone_transition") or str(door_area.get_meta("target_scene", "")) != SCENE_PATH + interior_id + ".tscn":
			errors.append("%s : Area2D de porte sans scène intérieure cible" % building["stamp"])
		else:
			var area_offset_data: Array = door.get("area_offset_px", [0, 0])
			var expected_area_position: Vector2 = _cell_center(door_cell) + Vector2(float(area_offset_data[0]), float(area_offset_data[1]))
			if door_area.position != expected_area_position:
				errors.append("%s : Area2D mal alignée sur la porte" % building["stamp"])
			var target_scene: PackedScene = load(str(door_area.get_meta("target_scene"))) as PackedScene
			if target_scene == null:
				errors.append("%s : scène intérieure absente" % building["stamp"])
			else:
				var interior: Node = target_scene.instantiate()
				var has_return := false
				for candidate: Node in interior.find_children("Transition_*", "Area2D", false, false):
					var return_area: Area2D = candidate as Area2D
					if str(return_area.get_meta("target_scene", "")) == SCENE_PATH + "bourg_en_vol.tscn" and return_area.get_meta("arrival_cell", Vector2i(-1, -1)) == approach:
						has_return = true
				if not has_return:
					errors.append("%s : scène intérieure sans transition de retour sur l'approche" % building["stamp"])
				interior.free()
		# Chaque cellule visible du stamp doit être solide ou explicitement traversable.
		var complete_cells: Dictionary = {}
		for cell: Vector2i in covered.keys(): complete_cells[cell] = true
		for value: Variant in stamp["solid_cells"]:
			var cell_data: Array = value
			complete_cells.erase(Vector2i(int(cell_data[0]), int(cell_data[1])))
		for value: Variant in stamp["traversable_cells"]:
			var cell_data: Array = value
			complete_cells.erase(Vector2i(int(cell_data[0]), int(cell_data[1])))
		if not complete_cells.is_empty(): errors.append("%s : cellules sans état de collision %s" % [building["stamp"], complete_cells.keys()])
		# Les cases de chemin doivent rester libres de collision structurelle.
		for offset: Vector2i in covered.keys():
			var cell := origin + offset
			if plan["terrain"][cell.y].substr(cell.x, 1) == "P" and offset not in stamp["traversable_cells"]:
				errors.append("%s : le chemin recouvre un toit ou un mur en %s" % [building["stamp"], cell])
	if actual_solids.size() != expected_solids.size():
		errors.append("Nombre de collisions attendu %d, trouvé %d" % [expected_solids.size(), actual_solids.size()])
	for cell: Vector2i in expected_solids.keys():
		if not actual_solids.has(cell): errors.append("Collision manquante en %s" % cell)
	for cell: Vector2i in actual_solids.keys():
		if not expected_solids.has(cell): errors.append("Collision supplémentaire en %s" % cell)

	var portals: Dictionary = plan["portals"]
	var north: Dictionary = portals["route_101"]
	var exit_cell := Vector2i(int(north["cell"][0]), int(north["cell"][1]))
	for building_value: Variant in plan.get("buildings", []):
		var building: Dictionary = building_value
		var stamp: Dictionary = stamps[str(building["stamp"])]
		var origin: Array = building["position"]
		var approach_data: Array = stamp["door"]["approach"]
		var approach := Vector2i(int(origin[0]) + int(approach_data[0]), int(origin[1]) + int(approach_data[1]))
		if not _path_exists(plan["terrain"], approach, exit_cell):
			errors.append("Chemin pavé interrompu entre %s et la sortie nord" % building["stamp"])

	if errors.is_empty():
		print("Validation des façades réussie : %d bâtiments, portes, collisions, retours et chemins vers le nord." % plan.get("buildings", []).size())
	else:
		for message: String in errors: push_error(message)
	scene.free()
	quit(0 if errors.is_empty() else 1)

func _read_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text()) as Dictionary if file != null else {}

func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * TILE_SIZE, (cell.y + 0.5) * TILE_SIZE)

func _cell_from_center(position: Vector2) -> Vector2i:
	return Vector2i(roundi(position.x / TILE_SIZE - 0.5), roundi(position.y / TILE_SIZE - 0.5))

func _path_exists(rows: Array, start: Vector2i, finish: Vector2i) -> bool:
	var visited: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == finish: return true
		for direction: Vector2i in directions:
			var next := current + direction
			if next.y < 0 or next.y >= rows.size(): continue
			var row: String = str(rows[next.y])
			if next.x < 0 or next.x >= row.length() or row.substr(next.x, 1) != "P": continue
			if not visited.has(next):
				visited[next] = true
				queue.append(next)
	return false
