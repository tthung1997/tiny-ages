extends McpTestSuite
## Keeping the world tidy (docs/ages.md B10): every prop belongs to a place and its art sits
## inside it, props do not pile on each other, a page is never crowded in any age, and an age can
## replace or retire what the last one built.

## The largest share of a prop's art another piece may cover (a hen in front of a doorstep).
const MAX_OVERLAP: float = 0.25
## Props shown on one page with everything unlocked (alternatives and overlays count once).
const PAGE_BUDGET: Dictionary = {-1: 14, 0: 9, 1: 8}
const LAST_ERA: int = 3
## The cave's standard and door shown at once (one of each per age).
const MAX_CAVE_DRESSING: int = 2


func suite_name() -> String:
	return "scene_props"


## A world in era `era_order` that holds everything a prop can wait for.
func _everything_unlocked(era_order: int) -> WorldState:
	var world: WorldState = WorldState.new()
	world.era_order = era_order
	for id: StringName in SceneProps.ids():
		var spec: Dictionary = SceneProps.PROPS[id]
		if spec["kind"] == SceneProps.Kind.FLAG:
			world.flags[spec["key"]] = true
		elif spec["kind"] == SceneProps.Kind.ACHIEVEMENT:
			world.achievements.append(spec["key"])
		elif spec["kind"] == SceneProps.Kind.BUILDING:
			var building: BuildingState = BuildingState.new()
			building.def_id = spec["key"]
			building.complete = true
			world.buildings.append(building)
	return world


## Where a piece's drawn pixels are in camp pixels, in the newest art the age has for it. `at` is
## where its sprite's top-left corner sits.
func _used_rect(layer: StringName, era_order: int, at: Vector2) -> Rect2:
	var path: String = WorldLayout.piece_path(layer, era_order)
	if path.is_empty():
		return Rect2()
	var texture: Texture2D = load(path) as Texture2D
	assert_true(texture != null, "No art for %s" % layer)
	if texture == null:
		return Rect2()
	var used: Rect2i = texture.get_image().get_used_rect()
	return Rect2(Vector2(used.position) + at, Vector2(used.size))


func _at_of(id: StringName) -> Vector2:
	return Vector2(SceneProps.at_x_of(id), SceneProps.at_y_of(id))


func _art_rect(id: StringName, era_order: int) -> Rect2:
	return _used_rect(id, era_order, _at_of(id))


func _overlap_share(a: Rect2, b: Rect2) -> float:
	var common: Rect2 = a.intersection(b)
	if a.get_area() <= 0.0 or common.get_area() <= 0.0:
		return 0.0
	return common.get_area() / minf(a.get_area(), b.get_area())


## The share of the smaller piece's drawn pixels that the other covers: art is rarely a full
## rectangle, so this is the fair test once the rectangles overlap.
func _pixel_share(a_layer: StringName, a_at: Vector2, b_layer: StringName, b_at: Vector2, era: int) -> float:
	var a_path: String = WorldLayout.piece_path(a_layer, era)
	var b_path: String = WorldLayout.piece_path(b_layer, era)
	if a_path.is_empty() or b_path.is_empty():
		return 0.0
	var a: Image = (load(a_path) as Texture2D).get_image()
	var b: Image = (load(b_path) as Texture2D).get_image()
	var offset: Vector2i = Vector2i(a_at - b_at)
	var a_count: int = 0
	var b_count: int = 0
	var both: int = 0
	for y: int in a.get_height():
		for x: int in a.get_width():
			var a_solid: bool = a.get_pixel(x, y).a > 0.05
			var bx: int = x + offset.x
			var by: int = y + offset.y
			var b_solid: bool = (
				bx >= 0 and bx < b.get_width() and by >= 0 and by < b.get_height()
				and b.get_pixel(bx, by).a > 0.05
			)
			a_count += 1 if a_solid else 0
			both += 1 if a_solid and b_solid else 0
	for y: int in b.get_height():
		for x: int in b.get_width():
			b_count += 1 if b.get_pixel(x, y).a > 0.05 else 0
	if a_count == 0 or b_count == 0:
		return 0.0
	return float(both) / float(mini(a_count, b_count))


func _root(id: StringName) -> StringName:
	var spec: Dictionary = SceneProps.PROPS[id]
	if spec.has("alt_of"):
		return _root(spec["alt_of"])
	if spec.has("overlays"):
		return _root(spec["overlays"])
	return id


