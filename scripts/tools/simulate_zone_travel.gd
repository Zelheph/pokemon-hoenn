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
	_assert_player_cell(Vector2i(10, 11), Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await _wait_zone("bourg_en_vol")
	_assert_player_cell(Vector2i(4, 6), Vector2i.DOWN)

	var to_rival: Array[Vector2i] = [Vector2i(4,7), Vector2i(11,7), Vector2i(18,7), Vector2i(18,8), Vector2i(25,8), Vector2i(25,7), Vector2i(25,6)]
	await _walk_path(to_rival)
	await _step(Vector2i.UP)
	await _wait_zone("bourg_en_vol_interieur_02")
	_assert_player_cell(Vector2i(10, 11), Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await _wait_zone("bourg_en_vol")
	_assert_player_cell(Vector2i(25, 6), Vector2i.DOWN)

	var to_lab: Array[Vector2i] = [Vector2i(25,7), Vector2i(25,8), Vector2i(18,8), Vector2i(18,7), Vector2i(11,7), Vector2i(11,12), Vector2i(14,12), Vector2i(14,11)]
	await _walk_path(to_lab)
	await _step(Vector2i.UP)
	await _wait_zone("bourg_en_vol_interieur_03")
	_assert_player_cell(Vector2i(10, 11), Vector2i.DOWN)
	await _step(Vector2i.DOWN)
	await _wait_zone("bourg_en_vol")
	_assert_player_cell(Vector2i(14, 11), Vector2i.DOWN)

	var to_north: Array[Vector2i] = [Vector2i(14,12), Vector2i(11,12), Vector2i(11,7), Vector2i(15,7), Vector2i(15,0)]
	await _walk_path(to_north)
	await _wait_zone("route_101")
	_assert_player_cell(Vector2i(15, 18), Vector2i.UP)
	_assert_camera_inside()
	await _step(Vector2i.DOWN)
	await _wait_zone("bourg_en_vol")
	_assert_player_cell(Vector2i(15, 1), Vector2i.DOWN)
	_assert_camera_inside()

	if _failures == 0:
		print("Parcours joué avec succès : maison héros, rival, laboratoire, sortie nord, retour Route 101/Bourg; aucun déplacement hors carte.")
	else:
		push_error("Simulation terminée avec %d échec(s)." % _failures)
	quit(0 if _failures == 0 else 1)

func _walk_path(cells: Array[Vector2i]) -> void:
	for cell: Vector2i in cells:
		var current := _player_cell()
		while current != cell:
			var delta := Vector2i.ZERO
			if current.x != cell.x:
				delta.x = signi(cell.x - current.x)
			else:
				delta.y = signi(cell.y - current.y)
			await _step(delta)
			if _zone_id() != "bourg_en_vol":
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
	if current_scene != null and current_scene.get_node_or_null("Player") == player and (player.position.x < 0.0 or player.position.y < 0.0 or player.position.x >= 480.0 or player.position.y >= 320.0):
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
	if player.position.x < 0.0 or player.position.y < 0.0 or player.position.x >= 480.0 or player.position.y >= 320.0:
		_fail("Player is outside map bounds at %s" % player.position)

func _assert_camera_inside() -> void:
	var camera: Camera2D = current_scene.get_node("Player/Camera2D") as Camera2D
	if camera.limit_left != 0 or camera.limit_top != 0 or camera.limit_right != 480 or camera.limit_bottom != 320:
		_fail("Camera bounds are not set to this map")

func _player_cell() -> Vector2i:
	var player: CharacterBody2D = current_scene.get_node("Player") as CharacterBody2D
	return Vector2i(roundi(player.position.x / 16.0 - 0.5), roundi(player.position.y / 16.0 - 0.5))

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
