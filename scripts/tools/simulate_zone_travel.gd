extends SceneTree

const MAIN_PATH: String = "res://scenes/main.tscn"
const ZONE_DIR: String = "res://scenes/hoenn/"
const STEP_TIMEOUT_FRAMES: int = 90
const TRANSITION_TIMEOUT_FRAMES: int = 180
var _failures: int = 0

func _initialize() -> void:
	call_deferred("_run_scenario")

func _run_scenario() -> void:
	var main_scene: PackedScene = load(MAIN_PATH) as PackedScene
	if main_scene == null:
		_fail("Main scene is missing")
		quit(1)
		return
	var initial_scene: Node = main_scene.instantiate()
	root.add_child(initial_scene)
	current_scene = initial_scene
	await process_frame
	await physics_frame
	_assert_zone("bourg_en_vol")
	_assert_player_cell(Vector2i(4, 6), Vector2i.DOWN)
	_assert_camera_inside()

	await _step(Vector2i.UP)
	await _wait_zone("bourg_en_vol_interieur_01")
	_assert_player_cell(Vector2i(5, 5), Vector2i.DOWN)
	_assert_camera_fits_room()
	await _step(Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await _wait_zone("bourg_en_vol")
	_assert_player_cell(Vector2i(4, 6), Vector2i.DOWN)

	var to_rival: Array[Vector2i] = [Vector2i(4,7), Vector2i(11,7), Vector2i(18,7), Vector2i(18,8), Vector2i(25,8), Vector2i(25,7), Vector2i(25,6)]
	await _walk_path(to_rival)
	await _step(Vector2i.UP)
	await _wait_zone("bourg_en_vol_interieur_02")
	_assert_player_cell(Vector2i(5, 5), Vector2i.DOWN)
	_assert_camera_fits_room()
	await _step(Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await _wait_zone("bourg_en_vol")
	_assert_player_cell(Vector2i(25, 6), Vector2i.DOWN)

	var to_lab: Array[Vector2i] = [Vector2i(25,7), Vector2i(25,8), Vector2i(18,8), Vector2i(18,7), Vector2i(11,7), Vector2i(11,12), Vector2i(14,12), Vector2i(14,11)]
	await _walk_path(to_lab)
	await _step(Vector2i.UP)
	await _wait_zone("bourg_en_vol_interieur_03")
	_assert_player_cell(Vector2i(7, 7), Vector2i.DOWN)
	_assert_camera_fits_room()
	await _step(Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await _wait_zone("bourg_en_vol")
	_assert_player_cell(Vector2i(14, 11), Vector2i.DOWN)

	var to_north: Array[Vector2i] = [Vector2i(14,12), Vector2i(11,12), Vector2i(11,7), Vector2i(15,7), Vector2i(15,0)]
	await _walk_path(to_north)
	await _wait_zone("route_101")
	_assert_player_cell(Vector2i(15, 38), Vector2i.UP)
	_assert_camera_inside()
	_assert_tall_grass_triggers()
	var path_to_rosyeres: Array[Vector2i] = _paved_path(Vector2i(15, 38), Vector2i(15, 0))
	await _walk_path(path_to_rosyeres)
	await _wait_zone("rosyeres")
	_assert_player_cell(Vector2i(15, 18), Vector2i.UP)
	_assert_camera_inside()

	if _failures == 0:
		print("Parcours joué avec succès : trois intérieurs, portes de retour, Route 101, hautes herbes et liaison nord vers Rosyères; aucun déplacement hors carte.")
	else:
		push_error("Simulation terminée avec %d échec(s)." % _failures)
	quit(0 if _failures == 0 else 1)

func _walk_path(cells: Array[Vector2i]) -> void:
	var source_zone: String = _zone_id()
	for cell: Vector2i in cells:
		var current := _player_cell()
		while current != cell:
			var delta := Vector2i.ZERO
			if current.x != cell.x:
				delta.x = signi(cell.x - current.x)
			else:
				delta.y = signi(cell.y - current.y)
			await _step(delta)
			if _zone_id() != source_zone:
				return
			current = _player_cell()

func _step(direction: Vector2i) -> void:
	if current_scene == null or current_scene.get_node_or_null("Player") == null:
		_fail("Cannot step without an active player")
		return
	var player: CharacterBody2D = current_scene.get_node("Player") as CharacterBody2D
	var source_zone: String = _zone_id()
	var expected: Vector2i = _player_cell() + direction
	var action: StringName = _action_for(direction)
	Input.action_press(action)
	var reached := false
	for frame: int in range(STEP_TIMEOUT_FRAMES):
		await physics_frame
		if current_scene == null or _zone_id() != source_zone or current_scene.get_node_or_null("Player") == null:
			reached = true
			break
		if _player_cell() == expected:
			reached = true
			break
	Input.action_release(action)
	await physics_frame
	if not reached:
		_fail("Player could not step to %s" % expected)
	var size: Vector2i = _zone_size()
	if current_scene != null and current_scene.get_node_or_null("Player") == player and (player.position.x < 0.0 or player.position.y < 0.0 or player.position.x >= size.x * 16.0 or player.position.y >= size.y * 16.0):
		_fail("Player left the 30x20-tile map at %s" % player.position)

func _wait_zone(expected_id: String) -> void:
	for frame: int in range(TRANSITION_TIMEOUT_FRAMES):
		await process_frame
		if _zone_id() == expected_id:
			if not bool(root.get_node("SceneManager").call("is_changing_zone")):
				_assert_zone(expected_id)
				return
	_fail("Timed out while waiting for zone %s; current=%s" % [expected_id, _zone_id()])
	quit(1)

func _assert_zone(expected_id: String) -> void:
	if _zone_id() != expected_id: _fail("Expected zone %s, got %s" % [expected_id, _zone_id()])

func _assert_player_cell(expected_cell: Vector2i, expected_facing: Vector2i) -> void:
	var player: CharacterBody2D = current_scene.get_node("Player") as CharacterBody2D
	if _player_cell() != expected_cell: _fail("Expected player cell %s, got %s" % [expected_cell, _player_cell()])
	if player.get("facing") != expected_facing: _fail("Expected facing %s, got %s" % [expected_facing, player.get("facing")])
	var size: Vector2i = _zone_size()
	if player.position.x < 0.0 or player.position.y < 0.0 or player.position.x >= size.x * 16.0 or player.position.y >= size.y * 16.0:
		_fail("Player is outside map bounds at %s" % player.position)

func _assert_camera_inside() -> void:
	var camera: Camera2D = current_scene.get_node("Player/Camera2D") as Camera2D
	var size: Vector2i = _zone_size()
	if camera.limit_left != 0 or camera.limit_top != 0 or camera.limit_right != size.x * 16 or camera.limit_bottom != size.y * 16:
		_fail("Camera bounds are not set to this map")
	if camera.zoom != Vector2.ONE:
		_fail("Camera d'extérieur avec un zoom inattendu")

func _assert_camera_fits_room() -> void:
	var camera: Camera2D = current_scene.get_node("Camera2D") as Camera2D
	var backdrop: Polygon2D = current_scene.get_node_or_null("InteriorBlackBackground") as Polygon2D
	var size: Vector2i = _zone_size()
	if camera.limit_left != 0 or camera.limit_top != 0 or camera.limit_right != size.x * 16 or camera.limit_bottom != size.y * 16:
		_fail("Limites de caméra incorrectes dans la pièce")
	if camera.get_parent() != current_scene:
		_fail("La caméra intérieure doit rester centrée sur la pièce")
	if camera.global_position != Vector2(size.x * 8.0, size.y * 8.0):
		_fail("La caméra intérieure n'est pas centrée sur la pièce")
	if camera.zoom.x < 1.0 or camera.zoom.y < 1.0:
		_fail("La caméra intérieure ne cadre pas la pièce")
	if backdrop == null or backdrop.color != Color.BLACK:
		_fail("Le fond noir de cadrage est absent")

func _assert_tall_grass_triggers() -> void:
	var count := 0
	for candidate: Node in get_nodes_in_group("tall_grass_encounter"):
		if candidate is Area2D and bool(candidate.get_meta("encounter_trigger", false)):
			count += 1
	if count == 0:
		_fail("Route 101 ne contient aucune Area2D de hautes herbes")

func _player_cell() -> Vector2i:
	var player: CharacterBody2D = current_scene.get_node("Player") as CharacterBody2D
	return Vector2i(roundi(player.position.x / 16.0 - 0.5), roundi(player.position.y / 16.0 - 0.5))

func _zone_size() -> Vector2i:
	var file: FileAccess = FileAccess.open("res://data/world.json", FileAccess.READ)
	if file == null: return Vector2i(30, 20)
	var manifest: Dictionary = JSON.parse_string(file.get_as_text()) as Dictionary
	for node_value: Variant in manifest["nodes"]:
		var node_data: Dictionary = node_value
		if str(node_data["id"]) == _zone_id():
			var size: Array = node_data["size"]
			return Vector2i(int(size[0]), int(size[1]))
	return Vector2i(30, 20)

func _paved_path(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
	var file: FileAccess = FileAccess.open("res://data/maps/route_101.json", FileAccess.READ)
	if file == null: return []
	var plan: Dictionary = JSON.parse_string(file.get_as_text()) as Dictionary
	var rows: Array = plan["terrain"]
	var queue: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: Vector2i(-1, -1)}
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == finish: break
		for direction: Vector2i in directions:
			var next: Vector2i = current + direction
			if next.y < 0 or next.y >= rows.size(): continue
			var row: String = str(rows[next.y])
			if next.x < 0 or next.x >= row.length() or row.substr(next.x, 1) != "P": continue
			if came_from.has(next): continue
			came_from[next] = current
			queue.append(next)
	if not came_from.has(finish):
		_fail("Aucun chemin pavé continu sur la Route 101")
		return []
	var path: Array[Vector2i] = []
	var cursor: Vector2i = finish
	while cursor != start:
		path.push_front(cursor)
		cursor = came_from[cursor]
	return path

func _zone_id() -> String:
	if current_scene == null: return "<none>"
	return str(current_scene.get("zone_id"))

func _action_for(direction: Vector2i) -> StringName:
	if direction == Vector2i.UP: return &"move_up"
	if direction == Vector2i.DOWN: return &"move_down"
	if direction == Vector2i.LEFT: return &"move_left"
	return &"move_right"

func _fail(message: String) -> void:
	_failures += 1
	push_error(message)
