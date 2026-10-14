extends Node2D

@export var zone_id: StringName = &""
@export var zone_name: String = "Hoenn"

@onready var dialogue_label: Label = $HUD/Dialogue
@onready var title_label: Label = $HUD/Title

func _ready() -> void:
	title_label.text = zone_name
	var state: Node = get_node("/root/GameState")
	state.set("current_zone_id", zone_id)
	state.connect("interaction_requested", _on_interaction_requested)
	for candidate: Node in get_tree().get_nodes_in_group("zone_transition"):
		if candidate is Area2D:
			var area: Area2D = candidate as Area2D
			if not area.body_entered.is_connected(_on_transition_body_entered.bind(area)):
				area.body_entered.connect(_on_transition_body_entered.bind(area))

func _on_interaction_requested(target: Node) -> void:
	if target.has_meta("dialogue"):
		dialogue_label.text = str(target.get_meta("dialogue"))
		dialogue_label.visible = true

func _on_transition_body_entered(body: Node2D, area: Area2D) -> void:
	if body.name != "Player" or not area.has_meta("target_scene"):
		return
	var scene_path: String = str(area.get_meta("target_scene"))
	if not ResourceLoader.exists(scene_path):
		dialogue_label.text = "Je ne peux pas encore aller là."
		dialogue_label.visible = true
		var retreat: Vector2i = area.get_meta("blocked_retreat", Vector2i.DOWN)
		if body.has_method("block_transition"):
			body.call("block_transition", retreat, area.global_position)
		else:
			body.position += Vector2(retreat) * 16.0
		return
	var manager: Node = get_node("/root/SceneManager")
	manager.call("change_zone", scene_path, area.get_meta("arrival_cell"), area.get_meta("arrival_facing", Vector2i.DOWN))
