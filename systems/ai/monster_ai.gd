class_name MonsterAI
extends RefCounted

## Simple monster AI that executes a turn: move toward nearest enemy and attack.
## Uses AIUtility for target selection and path planning.


## Execute a full turn for a monster combatant.
func execute_turn(combatant: CombatantData, all_combatants: Array[CombatantData],
		combat_mgr: CombatManager) -> void:
	if combatant.is_dead or not combatant.is_alive():
		return

	# Find enemies (players).
	var enemies: Array[CombatantData] = combat_mgr.get_enemies_of(combatant)
	if enemies.is_empty():
		return

	# Find the nearest enemy with line of sight first, fall back to nearest overall.
	var target: CombatantData = null
	var distance: int = 999

	for enemy in enemies:
		if enemy.is_dead:
			continue
		var dist: int = combat_mgr.targeting_system.combatant_distance_ft(combatant, enemy)
		if dist < distance and combat_mgr.targeting_system.combatant_has_los(combatant, enemy):
			distance = dist
			target = enemy

	# If no enemy with LoS, pick nearest to move toward.
	if target == null:
		var nearest_info: Dictionary = AIUtility.find_nearest_enemy(combatant, enemies)
		target = nearest_info.get("target")
		distance = nearest_info.get("distance", 999)
	if target == null:
		return

	# Pick the best action.
	var action: Variant = AIUtility.pick_best_action(combatant, target, distance)

	# Determine if we need to move.
	var action_reach: int = 5
	if action is Dictionary:
		action_reach = action.get("reach", action.get("range_normal", 5))

	# Move toward target if not in range or no line of sight.
	var has_los_before: bool = combat_mgr.targeting_system.combatant_has_los(combatant, target)
	if (distance > action_reach or not has_los_before) and combatant.movement_remaining > 0:
		_move_toward_target(combatant, target, combat_mgr)

		# Recalculate distance after moving.
		distance = combat_mgr.targeting_system.combatant_distance_ft(combatant, target)

	# Check line of sight before attacking.
	var has_los: bool = combat_mgr.targeting_system.combatant_has_los(combatant, target)

	# Attack if in range, have LoS, and have an action.
	if distance <= action_reach and has_los and combatant.has_action and action != null:
		_execute_attack(combatant, target, action, combat_mgr)

	# If we have a ranged action and didn't use our action yet, try that.
	if combatant.has_action and has_los:
		var ranged_action: Variant = _find_ranged_action(combatant)
		if ranged_action != null:
			var range_normal: int = ranged_action.get("range_normal", 30)
			if distance <= range_normal:
				_execute_attack(combatant, target, ranged_action, combat_mgr)


## Move toward a target, updating both combatant data and the visual token.
func _move_toward_target(combatant: CombatantData, target: CombatantData,
		combat_mgr: CombatManager) -> void:
	if combat_mgr.floor_layer == null or combat_mgr.wall_layer == null:
		return

	var pathfinder := GridPathfinding.new(combat_mgr.floor_layer, combat_mgr.wall_layer)
	var approach_cell: Vector2i = AIUtility.find_approach_cell(combatant, target, pathfinder, combat_mgr.targeting_system)

	if approach_cell == combatant.cell:
		return

	var max_cells: int = combatant.movement_remaining / 5
	var path: Array[Vector2i] = pathfinder.find_path(combatant.cell, approach_cell, max_cells)
	if path.is_empty():
		return

	# Move the combatant data.
	var cells_moved: Array[Vector2i] = combat_mgr.move_combatant(combatant, path)

	# Animate the token.
	if combatant.token and combatant.token is MonsterToken:
		var mt: MonsterToken = combatant.token as MonsterToken
		for cell in cells_moved:
			mt.move_to_cell(cell)
			# Wait for animation to finish before next step.
			if mt.is_moving:
				await mt.moved_to


## Execute an attack action.
func _execute_attack(combatant: CombatantData, target: CombatantData,
		action: Variant, combat_mgr: CombatManager) -> void:
	var result: Dictionary = combat_mgr.action_system.execute_attack(
		combatant, target, action, combat_mgr.combatants
	)

	# Visual feedback.
	if result.get("hit", false) and target.token:
		if target.token is MonsterToken:
			(target.token as MonsterToken).flash_damage()
		elif target.token is CharacterToken:
			# Flash the character token red briefly.
			var token_node: Node2D = target.token as Node2D
			var tween: Tween = token_node.create_tween()
			tween.tween_property(token_node, "modulate", Color(1.5, 0.3, 0.3), 0.1)
			tween.tween_property(token_node, "modulate", Color.WHITE, 0.2)

		if target.is_dead and target.token is MonsterToken:
			(target.token as MonsterToken).play_death()


## Find a ranged action from the monster's action list.
func _find_ranged_action(combatant: CombatantData) -> Variant:
	if not combatant.is_monster():
		return null
	var monster_data: MonsterData = combatant.source as MonsterData
	if monster_data == null:
		return null
	for action in monster_data.actions:
		if action.get("type") == "ranged_attack":
			return action
	return null
