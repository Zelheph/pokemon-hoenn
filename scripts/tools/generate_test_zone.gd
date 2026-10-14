extends SceneTree

const PLAN_PATH: String = "res://data/test_zone.json"
const TILESET_PATH: String = "res://assets/tilesets/emerald_exterior.tres"
const OUTPUT_PATH: String = "res://scenes/hoenn/test_zone.tscn"
const TILE_SIZE: int = 16

func _initialize() -> void:
	_generate()
	quit()

func _generate() -> void:
	var plan_file: FileAccess = FileAccess.open(PLAN_PATH, FileAccess.READ)
	if plan_file == null:
		push_error("Impossible d'ouvrir le plan JSON : %s" % PLAN_PATH)
		return
	var plan: Dictionary = JSON.parse_string(plan_file.get_as_text()) as Dictionary
	var tile_set: TileSet = load(TILESET_PATH) as TileSet
	if tile_set == null:
		push_error("Impossible de charger le TileSet : %s" % TILESET_PATH)
		return
	var tile_regions: Dictionary = plan["tile_regions"]

	var zone: Node2D = Node2D.new()
	zone.name = "ZoneTest"
	zone.set_script(load("res://scripts/hoenn/TestZone.gd"))
	var layer: TileMapLayer = TileMapLayer.new()
	layer.name = "Terrain"
	layer.tile_set = tile_set
	zone.add_child(layer)
	layer.owner = zone
	var size: Array = plan["size"]
	var rows: Array = plan["terrain"]
	var tile_regions_by_symbol: Dictionary = plan["tile_regions"]
	for y in range(mini(int(size[1]), rows.size())):
		var row: String = str(rows[y])
		for x in range(mini(int(size[0]), row.length())):
			var symbol: String = row.substr(x, 1)
			var tile_id: Array = tile_regions_by_symbol[symbol]
			layer.set_cell(Vector2i(x, y), int(tile_id[0]), Vector2i(int(tile_id[1]), int(tile_id[2])))

	var collision_root: StaticBody2D = StaticBody2D.new()
	collision_root.name = "Obstacles"
	collision_root.collision_layer = 1
	collision_root.collision_mask = 1
	zone.add_child(collision_root)
	collision_root.owner = zone
	for blocked_value: Variant in plan["blocked"]:
		var blocked: Array = blocked_value
		var shape: CollisionShape2D = CollisionShape2D.new()
		shape.position = Vector2((int(blocked[0]) + 0.5) * TILE_SIZE, (int(blocked[1]) + 0.5) * TILE_SIZE)
		var rectangle: RectangleShape2D = RectangleShape2D.new()
		rectangle.size = Vector2(TILE_SIZE, TILE_SIZE)
		shape.shape = rectangle
		collision_root.add_child(shape)
		shape.owner = zone

	var player: CharacterBody2D = CharacterBody2D.new()
	player.name = "Player"
	player.set_script(load("res://scripts/player/Player.gd"))
	player.position = Vector2((int(plan["spawn"][0]) + 0.5) * TILE_SIZE, (int(plan["spawn"][1]) + 0.5) * TILE_SIZE)
	player.collision_layer = 1
	player.collision_mask = 1
	zone.add_child(player)
	var player_shape: CollisionShape2D = CollisionShape2D.new()
	player_shape.name = "CollisionShape2D"
	var body_rectangle: RectangleShape2D = RectangleShape2D.new()
	body_rectangle.size = Vector2(10, 10)
	player_shape.shape = body_rectangle
	player.add_child(player_shape)
	player_shape.owner = zone
	player.owner = zone
	var camera: Camera2D = Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = false
	player.add_child(camera)
	camera.owner = zone
	var sign_post: Node2D = Node2D.new()
	sign_post.name = "PanneauTest"
	sign_post.set_script(load("res://scripts/player/TestSign.gd"))
	sign_post.position = Vector2(15.5 * TILE_SIZE, 12.5 * TILE_SIZE)
	zone.add_child(sign_post)
	sign_post.owner = zone
	var sign_area: Area2D = Area2D.new()
	sign_area.name = "Interaction"
	sign_area.collision_layer = 2
	sign_area.collision_mask = 0
	sign_area.set_meta("dialogue", "Bienvenue à Bourg-en-Vol !")
	sign_post.add_child(sign_area)
	sign_area.owner = zone
	var sign_shape: CollisionShape2D = CollisionShape2D.new()
	var sign_rectangle: RectangleShape2D = RectangleShape2D.new()
	sign_rectangle.size = Vector2(12, 12)
	sign_shape.shape = sign_rectangle
	sign_area.add_child(sign_shape)
	sign_shape.owner = zone

	var hud: CanvasLayer = CanvasLayer.new()
	hud.name = "HUD"
	zone.add_child(hud)
	hud.owner = zone
	var label: Label = Label.new()
	label.name = "Instructions"
	label.position = Vector2(8, 8)
	label.text = "Fleches / WASD : bouger | Maj : courir | E : interagir"
	label.add_theme_font_size_override("font_size", 10)
	hud.add_child(label)
	label.owner = zone
	var dialogue: Label = Label.new()
	dialogue.name = "Dialogue"
	dialogue.position = Vector2(8, 284)
	dialogue.size = Vector2(464, 28)
	dialogue.text = ""
	dialogue.visible = false
	dialogue.add_theme_font_size_override("font_size", 12)
	hud.add_child(dialogue)
	dialogue.owner = zone

	var packed: PackedScene = PackedScene.new()
	var pack_result: int = packed.pack(zone)
	if pack_result != OK:
		push_error("Échec de la création de la scène : %s" % pack_result)
		return
	var save_result: Error = ResourceSaver.save(packed, OUTPUT_PATH)
	if save_result != OK:
		push_error("Échec de l'enregistrement de la scène : %s" % save_result)
	else:
		print("Zone de test générée : %s" % OUTPUT_PATH)
	zone.free()
