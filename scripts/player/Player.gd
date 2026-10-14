extends CharacterBody2D

const TILE_SIZE: int = 16
const WALK_SPEED: float = 96.0
const RUN_SPEED: float = 160.0

var facing: Vector2i = Vector2i.DOWN
var _current_cell: Vector2i = Vector2i.ZERO
var _target_position: Vector2 = Vector2.ZERO
var _moving: bool = false
var _walk_phase: int = 0
var _step_progress: float = 0.0

func _ready() -> void:
	_current_cell = Vector2i(roundi(position.x / TILE_SIZE - 0.5), roundi(position.y / TILE_SIZE - 0.5))
	_target_position = position
	get_node("/root/GameState").set("player_position", position)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _moving:
		var remaining: Vector2 = _target_position - position
		var step_speed: float = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
		var movement: Vector2 = remaining.normalized() * minf(step_speed * delta, remaining.length())
		var collision: KinematicCollision2D = move_and_collide(movement)
		if collision != null:
			position = Vector2((_current_cell.x + 0.5) * TILE_SIZE, (_current_cell.y + 0.5) * TILE_SIZE)
			_moving = false
			_step_progress = 0.0
			queue_redraw()
			return
		_step_progress += movement.length()
		if position.distance_to(_target_position) < 0.1:
			position = _target_position
			_current_cell += facing
			_moving = false
			_walk_phase = (_walk_phase + 1) % 2
			_step_progress = 0.0
			get_node("/root/GameState").set("player_position", position)
			queue_redraw()
		return
		if int(_step_progress / 4.0) != int((_step_progress - movement.length()) / 4.0):
			queue_redraw()
		return

	var direction: Vector2i = _read_direction()
	if direction != Vector2i.ZERO:
		facing = direction
		_target_position = position + Vector2(direction) * TILE_SIZE
		_moving = true
		_step_progress = 0.0
		queue_redraw()
	elif Input.is_action_just_pressed("interact"):
		_interact()

func _read_direction() -> Vector2i:
	if Input.is_action_pressed("move_up"):
		return Vector2i.UP
	if Input.is_action_pressed("move_down"):
		return Vector2i.DOWN
	if Input.is_action_pressed("move_left"):
		return Vector2i.LEFT
	if Input.is_action_pressed("move_right"):
		return Vector2i.RIGHT
	return Vector2i.ZERO

func _interact() -> void:
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = position + Vector2(facing) * TILE_SIZE
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var found: Array[Dictionary] = get_world_2d().direct_space_state.intersect_point(query, 8)
	if not found.is_empty():
		var target: Object = found[0].get("collider") as Object
		if target is Node:
			get_node("/root/GameState").emit_signal("interaction_requested", target as Node)

func _draw() -> void:
	# Petit personnage pixel-art provisoire : le sens du regard et les pas changent à quatre directions.
	var bob: int = 1 if _moving and _walk_phase == 1 else 0
	var skin: Color = Color("f4c69a")
	var shirt: Color = Color("2878b8")
	var hair: Color = Color("362a3c")
	var leg_offset: int = 2 if _moving and _walk_phase == 1 else 0
	draw_rect(Rect2(-6, -10 + bob, 12, 11), skin)
	draw_rect(Rect2(-6, -11 + bob, 12, 4), hair)
	draw_rect(Rect2(-7, -7 + bob, 2, 4), hair)
	if facing == Vector2i.UP:
		draw_rect(Rect2(-6, -10 + bob, 12, 7), hair)
	else:
		draw_rect(Rect2(-4 if facing == Vector2i.RIGHT else -5, -6 + bob, 2, 2), Color("263448"))
	draw_rect(Rect2(-6, 1 + bob, 12, 9), shirt)
	draw_rect(Rect2(-6, 10 + bob, 5, 5), Color("263448"))
	draw_rect(Rect2(1, 10 + bob, 5, 5), Color("263448"))
	if _moving:
		if _walk_phase == 1:
			draw_rect(Rect2(-6 - leg_offset, 13 + bob, 5, 2), Color("172b43"))
			draw_rect(Rect2(1 + leg_offset, 13 + bob, 5, 2), Color("172b43"))
	draw_rect(Rect2(-7, 14 + bob, 14, 2), Color(0.0, 0.0, 0.0, 0.25))
