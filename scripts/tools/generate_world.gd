extends SceneTree

const WORLD_PATH: String = "res://data/world.json"
const MAPS_PATH: String = "res://data/maps/"
const TERRAIN_PATH: String = "res://assets/tilesets/placeholder_hoenn_terrain.svg"
const SCENES_PATH: String = "res://scenes/hoenn/"
const BLOCKED: Array[String] = ["T", "R", "B", "H", "W", "w"]
const TILE_SIZE: int = 16
const TILE_COORDS: Dictionary = {
	"G": Vector2i(0,0), "g": Vector2i(1,0), "P": Vector2i(2,0), "p": Vector2i(3,0),
	"W": Vector2i(4,0), "w": Vector2i(5,0), "T": Vector2i(6,0), "F": Vector2i(7,0),
	"R": Vector2i(0,1), "D": Vector2i(1,1), "C": Vector2i(2,1), "I": Vector2i(3,1),
	"B": Vector2i(4,1), "H": Vector2i(5,1), "S": Vector2i(6,1), "M": Vector2i(7,1)
}

var _edges: Array = []
var _nodes: Dictionary = {}
var _tile_set: TileSet

func _initialize() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	var file: FileAccess = FileAccess.open(WORLD_PATH, FileAccess.READ)
	if file == null:
		push_error("Graphe de Hoenn introuvable.")
		return
	var manifest: Dictionary = JSON.parse_string(file.get_as_text()) as Dictionary
	_edges = manifest["edges"]
	for node_value: Variant in manifest["nodes"]:
		var node_data: Dictionary = node_value
		_nodes[str(node_data["id"])] = node_data
	var texture: Texture2D = load(TERRAIN_PATH) as Texture2D
	if texture == null:
		push_error("Atlas de terrain introuvable.")
		return
	_tile_set = _make_tile_set(texture)
	for node_data: Dictionary in _nodes.values():
		var plan_file: FileAccess = FileAccess.open(MAPS_PATH + str(node_data["id"]) + ".json", FileAccess.READ)
		if plan_file == null:
			push_error("Plan absent : %s" % node_data["id"])
			continue
		_build_zone(node_data, JSON.parse_string(plan_file.get_as_text()) as Dictionary)
	print("Génération terminée : %d zones et %d liaisons." % [_nodes.size(), _edges.size()])

func _make_tile_set(texture: Texture2D) -> TileSet:
	var result: TileSet = TileSet.new()
	result.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for y in range(2):
		for x in range(8): atlas.create_tile(Vector2i(x,y))
	result.add_source(atlas, 0)
	return result

