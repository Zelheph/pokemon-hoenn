extends Node

signal interaction_requested(world_position: Vector2)

var player_position: Vector2 = Vector2.ZERO

var current_zone_id: StringName = &""
