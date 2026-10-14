extends Node2D

@export var actor_kind: String = "npc"
@export var actor_color: Color = Color("e9c659")

func _draw() -> void:
	match actor_kind:
		"npc":
			draw_rect(Rect2(-5, -8, 10, 8), Color("f1c59a"))
			draw_rect(Rect2(-5, -9, 10, 3), Color("473747"))
			draw_rect(Rect2(-6, 0, 12, 9), actor_color)
			draw_rect(Rect2(-5, 9, 4, 5), Color("394056"))
			draw_rect(Rect2(1, 9, 4, 5), Color("394056"))
		"sign":
			draw_rect(Rect2(-2, -4, 4, 12), Color("755237"))
			draw_rect(Rect2(-7, -11, 14, 8), Color("f0d48a"))
			draw_rect(Rect2(-5, -9, 10, 4), Color("855d35"))
		"item":
			draw_rect(Rect2(-4, -4, 8, 8), actor_color)
			draw_rect(Rect2(-2, -6, 4, 12), Color("fff1b3"))
			draw_rect(Rect2(-6, -2, 12, 4), Color("fff1b3"))
