extends SceneTree

const TILE_SIZE := 16
const BAND_SOURCE_BASE := 10
const RIVAL_ROOF_SOURCE_ID := 30

func _initialize() -> void:
	var exterior_ok := _build_tileset(
		"res://assets/tilesets/emerald_exterior_tileset.png",
		"res://assets/tilesets/emerald_exterior.tres",
		Vector2i(88, 69),
		[Vector2i(87,14), Vector2i(87,13), Vector2i(84,22), Vector2i(83,22), Vector2i(28,56), Vector2i(28,58), Vector2i(5,4), Vector2i(5,0), Vector2i(4,0), Vector2i(61,40), Vector2i(26,66), Vector2i(48,59)],
		true
	)
	var interior_ok := _build_tileset(
		"res://assets/tilesets/emerald_interior_tilesets.png",
		"res://assets/tilesets/emerald_interior.tres",
		Vector2i(192, 64),
		[Vector2i(184,40), Vector2i(184,39), Vector2i(178,42), Vector2i(185,39), Vector2i(180,53), Vector2i(184,38), Vector2i(176,42)],
		false
	)
	if exterior_ok and interior_ok:
		print("TileSets ROSA créés depuis les planches fournies (grille 16×16).")
		quit(0)
	else:
		quit(1)

func _build_tileset(texture_path: String, output_path: String, grid_size: Vector2i, used_cells: Array[Vector2i], add_bands: bool) -> bool:
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
	if add_bands and not _add_band_sources(tile_set):
		return false
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

func _add_band_sources(tile_set: TileSet) -> bool:
	var stamp_file := FileAccess.open("res://data/building_stamps.json", FileAccess.READ)
	if stamp_file == null:
		push_error("Catalogue de stamps introuvable.")
		return false
	var stamp_data: Dictionary = JSON.parse_string(stamp_file.get_as_text()) as Dictionary
	var cells_by_band: Dictionary = {}
	var rival_roof_cells: Dictionary = {}
	for stamp_value: Variant in stamp_data["stamps"]:
		var stamp: Dictionary = stamp_value
		var band_number := int(stamp["band"])
		if not cells_by_band.has(band_number):
			cells_by_band[band_number] = {}
		for tile_value: Variant in stamp["tiles"]:
			var tile: Dictionary = tile_value
			var atlas_cell: Array = tile["atlas"]
			var cell := Vector2i(int(atlas_cell[0]), int(atlas_cell[1]))
			(cells_by_band[band_number] as Dictionary)[cell] = true
			if str(stamp.get("roof_variant", "")) == "band_01_rival_roof" and str(tile["role"]) == "roof":
				rival_roof_cells[cell] = true
	for band_index: int in range(11):
		var band_path := "res://assets/tilesets/bands/band_%02d.png" % (band_index + 1)
		var band_texture := load(band_path) as Texture2D
		if band_texture == null or band_texture.get_width() != 128 or band_texture.get_height() != 1104:
			push_error("Bande extérieure invalide : " + band_path)
			return false
		var band_source := TileSetAtlasSource.new()
		band_source.texture = band_texture
		band_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		var band_number := band_index + 1
		if cells_by_band.has(band_number):
			for cell_value: Variant in (cells_by_band[band_number] as Dictionary).keys():
				var used_cell: Vector2i = cell_value
				band_source.create_tile(used_cell)
		tile_set.add_source(band_source, BAND_SOURCE_BASE + band_index)
	var roof_path := "res://assets/tilesets/bands/band_01_rival_roof.png"
	var roof_texture := load(roof_path) as Texture2D
	if roof_texture == null or roof_texture.get_width() != 128 or roof_texture.get_height() != 1104:
		push_error("Variante de toit du rival invalide : " + roof_path)
		return false
	var roof_source := TileSetAtlasSource.new()
	roof_source.texture = roof_texture
	roof_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for cell_value: Variant in rival_roof_cells.keys():
		var roof_cell: Vector2i = cell_value
		roof_source.create_tile(roof_cell)
	tile_set.add_source(roof_source, RIVAL_ROOF_SOURCE_ID)
	return true
