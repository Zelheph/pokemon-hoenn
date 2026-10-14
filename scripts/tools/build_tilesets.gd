extends SceneTree

const TILE_SIZE := 16

func _initialize() -> void:
	var exterior_ok := _build_tileset(
		"res://assets/tilesets/emerald_exterior_tileset.png",
		"res://assets/tilesets/emerald_exterior.tres",
		Vector2i(88, 69),
		[Vector2i(87,14), Vector2i(87,13), Vector2i(84,22), Vector2i(83,22), Vector2i(28,56), Vector2i(28,58), Vector2i(5,4), Vector2i(5,0), Vector2i(61,40), Vector2i(26,66), Vector2i(48,59)]
	)
	var interior_ok := _build_tileset(
		"res://assets/tilesets/emerald_interior_tilesets.png",
		"res://assets/tilesets/emerald_interior.tres",
		Vector2i(192, 64),
		[Vector2i(184,40), Vector2i(184,39), Vector2i(178,42), Vector2i(185,39), Vector2i(180,53), Vector2i(184,38), Vector2i(176,42)]
	)
	if exterior_ok and interior_ok:
		print("TileSets ROSA créés depuis les planches fournies (grille 16×16).")
		quit(0)
	else:
		quit(1)

func _build_tileset(texture_path: String, output_path: String, grid_size: Vector2i, used_cells: Array[Vector2i]) -> bool:
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("Planche introuvable : " + texture_path)
		return false
	if texture.get_width() != grid_size.x * TILE_SIZE or texture.get_height() != grid_size.y * TILE_SIZE:
		push_error("Dimensions incompatibles avec la grille 16×16 : " + texture_path)
		return false
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for cell: Vector2i in used_cells:
		if cell.x < 0 or cell.y < 0 or cell.x >= grid_size.x or cell.y >= grid_size.y:
			push_error("Coordonnée d’atlas hors grille : %s" % cell)
			return false
		atlas.create_tile(cell)
	tile_set.add_source(atlas, 0)
	var sky_texture := load("res://assets/tilesets/placeholder_sky.svg") as Texture2D
	if sky_texture == null:
		push_error("Placeholder sky introuvable.")
		return false
	var sky_atlas := TileSetAtlasSource.new()
	sky_atlas.texture = sky_texture
	sky_atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	sky_atlas.create_tile(Vector2i.ZERO)
	tile_set.add_source(sky_atlas, 1)
	var save_error := ResourceSaver.save(tile_set, output_path)
	if save_error != OK:
		push_error("Échec de sauvegarde : %s (%s)" % [output_path, error_string(save_error)])
		return false
	print("%s : grille %d×%d de 16 px, %d cases sélectionnées" % [output_path, grid_size.x, grid_size.y, used_cells.size()])
	return true
