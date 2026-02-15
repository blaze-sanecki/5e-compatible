class_name AIUtility
extends RefCounted

## Utility functions for monster AI decision-making.
## Evaluates threats, finds optimal positions, and scores targets.


## Evaluate threat level of a target (higher = more dangerous).
static func evaluate_threat(target: CombatantData) -> float:
	if target.is_dead or target.current_hp <= 0:
		return 0.0

	var threat: float = 0.0

	# Higher level = more threat.
	threat += float(target.get_level()) * 2.0

	# Low HP = less threat (target the strong ones or finish the weak ones?).
	var hp_ratio: float = float(target.current_hp) / float(maxi(target.max_hp, 1))
	threat += hp_ratio * 5.0

	# Spellcasters are higher threat.
	if target.is_player() and target.source.get("character_class"):
		if target.source.character_class.get("is_spellcaster"):
			threat += 5.0

	return threat


## Find the nearest enemy and return its distance and reference.
static func find_nearest_enemy(combatant: CombatantData,
		enemies: Array[CombatantData]) -> Dictionary:
	var nearest: CombatantData = null
	var nearest_dist: int = 999

	for enemy in enemies:
		if enemy.is_dead:
			continue
		var dx: int = absi(combatant.cell.x - enemy.cell.x)
		var dy: int = absi(combatant.cell.y - enemy.cell.y)
		var dist: int = maxi(dx, dy) * 5
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return {"target": nearest, "distance": nearest_dist}


## Find the best approach cell to reach a target within the movement budget.
## Prefers cells with line of sight to the target, then closest distance.
static func find_approach_cell(combatant: CombatantData, target: CombatantData,
		pathfinder: GridPathfinding, targeting: TargetingSystem = null) -> Vector2i:
	var max_cells: int = combatant.movement_remaining / 5
	var reachable: Array[Vector2i] = pathfinder.get_reachable_cells(combatant.cell, max_cells)

	if reachable.is_empty():
		return combatant.cell

	var best_cell: Vector2i = combatant.cell
	var best_dist: int = 999
	var best_has_los: bool = false

	for cell in reachable:
		var dx: int = absi(cell.x - target.cell.x)
		var dy: int = absi(cell.y - target.cell.y)
		var dist: int = maxi(dx, dy)

		# Avoid landing on occupied cells.
		if cell == target.cell:
			continue

		var cell_has_los: bool = true
		if targeting:
			cell_has_los = targeting.has_line_of_sight(cell, target.cell)

		# Prefer cells with LoS over cells without.
		if cell_has_los and not best_has_los:
			best_has_los = true
			best_dist = dist
			best_cell = cell
		elif cell_has_los == best_has_los and dist < best_dist:
			best_dist = dist
			best_cell = cell

	return best_cell


## Pick the best action from a monster's action list based on range.
static func pick_best_action(monster: CombatantData,
		target: CombatantData, distance_ft: int) -> Variant:
	if not monster.is_monster():
		return null

	var monster_data: MonsterData = monster.source as MonsterData
	if monster_data == null or monster_data.actions.is_empty():
		return null

	# Prefer melee if adjacent, ranged if at distance.
	var best_action: Variant = null
	var best_score: float = -1.0

	for action in monster_data.actions:
		var action_type: String = action.get("type", "melee_attack")
		var reach: int = action.get("reach", 5)
		var range_normal: int = action.get("range_normal", 5)
		var score: float = 0.0

		if action_type == "melee_attack":
			if distance_ft <= reach:
				score = 10.0  # Melee is preferred when in range.
			else:
				score = -1.0  # Can't use melee from here.
		elif action_type == "ranged_attack":
			if distance_ft <= range_normal:
				score = 5.0  # In normal range.
			elif distance_ft <= action.get("range_long", range_normal):
				score = 2.0  # Long range (disadvantage).
			else:
				score = -1.0

		# Parse damage for scoring.
		var damage_str: String = action.get("damage", "1d4")
		score += _estimate_average_damage(damage_str) * 0.5

		if score > best_score:
			best_score = score
			best_action = action

	return best_action


## Estimate average damage from a notation string like "2d6+3".
static func _estimate_average_damage(notation: String) -> float:
	# Simple parse: NdM+B.
	var result := DiceRoller.roll(notation)
	# Use a rough average instead of rolling.
	var parts: PackedStringArray = notation.replace("-", "+-").split("+")
	var total: float = 0.0
	for part in parts:
		part = part.strip_edges()
		if "d" in part.to_lower():
			var dice_parts: PackedStringArray = part.to_lower().split("d")
			if dice_parts.size() == 2:
				var count: float = float(dice_parts[0])
				var sides: float = float(dice_parts[1])
				total += count * (sides + 1.0) / 2.0
		elif part != "":
			total += float(part)
	return total
