extends SceneTree

const WORLD_PATH: String = "res://data/world.json"
const MAPS_PATH: String = "res://data/maps/"
const STAMPS_PATH: String = "res://data/building_stamps.json"
const EXTERIOR_TILESET_PATH: String = "res://assets/tilesets/emerald_exterior.tres"
const INTERIOR_TILESET_PATH: String = "res://assets/tilesets/emerald_interior.tres"
const SCENES_PATH: String = "res://scenes/hoenn/"
const BLOCKED: Array[String] = ["T", "R", "B", "H", "W", "w"]
const TILE_SIZE: int = 16
var _edges: Array = []
var _nodes: Dictionary = {}
var _plans: Dictionary = {}
var _stamps: Dictionary = {}
var _characters: Dictionary = {}
var _selected_zones: Array[String] = []

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--zones="):
			for zone_id: String in argument.trim_prefix("--zones=").split(","):
				if not zone_id.is_empty(): _selected_zones.append(zone_id)
	_generate_all()
	quit()

func _generate_all() -> void:
	var file: FileAccess = FileAccess.open(WORLD_PATH, FileAccess.READ)
	if file == null:
		push_error("Graphe de Hoenn introuvable.")
		return
	var manifest: Dictionary = JSON.parse_string(file.get_as_text()) as Dictionary
	_edges = manifest["edges"]
	var stamps_file := FileAccess.open(STAMPS_PATH, FileAccess.READ)
	if stamps_file == null:
		push_error("Catalogue de stamps introuvable : " + STAMPS_PATH)
		return
	var stamps_data: Dictionary = JSON.parse_string(stamps_file.get_as_text()) as Dictionary
	var characters_file := FileAccess.open("res://data/characters.json", FileAccess.READ)
	if characters_file != null:
		var characters_data: Dictionary = JSON.parse_string(characters_file.get_as_text()) as Dictionary
		for character_value: Variant in characters_data.get("characters", []):
			var character: Dictionary = character_value
			_characters[str(character["id"])] = character
	for stamp_value: Variant in stamps_data["stamps"]:
		var stamp: Dictionary = stamp_value
		_stamps[str(stamp["id"])] = stamp
	for node_value: Variant in manifest["nodes"]:
		var node_data: Dictionary = node_value
		_nodes[str(node_data["id"])] = node_data

	for node_data: Dictionary in _nodes.values():
		var plan_file: FileAccess = FileAccess.open(MAPS_PATH + str(node_data["id"]) + ".json", FileAccess.READ)
		if plan_file == null:
			push_error("Plan absent : %s" % node_data["id"])
			continue
		var plan: Dictionary = JSON.parse_string(plan_file.get_as_text()) as Dictionary
		_plans[str(node_data["id"])] = plan
	for node_data: Dictionary in _nodes.values():
		var node_id := str(node_data["id"])
		if _plans.has(node_id) and (_selected_zones.is_empty() or _selected_zones.has(node_id)):
			_build_zone(node_data, _plans[node_id])
	print("Génération terminée : %d zones demandées sur %d, %d liaisons dans le graphe." % [(_nodes.size() if _selected_zones.is_empty() else _selected_zones.size()), _nodes.size(), _edges.size()])

