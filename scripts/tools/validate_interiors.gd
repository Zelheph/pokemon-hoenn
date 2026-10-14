extends SceneTree

const ROOM_IDS: Array[String] = [
	"bourg_en_vol_interieur_01",
	"bourg_en_vol_interieur_02",
	"bourg_en_vol_interieur_03"
]
const TILE: int = 16
const BLOCKED: Array[String] = ["T", "R", "B", "H", "W", "w"]
var _errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_validate")

func _validate() -> void:
	var characters_data: Dictionary = _read_json("res://data/characters.json")
	var character_ids: Dictionary = {}
	for character_value: Variant in characters_data.get("characters", []):
		var character: Dictionary = character_value
		character_ids[str(character.get("id", ""))] = character
	for room_id: String in ROOM_IDS:
		var plan: Dictionary = _read_json("res://data/maps/%s.json" % room_id)
		var packed: PackedScene = load("res://scenes/hoenn/%s.tscn" % room_id) as PackedScene
		if plan.is_empty() or packed == null:
			_errors.append("Plan ou scène absente : %s" % room_id)
			continue
		if plan.has("sign") or not plan.get("items", []).is_empty():
			_errors.append("%s : objet ou panneau de test encore présent" % room_id)
		for npc_value: Variant in plan.get("npcs", []):
			var npc: Dictionary = npc_value
			var character_id := str(npc.get("character_id", ""))
			if not character_ids.has(character_id):
				_errors.append("%s : fiche de nom/dialogue absente pour %s" % [room_id, character_id])
		var scene: Node2D = packed.instantiate() as Node2D
		root.add_child(scene)
		await physics_frame
		_validate_room(scene, plan, room_id)
		scene.queue_free()
		await process_frame
	var route: Dictionary = _read_json("res://data/maps/route_101.json")
	var route_sign: Dictionary = route.get("sign", {})
	var sign_cell: Array = route_sign.get("cell", [])
	var south_row: int = int(route.get("size", [0, 0])[1]) - 3
	if sign_cell.size() != 2 or int(sign_cell[0]) != 13 or int(sign_cell[1]) != south_row or str(route_sign.get("dialogue", "")).find("Route 101") < 0:
		_errors.append("Route 101 : le panneau doit nommer la route à son entrée sud")
	if not route.get("npcs", []).is_empty() or not route.get("items", []).is_empty():
		_errors.append("Route 101 : acteur ou objet de test encore présent")
	var grass_cells := 0
	for row_value: Variant in route.get("terrain", []):
		grass_cells += str(row_value).count("X") + str(row_value).count("x")
	if grass_cells < 20:
		_errors.append("Route 101 : hautes herbes latérales manquantes")
	if _errors.is_empty():
		print("Intérieurs validés : collisions des meubles et PNJ bloquantes, meubles sans chevauchement, tous les points d'intérêt accessibles dans les trois pièces.")
	else:
		for error: String in _errors: push_error(error)
	quit(0 if _errors.is_empty() else 1)

func _validate_room(scene: Node2D, plan: Dictionary, room_id: String) -> void:
	var size: Array = plan["size"]
	var width: int = int(size[0]); var height: int = int(size[1])
	var rows: Array = plan["terrain"]
	var occupied: Dictionary = {}
	var interest_groups: Dictionary = {}
	var space: PhysicsDirectSpaceState2D = scene.get_world_2d().direct_space_state
	for furniture_value: Variant in plan.get("furniture", []):
		var furniture: Dictionary = furniture_value
		var cell: Vector2i = _cell(furniture["cell"])
		if occupied.has(cell): _errors.append("%s : chevauchement de meubles en %s" % [room_id, cell])
		occupied[cell] = true
		var role := str(furniture.get("role", ""))
		if role != "fenêtre":
			if role.begins_with("étagère") or role.begins_with("bibliothèque"):
				role = "bibliothèque"
			if not interest_groups.has(role): interest_groups[role] = []
			interest_groups[role].append(cell)
		var query := PhysicsPointQueryParameters2D.new()
		query.position = _center(cell); query.collision_mask = 1; query.collide_with_areas = false
		if space.intersect_point(query, 8).is_empty():
			_errors.append("%s : meuble traversable sans collision en %s" % [room_id, cell])
	for npc_value: Variant in plan.get("npcs", []):
		var npc: Dictionary = npc_value
		var cell: Vector2i = _cell(npc["cell"])
		if occupied.has(cell): _errors.append("%s : PNJ superposé à un meuble en %s" % [room_id, cell])
		occupied[cell] = true
		interest_groups[str(npc.get("character_id", "PNJ"))] = [cell]
		var query := PhysicsPointQueryParameters2D.new()
		query.position = _center(cell); query.collision_mask = 1; query.collide_with_areas = false
		if space.intersect_point(query, 8).is_empty():
			_errors.append("%s : corps collision du PNJ absent en %s" % [room_id, cell])
	var spawn: Vector2i = _cell(plan["spawn"])
	var reached: Dictionary = {spawn: true}
	var queue: Array[Vector2i] = [spawn]
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		for direction: Vector2i in directions:
			var next: Vector2i = at + direction
			if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height: continue
			if rows[next.y].substr(next.x, 1) in BLOCKED or occupied.has(next) or reached.has(next): continue
			reached[next] = true; queue.append(next)
	for role: String in interest_groups:
		var accessible := false
		var collision_stopped := false
		for target_value: Variant in interest_groups[role]:
			var target: Vector2i = target_value
			for direction: Vector2i in directions:
				var approach: Vector2i = target + direction
				if not reached.has(approach): continue
				accessible = true
				var movement := PhysicsShapeQueryParameters2D.new()
				var player_shape := RectangleShape2D.new()
				player_shape.size = Vector2(10, 10)
				movement.shape = player_shape
				movement.transform = Transform2D(0.0, _center(approach))
				movement.motion = Vector2(-direction) * TILE
				movement.collision_mask = 1
				var cast: PackedFloat32Array = space.cast_motion(movement)
				if not cast.is_empty() and cast[0] < 0.95:
					collision_stopped = true
		if not accessible: _errors.append("%s : point d'intérêt %s inaccessible" % [room_id, role])
		elif not collision_stopped: _errors.append("%s : déplacement simulé à travers %s sans collision" % [room_id, role])

func _read_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text()) as Dictionary if file != null else {}

func _cell(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

func _center(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * TILE, (cell.y + 0.5) * TILE)