## Alternatives and overlays are meant to share ground.
func _related(a: StringName, b: StringName) -> bool:
	return _root(a) == _root(b)


func _page_of(id: StringName) -> int:
	var place: Rect2 = WorldLayout.PLACES.get(SceneProps.place_of(id), Rect2())
	return int(floor(place.position.x / 384.0))


func test_every_prop_belongs_to_a_place() -> void:
	for id: StringName in SceneProps.ids():
		assert_true(
			WorldLayout.PLACES.has(SceneProps.place_of(id)),
			"%s has no known place (%s)" % [id, SceneProps.place_of(id)]
		)


func test_places_do_not_overlap() -> void:
	var ids: Array = WorldLayout.PLACES.keys()
	for i: int in ids.size():
		for j: int in range(i + 1, ids.size()):
			var a: Rect2 = WorldLayout.PLACES[ids[i]]
			var b: Rect2 = WorldLayout.PLACES[ids[j]]
			assert_false(a.intersects(b), "%s and %s overlap" % [ids[i], ids[j]])


func test_a_props_art_sits_inside_its_place_in_every_age() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var world: WorldState = _everything_unlocked(era_order)
		for id: StringName in SceneProps.shown(world):
			var place: Rect2 = WorldLayout.PLACES.get(SceneProps.place_of(id), Rect2())
			var art: Rect2 = _art_rect(id, era_order)
			if art.get_area() <= 0.0:
				continue
			assert_true(
				place.encloses(art), "%s (age %d) is drawn at %s, outside %s %s" % [
					id, era_order, art, SceneProps.place_of(id), place
				]
			)


func test_props_shown_together_do_not_pile_on_each_other() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var shown: Array[StringName] = SceneProps.shown(_everything_unlocked(era_order))
		for i: int in shown.size():
			for j: int in range(i + 1, shown.size()):
				if _related(shown[i], shown[j]):
					continue
				var a: Dictionary = SceneProps.PROPS[shown[i]]
				var b: Dictionary = SceneProps.PROPS[shown[j]]
				if a.has("behind") or b.has("behind"):
					continue
				var share: float = _overlap_share(
					_art_rect(shown[i], era_order), _art_rect(shown[j], era_order)
				)
				if share > MAX_OVERLAP:
					share = _pixel_share(
						shown[i], _at_of(shown[i]), shown[j], _at_of(shown[j]), era_order
					)
				assert_true(
					share <= MAX_OVERLAP, "Age %d: %s and %s cover each other (%d%%)" % [
						era_order, shown[i], shown[j], int(share * 100.0)
					]
				)


func test_a_prop_does_not_stand_on_a_building_unless_it_is_behind_it() -> void:
	for era_order: int in range(LAST_ERA + 1):
		for id: StringName in SceneProps.shown(_everything_unlocked(era_order)):
			var art: Rect2 = _art_rect(id, era_order)
			for building_id: StringName in WorldLayout.BUILDINGS:
				if SceneProps.z_of(id) < int(WorldLayout.BUILDINGS[building_id]["z"]):
					continue
				for prefix: String in ["building_", "site_"]:
					var piece: Rect2 = _used_rect(
						StringName(prefix + building_id), era_order,
						WorldLayout.building_offset(building_id)
					)
					assert_true(
						_overlap_share(art, piece) <= MAX_OVERLAP,
						"Age %d: %s stands on %s%s" % [era_order, id, prefix, building_id]
					)


func test_no_page_is_crowded_in_any_age_once_everything_is_unlocked() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var counted: Dictionary = {}
		var dressing: int = 0
		for id: StringName in SceneProps.shown(_everything_unlocked(era_order)):
			var spec: Dictionary = SceneProps.PROPS[id]
			if spec["kind"] == SceneProps.Kind.ALWAYS:
				# The cave's own door and marks sit on the cliff's face, not on the ground the
				# budget protects; they have their own cap below.
				dressing += 1
				continue
			if spec.has("alt_of") or spec.has("overlays"):
				continue
			var page: int = _page_of(id)
			counted[page] = int(counted.get(page, 0)) + 1
		assert_true(dressing <= MAX_CAVE_DRESSING, "Age %d: the cave shows %d pieces" % [era_order, dressing])
		for page: int in counted:
			assert_true(
				int(counted[page]) <= int(PAGE_BUDGET.get(page, 0)),
				"Age %d, page %d shows %d props (at most %d)" % [
					era_order, page, counted[page], PAGE_BUDGET.get(page, 0)
				]
			)