func _build_zone(data: Dictionary, plan: Dictionary) -> void:
	var size: Array = plan["size"]
	var width: int = int(size[0])
	var height: int = int(size[1])
	var root: Node2D = Node2D.new()
	root.name = str(data["id"])
	root.set_script(load("res://scripts/hoenn/MapZone.gd"))
	root.set("zone_id", StringName(str(data["id"])))
	root.set("zone_name", str(data["name"]))

	var layer: TileMapLayer = TileMapLayer.new()
	layer.name = "Terrain"
	layer.tile_set = _tile_set
	root.add_child(layer)
	layer.owner = root
	var rows: Array = plan["terrain"]
	var blockers: StaticBody2D = StaticBody2D.new()
	blockers.name = "TerrainCollisions"
	blockers.collision_layer = 1
	blockers.collision_mask = 1
	root.add_child(blockers)
	blockers.owner = root
	for y in range(mini(height, rows.size())):
		var row: String = str(rows[y])
		for x in range(mini(width, row.length())):
			var symbol: String = row.substr(x,1)
			if TILE_COORDS.has(symbol):
				layer.set_cell(Vector2i(x,y), 0, TILE_COORDS[symbol])
			if BLOCKED.has(symbol): _add_blocker(blockers, root, Vector2i(x,y))

	_add_actor(root, plan["sign"], "sign")
	for value: Variant in plan["npcs"]: _add_actor(root, value, "npc")
	for value: Variant in plan["items"]: _add_actor(root, value, "item")
	for edge_value: Variant in _edges:
		var edge: Dictionary = edge_value
		var a_id: String = str(edge["a"])
		var b_id: String = str(edge["b"])
		if a_id == str(data["id"]): _add_transition(root, data, plan, b_id, edge, true)
		elif b_id == str(data["id"]): _add_transition(root, data, plan, a_id, edge, false)

	var player: CharacterBody2D = CharacterBody2D.new()
	player.name = "Player"
	player.set_script(load("res://scripts/player/Player.gd"))
	player.collision_layer = 1
	player.collision_mask = 1
	var start: Vector2i = Vector2i(width / 2, height / 2)
	if str(data["kind"]) == "town": start.y += 3
	player.position = _cell_center(start)
	root.add_child(player)
	var player_collision: CollisionShape2D = CollisionShape2D.new()
	player_collision.name = "CollisionShape2D"
	var player_shape: RectangleShape2D = RectangleShape2D.new()
	player_shape.size = Vector2(10,10)
	player_collision.shape = player_shape
	player.add_child(player_collision)
	player_collision.owner = root
	player.owner = root
	var camera: Camera2D = Camera2D.new()
	camera.name = "Camera2D"
	player.add_child(camera)
	camera.owner = root

	var hud: CanvasLayer = CanvasLayer.new()
	hud.name = "HUD"
	root.add_child(hud)
	hud.owner = root
	var title: Label = Label.new()
	title.name = "Title"
	title.position = Vector2(8,5)
	title.text = str(data["name"])
	title.add_theme_font_size_override("font_size",12)
	hud.add_child(title)
	title.owner = root
	var controls: Label = Label.new()
	controls.name = "Controls"
	controls.position = Vector2(8,21)
	controls.text = "Flèches / WASD · Maj courir · E interagir"
	controls.add_theme_font_size_override("font_size",9)
	hud.add_child(controls)
	controls.owner = root
	var dialogue: Label = Label.new()
	dialogue.name = "Dialogue"
	dialogue.position = Vector2(8,286)
	dialogue.size = Vector2(464,26)
	dialogue.visible = false
	dialogue.add_theme_font_size_override("font_size",11)
	hud.add_child(dialogue)
	dialogue.owner = root

	var packed: PackedScene = PackedScene.new()
	if packed.pack(root) != OK:
		push_error("Échec de la sérialisation de %s" % data["id"])
		root.free()
		return
	var save_error: Error = ResourceSaver.save(packed, SCENES_PATH + str(data["id"]) + ".tscn")
	if save_error != OK: push_error("Échec de l'enregistrement de %s" % data["id"])
	root.free()

func _add_blocker(parent: Node, scene_root: Node, cell: Vector2i) -> void:
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	shape_node.position = _cell_center(cell)
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(TILE_SIZE,TILE_SIZE)
	shape_node.shape = rect
	parent.add_child(shape_node)
	shape_node.owner = scene_root

func _add_actor(root: Node2D, actor_data: Dictionary, kind: String) -> void:
	var actor: Node2D = Node2D.new()
	var actor_name: String = str(actor_data.get("name", kind.capitalize()))
	actor.name = ("Sign_" if kind == "sign" else "NPC_" if kind == "npc" else "Item_") + actor_name.validate_node_name()
	actor.set_script(load("res://scripts/player/WorldActor.gd"))
	actor.set("actor_kind", kind)
	var cell: Array = actor_data["cell"]
	actor.position = _cell_center(Vector2i(int(cell[0]),int(cell[1])))
	root.add_child(actor)
	actor.owner = root
	var sensor: Area2D = Area2D.new()
	sensor.name = "Interaction"
	sensor.collision_layer = 2
	sensor.collision_mask = 0
	sensor.add_to_group("interactable")
	sensor.set_meta("dialogue", str(actor_data.get("dialogue", "")))
	actor.add_child(sensor)
	sensor.owner = root
	var sensor_collision: CollisionShape2D = CollisionShape2D.new()
	var sensor_rect: RectangleShape2D = RectangleShape2D.new()
	sensor_rect.size = Vector2(14,14)
	sensor_collision.shape = sensor_rect
	sensor.add_child(sensor_collision)
	sensor_collision.owner = root
	if kind == "npc":
		var body: StaticBody2D = StaticBody2D.new()
		body.name = "BlockingBody"
		body.collision_layer = 1
		body.collision_mask = 1
		actor.add_child(body)
		body.owner = root
		var body_collision: CollisionShape2D = CollisionShape2D.new()
		var body_rect: RectangleShape2D = RectangleShape2D.new()
		body_rect.size = Vector2(10,10)
		body_collision.shape = body_rect
		body.add_child(body_collision)
		body_collision.owner = root

