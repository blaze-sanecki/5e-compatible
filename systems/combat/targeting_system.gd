class_name TargetingSystem
extends RefCounted

## Handles distance calculation, range checks, line of sight, cover, and
## valid target enumeration for the combat system.

## Grid cell size in feet (standard 5e).
const CELL_SIZE_FT: int = 5

## Reference to vision calculator for LoS checks.
var _vision_calc: VisionCalculator

## References to the floor and wall layers.
var _floor_layer: TileMapLayer
var _wall_layer: TileMapLayer


func _init(floor_layer: TileMapLayer, wall_layer: TileMapLayer) -> void:
	_floor_layer = floor_layer
	_wall_layer = wall_layer
	_vision_calc = VisionCalculator.new()


# ---------------------------------------------------------------------------
# Distance
# ---------------------------------------------------------------------------

## Distance in feet between two grid cells (using 5e grid measurement).
## Diagonal movement costs 5 ft (simplified).
func distance_ft(from: Vector2i, to: Vector2i) -> int:
	var dx: int = absi(from.x - to.x)
	var dy: int = absi(from.y - to.y)
	# 5e simplified: each cell = 5 ft, diagonals = 5 ft.
	return maxi(dx, dy) * CELL_SIZE_FT


## Distance between two combatants in feet.
func combatant_distance_ft(a: CombatantData, b: CombatantData) -> int:
	return distance_ft(a.cell, b.cell)


# ---------------------------------------------------------------------------
# Range checks
# ---------------------------------------------------------------------------

## Check if a target is within weapon range.
func is_in_range(attacker: CombatantData, target: CombatantData,
		range_normal: int, range_long: int = 0) -> bool:
	var dist: int = combatant_distance_ft(attacker, target)
	if range_long > 0:
		return dist <= range_long
	return dist <= range_normal


## Check if attacking at long range (disadvantage).
func is_long_range(attacker: CombatantData, target: CombatantData,
		range_normal: int) -> bool:
	var dist: int = combatant_distance_ft(attacker, target)
	return dist > range_normal


# ---------------------------------------------------------------------------
# Line of sight
# ---------------------------------------------------------------------------

## Check if there is a clear line of sight between two cells.
func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	var line: Array[Vector2i] = _vision_calc._bresenham_line(from, to)
	for i in range(1, line.size() - 1):  # Skip start and end cells.
		var cell: Vector2i = line[i]
		if _wall_layer.get_cell_source_id(cell) != -1:
			return false
	return true


## Check LoS between two combatants.
func combatant_has_los(attacker: CombatantData, target: CombatantData) -> bool:
	return has_line_of_sight(attacker.cell, target.cell)


# ---------------------------------------------------------------------------
# Cover
# ---------------------------------------------------------------------------

## Determine cover between attacker and target.
## Returns: 0 = no cover, 2 = half cover (+2 AC), 5 = three-quarters (+5 AC).
func calculate_cover(attacker_cell: Vector2i, target_cell: Vector2i,
		occupied_cells: Array[Vector2i]) -> int:
	var line: Array[Vector2i] = _vision_calc._bresenham_line(attacker_cell, target_cell)
	var obstructions: int = 0

	for i in range(1, line.size() - 1):  # Skip start and end.
		var cell: Vector2i = line[i]
		# Walls provide total cover (but this is checked via LoS).
		if _wall_layer.get_cell_source_id(cell) != -1:
			return 5  # At least three-quarters if we can still target.
		# Other creatures provide half cover.
		if cell in occupied_cells:
			obstructions += 1

	if obstructions >= 2:
		return 5  # Three-quarters cover.
	elif obstructions >= 1:
		return 2  # Half cover.
	return 0


# ---------------------------------------------------------------------------
# Valid targets
# ---------------------------------------------------------------------------

## Get all valid targets for a given attacker and range.
func get_valid_targets(attacker: CombatantData, all_combatants: Array[CombatantData],
		range_normal: int, range_long: int = 0, allies: bool = false) -> Array[CombatantData]:
	var valid: Array[CombatantData] = []

	for target in all_combatants:
		if target == attacker:
			continue
		if target.is_dead:
			continue
		# By default, only enemies are valid targets.
		if not allies and target.type == attacker.type:
			continue
		if not is_in_range(attacker, target, range_normal, range_long):
			continue
		if not combatant_has_los(attacker, target):
			continue
		valid.append(target)

	return valid


## Get all cells in an area of effect.
func get_aoe_cells(center: Vector2i, shape: StringName, radius_ft: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var radius_cells: int = radius_ft / CELL_SIZE_FT

	match shape:
		&"sphere", &"circle":
			for x in range(center.x - radius_cells, center.x + radius_cells + 1):
				for y in range(center.y - radius_cells, center.y + radius_cells + 1):
					if distance_ft(center, Vector2i(x, y)) <= radius_ft:
						cells.append(Vector2i(x, y))
		&"cube", &"square":
			for x in range(center.x - radius_cells, center.x + radius_cells + 1):
				for y in range(center.y - radius_cells, center.y + radius_cells + 1):
					cells.append(Vector2i(x, y))
		&"line":
			# Lines are handled by direction, this is a simple 1-cell-wide line.
			for i in range(1, radius_cells + 1):
				cells.append(Vector2i(center.x + i, center.y))
		&"cone":
			# 5e cone: width at any point = distance from origin.
			for dist in range(1, radius_cells + 1):
				var half_width: int = dist
				for w in range(-half_width, half_width + 1):
					cells.append(Vector2i(center.x + dist, center.y + w))

	return cells


## Get all combatants in an AoE.
func get_combatants_in_aoe(aoe_cells: Array[Vector2i],
		all_combatants: Array[CombatantData]) -> Array[CombatantData]:
	var result: Array[CombatantData] = []
	for c in all_combatants:
		if c.is_dead:
			continue
		if c.cell in aoe_cells:
			result.append(c)
	return result


## Get all occupied cells (for cover calculation).
func get_occupied_cells(all_combatants: Array[CombatantData]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for c in all_combatants:
		if not c.is_dead:
			cells.append(c.cell)
	return cells