func test_the_bronze_age_simplifies_what_the_settled_age_scattered() -> void:
	var settled: Array[StringName] = SceneProps.shown(_everything_unlocked(1))
	var bronze: Array[StringName] = SceneProps.shown(_everything_unlocked(2))
	for old: StringName in [
		&"pots", &"west_kiln", &"clay_pits", &"loom", &"cloth_line", &"west_plot_farm",
		&"west_scarecrow", &"hens", &"west_plot_patch", &"west_pen",
	]:
		assert_true(settled.has(old), "%s stands in the Settled Age" % old)
		assert_false(bronze.has(old), "%s is folded into a yard in the Bronze Age" % old)
	for tidy: StringName in [
		&"potters_yard", &"weavers_row", &"town_wall", &"crossing_planks", &"quay_boats",
		&"farmstead_farm", &"farmstead_herd",
	]:
		assert_false(settled.has(tidy), "%s waits for the Bronze Age" % tidy)
		assert_true(bronze.has(tidy), "%s is the Bronze Age's" % tidy)
	assert_false(bronze.has(&"low_wall"), "The town wall replaces the low wall")
	assert_false(bronze.has(&"green_stones"), "The green stone is put away in the Bronze Age")
	for afloat: StringName in [&"boat_dugout", &"boat_raft", &"river_trap", &"crossing_stones"]:
		assert_false(bronze.has(afloat), "%s gives way to the quay and the bridge" % afloat)


func test_the_iron_age_redraws_the_wall_the_tally_and_the_ship() -> void:
	var bronze: Array[StringName] = SceneProps.shown(_everything_unlocked(2))
	var iron: Array[StringName] = SceneProps.shown(_everything_unlocked(3))
	for old: StringName in [&"town_wall", &"low_wall", &"tally_post", &"east_sail"]:
		assert_false(iron.has(old), "%s gives way to the Iron Age's piece" % old)
	for tidy: StringName in [&"rampart", &"writing_post", &"east_deep_ship"]:
		assert_false(bronze.has(tidy), "%s waits for the Iron Age" % tidy)
		assert_true(iron.has(tidy), "%s is the Iron Age's" % tidy)
	for fresh: StringName in [
		&"slag_heap", &"plough_team", &"shearing_pen", &"coin_tray", &"standing_stone",
		&"east_beacon",
	]:
		assert_false(bronze.has(fresh), "%s waits for the Iron Age" % fresh)
		assert_true(iron.has(fresh), "%s is the Iron Age's" % fresh)
	for kept: StringName in [&"market_stalls", &"council_ring", &"cart", &"donkeys", &"quay_boats"]:
		assert_true(iron.has(kept), "%s stays in the Iron Age" % kept)
	for tidy: StringName in [
		&"potters_yard", &"weavers_row", &"crossing_planks", &"farmstead_farm", &"farmstead_herd",
	]:
		assert_true(iron.has(tidy), "The Bronze Age's %s stays" % tidy)
	for folded: StringName in [
		&"pots", &"west_kiln", &"clay_pits", &"loom", &"cloth_line", &"west_plot_farm", &"hens",
		&"west_pen", &"green_stones", &"boat_dugout", &"crossing_stones",
	]:
		assert_false(iron.has(folded), "%s stays folded away in the Iron Age" % folded)


const CAVE_DOORS: Array[StringName] = [&"cave_door_settled", &"cave_door_bronze", &"cave_door_iron"]
const CAVE_STANDARDS: Array[StringName] = [
	&"cave_standard_cave", &"cave_standard_settled", &"cave_standard_bronze", &"cave_standard_iron",
]
## The colour of the cave's opening in the cliff art (tools/art/lib.js cliff()).
const MOUTH_DARK: Color = Color("2a2433")
## Where the standards' poles stand on the cliff's top edge.
const STANDARD_POLE_X: int = 26


func _empty_world(era_order: int) -> WorldState:
	var world: WorldState = WorldState.new()
	world.era_order = era_order
	return world


func test_the_first_age_shows_only_the_caves_own_pennant() -> void:
	assert_eq(
		SceneProps.shown(_empty_world(0)), [&"cave_standard_cave"] as Array[StringName],
		"The Cave Age's cave has its pennant and nothing else"
	)


