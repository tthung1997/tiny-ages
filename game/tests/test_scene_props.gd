extends McpTestSuite
## Keeping the world tidy (docs/ages.md B10): every prop belongs to a place and its art sits
## inside it, props do not pile on each other, a page is never crowded in any age, and an age can
## replace or retire what the last one built.

## The largest share of a prop's art another piece may cover (a hen in front of a doorstep).
const MAX_OVERLAP: float = 0.25
## Props shown on one page with everything unlocked (alternatives and overlays count once).
const PAGE_BUDGET: Dictionary = {-1: 14, 0: 9, 1: 8}
const LAST_ERA: int = 2


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
		for id: StringName in SceneProps.shown(_everything_unlocked(era_order)):
			var spec: Dictionary = SceneProps.PROPS[id]
			if spec.has("alt_of") or spec.has("overlays"):
				continue
			var page: int = _page_of(id)
			counted[page] = int(counted.get(page, 0)) + 1
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


func test_every_link_between_props_points_at_a_prop() -> void:
	for id: StringName in SceneProps.ids():
		for field: String in ["alt_of", "overlays", "replaced_by"]:
			var spec: Dictionary = SceneProps.PROPS[id]
			if spec.has(field):
				assert_true(SceneProps.PROPS.has(spec[field]), "%s: %s is not a prop" % [id, field])
				assert_true(spec[field] != id, "%s points at itself" % id)


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