func _add_transition(root: Node2D, data: Dictionary, plan: Dictionary, target_id: String, edge: Dictionary, is_a: bool) -> void:
	var here: Vector2i = _portal_cell(str(data["id"]), target_id, edge, plan)
	var arrival: Vector2i = _arrival_cell(target_id, str(data["id"]), edge)
	var area: Area2D = Area2D.new()
	area.name = "Transition_" + target_id
	area.position = _cell_center(here)
	area.collision_layer = 0
	area.collision_mask = 1
	area.add_to_group("zone_transition")
	area.set_meta("target_scene", SCENES_PATH + target_id + ".tscn")
	area.set_meta("arrival_cell", arrival)
	area.set_meta("transition_kind", str(edge["kind"]))
	root.add_child(area)
	area.owner = root
	var collision: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(14,14)
	collision.shape = rect
	area.add_child(collision)
	collision.owner = root

func _portal_cell(node_id: String, neighbor_id: String, edge: Dictionary, plan: Dictionary) -> Vector2i:
	var node_data: Dictionary = _nodes[node_id]
	var width: int = int(plan["size"][0]); var height: int = int(plan["size"][1])
	if str(edge["kind"]) == "door":
		if str(node_data["kind"]) != "town": return Vector2i(width/2,height-2)
		var door_index: int = 0
		for value: Variant in _edges:
			var candidate: Dictionary = value
			if str(candidate["a"]) == node_id and str(candidate["kind"]) == "door":
				if str(candidate["b"]) == neighbor_id: break
				door_index += 1
		var bx: int = 3 + (door_index % 3) * 8
		var by: int = 3 + (door_index / 3) * 7
		return Vector2i(bx+2,by+3)
	var port_index: int = _neighbor_index(node_id,neighbor_id)
	var side: int = port_index % 4
	var lane: int = int(port_index / 4) * 2
	match side:
		0: return Vector2i(clampi(width/2+lane,1,width-2),1)
		1: return Vector2i(width-2,clampi(height/2+lane,1,height-2))
		2: return Vector2i(clampi(width/2-lane,1,width-2),height-2)
		_: return Vector2i(1,clampi(height/2-lane,1,height-2))

func _arrival_cell(target_id: String, source_id: String, edge: Dictionary) -> Vector2i:
	var target: Dictionary = _nodes[target_id]
	var width: int = int(target["size"][0]); var height: int = int(target["size"][1])
	if str(edge["kind"]) == "door":
		if str(target["kind"]) != "town": return Vector2i(width/2,height-3)
		var door_index: int = 0
		for value: Variant in _edges:
			var candidate: Dictionary = value
			if str(candidate["a"]) == target_id and str(candidate["kind"]) == "door":
				if str(candidate["b"]) == source_id: break
				door_index += 1
		var bx: int = 3 + (door_index % 3) * 8
		var by: int = 3 + (door_index / 3) * 7
		return Vector2i(bx+2,by+4)
	var index: int = _neighbor_index(target_id,source_id)
	var side: int = index % 4
	var lane: int = int(index / 4) * 2
	match side:
		0: return Vector2i(clampi(width/2+lane,1,width-2),2)
		1: return Vector2i(width-3,clampi(height/2+lane,1,height-2))
		2: return Vector2i(clampi(width/2-lane,1,width-2),height-3)
		_: return Vector2i(2,clampi(height/2-lane,1,height-2))

func _neighbor_index(node_id: String, neighbor_id: String) -> int:
	var neighbors: Array[String] = []
	for value: Variant in _edges:
		var edge: Dictionary = value
		if str(edge["kind"]) == "door": continue
		if str(edge["a"]) == node_id: neighbors.append(str(edge["b"]))
		elif str(edge["b"]) == node_id: neighbors.append(str(edge["a"]))
	neighbors.sort()
	return maxi(0, neighbors.find(neighbor_id))

func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2((cell.x+0.5)*TILE_SIZE,(cell.y+0.5)*TILE_SIZE)