func _build_zone(data: Dictionary, plan: Dictionary) -> void:
	var size: Array = plan["size"]
	var width: int = int(size[0])
	var height: int = int(size[1])
	var root: Node2D = Node2D.new()
	root.name = str(data["id"])
	root.set_script(load("res://scripts/hoenn/MapZone.gd"))
	root.set("zone_id", StringName(str(data["id"])))
	root.set("zone_name", str(data["name"]))
	if str(data["kind"]) == "interior":
		var backdrop: Polygon2D = Polygon2D.new()
		backdrop.name = "InteriorBlackBackground"
		var padding := Vector2(128.0, 128.0)
		backdrop.polygon = PackedVector2Array([
			Vector2(-padding.x, -padding.y),
			Vector2(width * TILE_SIZE + padding.x, -padding.y),
			Vector2(width * TILE_SIZE + padding.x, height * TILE_SIZE + padding.y),
			Vector2(-padding.x, height * TILE_SIZE + padding.y)
		])
		backdrop.color = Color.BLACK
		backdrop.z_index = -100
		root.add_child(backdrop)
		backdrop.owner = root

	var layer: TileMapLayer = TileMapLayer.new()
	layer.name = "Terrain"
	var tileset_path: String = INTERIOR_TILESET_PATH if str(plan["tileset"]) == "interior" else EXTERIOR_TILESET_PATH
	layer.tile_set = load(tileset_path) as TileSet
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
			var tile_id: Array = plan["tiles"].get(symbol, [])
			if tile_id.size() == 3:
				layer.set_cell(Vector2i(x,y), int(tile_id[0]), Vector2i(int(tile_id[1]), int(tile_id[2])))
			if BLOCKED.has(symbol): _add_blocker(blockers, root, Vector2i(x,y))
			if symbol == "X" or symbol == "x": _add_encounter_area(root, Vector2i(x,y))
	_add_building_stamps(layer, blockers, root, plan)
	_add_furniture(layer, blockers, root, plan)

	if plan.has("sign"):
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
	if plan.has("spawn"):
		var spawn: Array = plan["spawn"]
		start = Vector2i(int(spawn[0]), int(spawn[1]))
	elif str(data["kind"]) == "town": start.y += 3
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
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = width * TILE_SIZE
	camera.limit_bottom = height * TILE_SIZE
	var fit_zoom: float = 1.0
	if str(data["kind"]) == "interior":
		fit_zoom = maxf(1.0, floorf(minf(480.0 / float(width * TILE_SIZE), 320.0 / float(height * TILE_SIZE))))
	camera.zoom = Vector2(fit_zoom, fit_zoom)
	if str(data["kind"]) == "interior":
		camera.position = Vector2(width * TILE_SIZE / 2.0, height * TILE_SIZE / 2.0)
		root.add_child(camera)
	else:
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

func _add_building_stamps(layer: TileMapLayer, blockers: StaticBody2D, root: Node2D, plan: Dictionary) -> void:
	for building_value: Variant in plan.get("buildings", []):
		var building: Dictionary = building_value
		var stamp_id := str(building["stamp"])
		if not _stamps.has(stamp_id):
			push_error("Stamp inconnu : " + stamp_id)
			continue
		var stamp: Dictionary = _stamps[stamp_id]
		var position_data: Array = building["position"]
		var origin := Vector2i(int(position_data[0]), int(position_data[1]))
		var source_id := 10 + int(stamp["band"]) - 1
		for tile_value: Variant in stamp["tiles"]:
			var tile: Dictionary = tile_value
			var offset_data: Array = tile["offset"]
			var atlas_data: Array = tile["atlas"]
			var offset := Vector2i(int(offset_data[0]), int(offset_data[1]))
			var atlas_cell := Vector2i(int(atlas_data[0]), int(atlas_data[1]))
			var tile_source_id := 30 if str(stamp.get("roof_variant", "")) == "band_01_rival_roof" and str(tile["role"]) == "roof" else source_id
			layer.set_cell(origin + offset, tile_source_id, atlas_cell)
		for solid_value: Variant in stamp["solid_cells"]:
			var solid_data: Array = solid_value
			_add_blocker(blockers, root, origin + Vector2i(int(solid_data[0]), int(solid_data[1])))

func _add_furniture(layer: TileMapLayer, blockers: StaticBody2D, root: Node2D, plan: Dictionary) -> void:
	for furniture_value: Variant in plan.get("furniture", []):
		var furniture: Dictionary = furniture_value
		var cell_data: Array = furniture.get("cell", [])
		var atlas_data: Array = furniture.get("atlas", [])
		if cell_data.size() != 2 or atlas_data.size() != 2:
			push_error("Meuble invalide dans le plan %s." % plan.get("id", "?"))
			continue
		var cell := Vector2i(int(cell_data[0]), int(cell_data[1]))
		var atlas_cell := Vector2i(int(atlas_data[0]), int(atlas_data[1]))
		layer.set_cell(cell, 0, atlas_cell)
		if bool(furniture.get("solid", true)):
			_add_blocker(blockers, root, cell)

