extends TileMapLayer

@export var mapw: int = 64
@export var maph: int = 64

const GROUND := 0
const WALL := 1
const DECORATION := 2

const TILE_SOURCE_ID := 0
const GROUND_ATLAS_COORDS := Vector2i(0, 0)
const WALL_ATLAS_COORDS := Vector2i(1, 0)
const DECORATION_ATLAS_COORDS := Vector2i(2, 0)

var map_data: Array = []

func get_map_origin():
	return Vector2(get_used_rect().position * tile_set.tile_size)

func get_map_center():
	return get_map_origin() + get_map_size() / 2.0

func get_map_size():
	return Vector2(get_used_rect().size * tile_set.tile_size)

func get_tile_size():
	return Vector2(tile_set.tile_size)

func get_random_ground_position():
	while true:
		var pos = Vector2i(randi_range(0, mapw),randi_range(0, maph) )
		if self.get_cell_atlas_coords(pos) == GROUND_ATLAS_COORDS:
			return get_map_origin() + Vector2(pos) * get_tile_size()

func init(random_seed):
	seed(random_seed)
	# fill everything with walls
	for x in range(mapw + 1):
		map_data.append([])
		for y in range(maph + 1):
			map_data[x].append(WALL)

	# random initial carve
	for x in range(1, mapw - 1):
		for y in range(1, maph - 1):
			if randf() < 0.65:
				map_data[x][y] = GROUND

	# smooth
	for i in range(11):
		var new_map := copy_map_data()

		for x in range(1, mapw - 1):
			for y in range(1, maph - 1):
				var n := wall_check(x, y)
				if n > 4:
					new_map[x][y] = WALL
				elif n < 3:
					new_map[x][y] = GROUND
				# else leave unchanged

		map_data = new_map

	# decoration pass
	for x in range(mapw - 1):
		for y in range(maph - 1):
			if x % 8 == 0 and y % 8 == 0:
				var points := [
					Vector2i(x, y),
					Vector2i(x + 1, y),
					Vector2i(x, y + 1),
					Vector2i(x + 1, y + 1),
				]
				for p in points:
					if map_data[p.x][p.y] == GROUND:
						map_data[p.x][p.y] = DECORATION
			if (x + 4) % 8 == 0 and (y + 4) % 8 == 0:
				var points := [
					Vector2i(x - 1, y - 1), Vector2i(x - 1, y),
					Vector2i(x - 1, y + 1), Vector2i(x - 1, y + 2),
					Vector2i(x + 2, y - 1), Vector2i(x + 2, y),
					Vector2i(x + 2, y + 1), Vector2i(x + 2, y + 2),
					Vector2i(x, y - 1), Vector2i(x + 1, y - 1),
					Vector2i(x, y + 2), Vector2i(x + 1, y + 2),
				]
				for p in points:
					if map_data[p.x][p.y] == GROUND:
						map_data[p.x][p.y] = DECORATION

	apply_to_tilemap()

func wall_check(x: int, y: int) -> int:
	var n := 0

	if map_data[x][y - 1] == WALL: n += 1
	if map_data[x][y + 1] == WALL: n += 1
	if map_data[x - 1][y] == WALL: n += 1
	if map_data[x + 1][y] == WALL: n += 1
	if map_data[x + 1][y + 1] == WALL: n += 1
	if map_data[x + 1][y - 2] == WALL: n += 1
	if map_data[x - 1][y + 1] == WALL: n += 1
	if map_data[x - 1][y - 1] == WALL: n += 1

	return n

func copy_map_data() -> Array:
	var result: Array = []
	for x in range(map_data.size()):
		result.append(map_data[x].duplicate())
	return result

func apply_to_tilemap() -> void:
	self.clear()

	for x in range(mapw + 1):
		for y in range(maph + 1):
			var atlas_coords := GROUND_ATLAS_COORDS

			match map_data[x][y]:
				WALL:
					atlas_coords = WALL_ATLAS_COORDS
				DECORATION:
					atlas_coords = DECORATION_ATLAS_COORDS
				GROUND:
					atlas_coords = GROUND_ATLAS_COORDS

			self.set_cell(Vector2i(x, y), TILE_SOURCE_ID, atlas_coords)
