extends Node2D

@onready var dialogue_label: Label = $HUD/Dialogue

func _ready() -> void:
	get_node("/root/GameState").connect("interaction_requested", _on_interaction_requested)

func _on_interaction_requested(target: Node) -> void:
	if target.has_meta("dialogue"):
		dialogue_label.text = str(target.get_meta("dialogue"))
		dialogue_label.visible = true
