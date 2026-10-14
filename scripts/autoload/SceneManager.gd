extends Node

signal transition_finished

const FADE_SECONDS: float = 0.22
const TILE_SIZE: float = 16.0

var _overlay: ColorRect
var _changing_zone: bool = false
var _pending_spawn: Vector2 = Vector2.INF
var _pending_facing: Vector2i = Vector2i.DOWN

func _ready() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "ZoneFade"
	canvas.layer = 100
	add_child(canvas)
	_overlay = ColorRect.new()
	_overlay.name = "Black"
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.position = Vector2.ZERO
	_overlay.size = Vector2(480, 320)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_overlay)

func change_zone(scene_path: String, arrival_cell: Vector2i, arrival_facing: Vector2i = Vector2i.DOWN) -> void:
	if _changing_zone or not ResourceLoader.exists(scene_path):
		return
	_changing_zone = true
	_pending_spawn = Vector2((arrival_cell.x + 0.5) * TILE_SIZE, (arrival_cell.y + 0.5) * TILE_SIZE)
	_pending_facing = arrival_facing
	_overlay.visible = true
	var fade_out: Tween = create_tween()
	fade_out.tween_property(_overlay, "color:a", 1.0, FADE_SECONDS)
	await fade_out.finished
	var change_error: Error = get_tree().change_scene_to_file(scene_path)
	if change_error != OK:
		push_error("Impossible de charger la zone %s" % scene_path)
		_changing_zone = false
		_pending_spawn = Vector2.INF
		return
	await get_tree().process_frame
	var fade_in: Tween = create_tween()
	fade_in.tween_property(_overlay, "color:a", 0.0, FADE_SECONDS)
	await fade_in.finished
	_overlay.visible = false
	_changing_zone = false
	transition_finished.emit()

func consume_spawn_position() -> Vector2:
	var result: Vector2 = _pending_spawn
	_pending_spawn = Vector2.INF
	return result

func consume_spawn_facing() -> Vector2i:
	var result: Vector2i = _pending_facing
	_pending_facing = Vector2i.DOWN
	return result

func is_changing_zone() -> bool:
	return _changing_zone