func test_the_cave_door_is_replaced_each_age() -> void:
	for id: StringName in SceneProps.shown(_empty_world(0)):
		assert_false(CAVE_DOORS.has(id), "The Cave Age has no door yet")
	for era_order: int in range(1, LAST_ERA + 1):
		var shown: Array[StringName] = SceneProps.shown(_empty_world(era_order))
		for index: int in CAVE_DOORS.size():
			assert_eq(
				shown.has(CAVE_DOORS[index]), index == era_order - 1,
				"Age %d shows only its own door (%s)" % [era_order, CAVE_DOORS[index]]
			)


func test_the_standard_on_the_cliff_is_replaced_each_age() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var shown: Array[StringName] = SceneProps.shown(_empty_world(era_order))
		for index: int in CAVE_STANDARDS.size():
			assert_eq(
				shown.has(CAVE_STANDARDS[index]), index == era_order,
				"Age %d shows only its own standard (%s)" % [era_order, CAVE_STANDARDS[index]]
			)


func test_the_cave_shows_only_because_the_age_turned() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var world: WorldState = _empty_world(era_order)
		# The standard, then from the first turn a door as well.
		var expected: int = 1 if era_order == 0 else 2
		assert_eq(
			SceneProps.shown(world).size(), expected,
			"Age %d with nothing earned shows only the cave's own pieces" % era_order
		)
		for id: StringName in SceneProps.shown(world):
			assert_eq(SceneProps.PROPS[id]["kind"], SceneProps.Kind.ALWAYS, "%s waits for nothing" % id)


func test_the_cave_door_fits_the_whole_mouth() -> void:
	var cliff: Image = (load(WorldLayout.piece_path(&"static_back", 0)) as Texture2D).get_image()
	for era_order: int in range(1, LAST_ERA + 1):
		var door_id: StringName = CAVE_DOORS[era_order - 1]
		var door: Image = (load(WorldLayout.piece_path(door_id, era_order)) as Texture2D).get_image()
		for x: int in range(20, 48):
			var crown: int = -1
			for y: int in range(30, 66):
				if cliff.get_pixel(x, y).is_equal_approx(MOUTH_DARK):
					crown = y
					break
			assert_true(crown >= 0, "Column %d has no opening" % x)
			assert_true(
				door.get_pixel(x, crown).a > 0.5,
				"%s leaves the top of the arch bare at column %d (row %d)" % [door_id, x, crown]
			)
		for x: int in [20, 21, 46, 47]:
			assert_true(door.get_pixel(x, 65).a > 0.5, "%s: a post does not reach the floor at %d" % [door_id, x])


func test_the_standards_are_inside_the_skyline() -> void:
	var cliff: Texture2D = load(WorldLayout.piece_path(&"static_back", 0)) as Texture2D
	for era_order: int in range(LAST_ERA + 1):
		var id: StringName = CAVE_STANDARDS[era_order]
		var texture: Texture2D = load(WorldLayout.piece_path(id, era_order)) as Texture2D
		var skyline: Skyline = Skyline.new(384, WorldLayout.VIEW_SIZE.y)
		skyline.add(cliff, 0)
		skyline.add(texture, 0)
		var art: Image = texture.get_image()
		for x: int in art.get_width():
			for y: int in art.get_height():
				if art.get_pixel(x, y).a > Skyline.ALPHA_CLICKABLE:
					assert_true(y >= skyline.tops[x], "%s: (%d, %d) is above the skyline" % [id, x, y])
		var pole: int = skyline.tops[STANDARD_POLE_X]
		assert_true(pole < 22, "%s's pole rises above the cliff's edge in the skyline" % id)


func test_the_standards_stand_on_the_cliffs_top_and_stay_small() -> void:
	var cliff: Image = (load(WorldLayout.piece_path(&"static_back", 0)) as Texture2D).get_image()
	for era_order: int in range(LAST_ERA + 1):
		var id: StringName = CAVE_STANDARDS[era_order]
		var art: Image = (load(WorldLayout.piece_path(id, era_order)) as Texture2D).get_image()
		var used: Rect2i = art.get_used_rect()
		assert_true(used.size.x <= 12 and used.size.y <= 22, "%s is %s, too big" % [id, used.size])
		var base: int = -1
		for y: int in range(art.get_height() - 1, -1, -1):
			if art.get_pixel(STANDARD_POLE_X, y).a > 0.5:
				base = y
				break
		assert_true(base >= 0, "%s has no pole" % id)
		assert_true(cliff.get_pixel(STANDARD_POLE_X, base).a > 0.5, "%s does not stand on the rock" % id)