func _add_encounter_area(root: Node2D, cell: Vector2i) -> void:
	var area: Area2D = Area2D.new()
	area.name = "TallGrass_%02d_%02d" % [cell.x, cell.y]
	area.position = _cell_center(cell)
	area.collision_layer = 0
	area.collision_mask = 1
	area.add_to_group("tall_grass_encounter", true)
	area.set_meta("encounter_trigger", true)
	area.set_meta("encounter_stage", 8)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	collision.shape = shape
	area.add_child(collision)
	root.add_child(area)
	area.owner = root
	collision.owner = root

func _add_actor(root: Node2D, actor_data: Dictionary, kind: String) -> void:
	var actor: Node2D = Node2D.new()
	var actor_name: String = str(actor_data.get("name", kind.capitalize()))
	var dialogue: String = str(actor_data.get("dialogue", ""))
	if kind == "npc":
		var character_id := str(actor_data.get("character_id", ""))
		if not _characters.has(character_id):
			push_error("Fiche de personnage absente : " + character_id)
		else:
			var character: Dictionary = _characters[character_id]
			actor_name = str(character["name"])
			dialogue = "%s : %s" % [actor_name, str(character["dialogue"])]
	actor.name = ("Sign_" if kind == "sign" else "NPC_" if kind == "npc" else "Item_") + actor_name.validate_node_name()
	actor.set_script(load("res://scripts/player/WorldActor.gd"))
	actor.set("actor_kind", kind)
	if kind == "npc" and _characters.has(str(actor_data.get("character_id", ""))):
		var character: Dictionary = _characters[str(actor_data["character_id"])]
		actor.set("actor_color", Color(str(character.get("color", "#e9c659"))))
	var cell: Array = actor_data["cell"]
	actor.position = _cell_center(Vector2i(int(cell[0]),int(cell[1])))
	root.add_child(actor)
	actor.owner = root
	var sensor: Area2D = Area2D.new()
	sensor.name = "Interaction"
	sensor.collision_layer = 2
	sensor.collision_mask = 0
	sensor.add_to_group("interactable", true)
	sensor.set_meta("dialogue", dialogue)
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
	var width: int = int(plan["size"][0])
	var height: int = int(plan["size"][1])
	var area: Area2D = Area2D.new()
	area.name = "Transition_" + target_id
	var area_size := Vector2(14,14)
	var area_offset := Vector2.ZERO
	if str(edge["kind"]) == "door":
		var building: Dictionary = _building_for_interior(plan, target_id)
		if not building.is_empty():
			var stamp: Dictionary = _stamps[str(building["stamp"])]
			var door: Dictionary = stamp["door"]
			var size_data: Array = door.get("area_size", [14,14])
			var offset_data: Array = door.get("area_offset_px", [0,0])
			area_size = Vector2(float(size_data[0]), float(size_data[1]))
			area_offset = Vector2(float(offset_data[0]), float(offset_data[1]))
		elif plan.get("portals", {}).has(target_id):
			var portal: Dictionary = plan["portals"][target_id]
			var portal_size_data: Array = portal.get("area_size", [14,14])
			area_size = Vector2(float(portal_size_data[0]), float(portal_size_data[1]))
	elif plan.get("portals", {}).has(target_id):
		var portal: Dictionary = plan["portals"][target_id]
		var size_data: Array = portal.get("area_size", [14,14])
		area_size = Vector2(float(size_data[0]), float(size_data[1]))
	area.position = _cell_center(here) + area_offset
	var arrival_facing: Vector2i = _arrival_facing(plan, target_id, str(edge["kind"]))
	area.set_meta("arrival_facing", arrival_facing)
	area.set_meta("blocked_retreat", _inward_direction(here, width, height))
	area.collision_layer = 0
	area.collision_mask = 1
	area.add_to_group("zone_transition", true)
	area.set_meta("target_scene", SCENES_PATH + target_id + ".tscn")
	area.set_meta("arrival_cell", arrival)
	area.set_meta("transition_kind", str(edge["kind"]))
	root.add_child(area)
	area.owner = root
	var collision: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = area_size
	collision.shape = rect
	area.add_child(collision)
	collision.owner = root

func _portal_cell(node_id: String, neighbor_id: String, edge: Dictionary, plan: Dictionary) -> Vector2i:
	var node_data: Dictionary = _nodes[node_id]
	var width: int = int(plan["size"][0]); var height: int = int(plan["size"][1])
	var portals: Dictionary = plan.get("portals", {})
	if portals.has(neighbor_id):
		var portal: Dictionary = portals[neighbor_id]
		var portal_cell: Array = portal["cell"]
		return Vector2i(int(portal_cell[0]), int(portal_cell[1]))
	if str(edge["kind"]) == "door":
		var building: Dictionary = _building_for_interior(plan, neighbor_id)
		if not building.is_empty():
			var stamp: Dictionary = _stamps[str(building["stamp"])]
			var position_data: Array = building["position"]
			var door_data: Array = stamp["door"]["position"]
			return Vector2i(int(position_data[0]) + int(door_data[0]), int(position_data[1]) + int(door_data[1]))
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
	if str(edge["kind"]) == "door" and str(target["kind"]) == "town" and _plans.has(target_id):
		var target_plan: Dictionary = _plans[target_id]
		var building: Dictionary = _building_for_interior(target_plan, source_id)
		if not building.is_empty():
			var stamp: Dictionary = _stamps[str(building["stamp"])]
			var origin_data: Array = building["position"]
			var approach_data: Array = stamp["door"]["approach"]
			return Vector2i(int(origin_data[0]) + int(approach_data[0]), int(origin_data[1]) + int(approach_data[1]))
	if str(edge["kind"]) == "door" and str(target["kind"]) != "town":
		if _plans.has(target_id):
			var room_plan: Dictionary = _plans[target_id]
			if room_plan.has("spawn"):
				var room_spawn: Array = room_plan["spawn"]
				return Vector2i(int(room_spawn[0]), int(room_spawn[1]))
		return Vector2i(width/2,height-3)
	if _plans.has(source_id):
		var source_plan: Dictionary = _plans[source_id]
		var source_portals: Dictionary = source_plan.get("portals", {})
		if source_portals.has(target_id):
			var source_portal: Dictionary = source_portals[target_id]
			if source_portal.has("arrival_cell"):
				var arrival_data: Array = source_portal["arrival_cell"]
				return Vector2i(int(arrival_data[0]), int(arrival_data[1]))
	if _plans.has(target_id):
		var target_plan: Dictionary = _plans[target_id]
		var target_portals: Dictionary = target_plan.get("portals", {})
		if target_portals.has(source_id):
			var reciprocal_portal: Dictionary = target_portals[source_id]
			if reciprocal_portal.has("cell"):
				var arrival_data: Array = reciprocal_portal["cell"]
				return Vector2i(int(arrival_data[0]), int(arrival_data[1]))
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

func _building_for_interior(plan: Dictionary, interior_id: String) -> Dictionary:
	for building_value: Variant in plan.get("buildings", []):
		var building: Dictionary = building_value
		if str(building.get("interior_id", "")) == interior_id:
			return building
	return {}

func _arrival_facing(plan: Dictionary, target_id: String, edge_kind: String) -> Vector2i:
	var portals: Dictionary = plan.get("portals", {})
	if portals.has(target_id):
		var portal: Dictionary = portals[target_id]
		match str(portal.get("arrival_facing", "down")):
			"up": return Vector2i.UP
			"down": return Vector2i.DOWN
			"left": return Vector2i.LEFT
			"right": return Vector2i.RIGHT
	return Vector2i.DOWN if edge_kind == "door" else Vector2i.UP

func _inward_direction(cell: Vector2i, width: int, height: int) -> Vector2i:
	if cell.x == 0: return Vector2i.RIGHT
	if cell.x == width - 1: return Vector2i.LEFT
	if cell.y == 0: return Vector2i.DOWN
	if cell.y == height - 1: return Vector2i.UP
	return Vector2i.DOWN

func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2((cell.x+0.5)*TILE_SIZE,(cell.y+0.5)*TILE_SIZE)