func test_the_cave_door_leaves_the_firelight_and_the_gathering_spots_clear() -> void:
	var fire: Image = (load(WorldLayout.piece_path(&"fire_pit_0", 0)) as Texture2D).get_image()
	for era_order: int in range(1, LAST_ERA + 1):
		var door_id: StringName = CAVE_DOORS[era_order - 1]
		var door: Image = (load(WorldLayout.piece_path(door_id, era_order)) as Texture2D).get_image()
		for y: int in door.get_height():
			for x: int in door.get_width():
				if door.get_pixel(x, y).a <= 0.05:
					continue
				var point: Vector2 = Vector2(x, y)
				assert_false(WorldLayout.FIRE_HIT.has_point(point), "%s covers the fire at %s" % [door_id, point])
				if x < int(WorldLayout.FIRE_HIT.position.x):
					assert_true(
						fire.get_pixel(x, y).a <= 0.05, "%s covers the firelight at %s" % [door_id, point]
					)
		var art: Rect2 = _art_rect(door_id, era_order)
		for spot: Vector2 in WorldLayout.COLD_SPOTS:
			assert_false(art.has_point(spot), "%s is on the cold spot %s" % [door_id, spot])


func test_the_low_wall_gives_way_to_either_wall() -> void:
	var world: WorldState = _world_with(&"low_wall", 3)
	assert_true(SceneProps.is_shown(&"low_wall", world))
	world.flags[&"town_wall"] = true
	assert_false(SceneProps.is_shown(&"low_wall", world), "The town wall replaces it")
	assert_true(SceneProps.is_shown(&"town_wall", world))
	world.flags[&"hill_fort"] = true
	assert_false(SceneProps.is_shown(&"low_wall", world), "And so does the rampart")
	assert_false(SceneProps.is_shown(&"town_wall", world), "The rampart redraws the town wall")
	assert_true(SceneProps.is_shown(&"rampart", world))


func test_every_link_between_props_points_at_a_prop() -> void:
	for id: StringName in SceneProps.ids():
		var spec: Dictionary = SceneProps.PROPS[id]
		for field: String in ["alt_of", "overlays"]:
			if spec.has(field):
				assert_true(SceneProps.PROPS.has(spec[field]), "%s: %s is not a prop" % [id, field])
				assert_true(spec[field] != id, "%s points at itself" % id)
		for replacer: StringName in SceneProps.replacements_of(spec):
			assert_true(SceneProps.PROPS.has(replacer), "%s: %s is not a prop" % [id, replacer])
			assert_true(replacer != id, "%s points at itself" % id)


func _world_with(flag: StringName, era_order: int) -> WorldState:
	var world: WorldState = WorldState.new()
	world.era_order = era_order
	world.flags[flag] = true
	return world


func test_a_replaced_prop_is_hidden_while_its_replacement_is_shown() -> void:
	var props: Dictionary = {
		&"old": {"kind": SceneProps.Kind.FLAG, "key": &"a", "replaced_by": &"new"},
		&"new": {"kind": SceneProps.Kind.FLAG, "key": &"b"},
	}
	var world: WorldState = _world_with(&"a", 0)
	assert_true(SceneProps.is_shown_in(props, &"old", world), "Shown until replaced")
	world.flags[&"b"] = true
	assert_false(SceneProps.is_shown_in(props, &"old", world), "Hidden once replaced")
	assert_true(SceneProps.is_shown_in(props, &"new", world))


func test_a_retired_prop_is_hidden_from_its_era_on() -> void:
	var props: Dictionary = {
		&"gone": {"kind": SceneProps.Kind.FLAG, "key": &"a", "until_era": 2},
	}
	assert_true(SceneProps.is_shown_in(props, &"gone", _world_with(&"a", 1)))
	assert_false(SceneProps.is_shown_in(props, &"gone", _world_with(&"a", 2)))
	assert_false(SceneProps.is_shown_in(props, &"gone", _world_with(&"a", 3)))


func test_a_prop_waits_for_its_era() -> void:
	var props: Dictionary = {
		&"later": {"kind": SceneProps.Kind.FLAG, "key": &"a", "from_era": 2},
	}
	assert_false(SceneProps.is_shown_in(props, &"later", _world_with(&"a", 1)))
	assert_true(SceneProps.is_shown_in(props, &"later", _world_with(&"a", 2)))
