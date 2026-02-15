class_name GridTokenManager
extends RefCounted

## Manages character and monster token arrays, spawning, and selection
## for GridDungeonController.

var character_tokens: Array[CharacterToken] = []
var character_states: Array[GridEntityState] = []
var selected_token_index: int = 0
var monster_tokens: Array[MonsterToken] = []

var _floor_layer: TileMapLayer
var _parent: Node2D


func _init(floor_layer: TileMapLayer, parent: Node2D) -> void:
	_floor_layer = floor_layer
	_parent = parent


# ---------------------------------------------------------------------------
# Character token helpers
# ---------------------------------------------------------------------------

## Spawn character tokens from the party roster at the given cell.
func spawn_party(spawn_cell: Vector2i) -> void:
	for i in PartyManager.party.size():
		var character: Resource = PartyManager.party[i]

		# Offset each character by one cell so they don't stack.
		var cell: Vector2i = spawn_cell + Vector2i(i, 0)

		# Create logic state.
		var base_speed: int = character.speed if character.get("speed") else 30
		var state := GridEntityState.new(cell, base_speed)
		character_states.append(state)

		# Create visual token.
		var token: CharacterToken = CharacterToken.new()
		token.name = "CharToken_%d" % i
		_parent.add_child(token)

		# Give the token a visible sprite.
		var color: Color = [
			Color(0.2, 0.6, 1.0), Color(0.2, 0.9, 0.3),
			Color(0.9, 0.4, 0.2), Color(0.8, 0.2, 0.8),
		][i % 4]
		var sprite := Sprite2D.new()
		sprite.texture = TestMapGenerator.create_circle_texture(20, color)
		token.add_child(sprite)

		token.character_data = character
		token.teleport_visual(_floor_layer.map_to_local(cell))
		character_tokens.append(token)

	if not character_states.is_empty():
		character_states[0].select()
		character_tokens[0].set_selected_visual(true)
		selected_token_index = 0


func get_active_token() -> CharacterToken:
	if character_tokens.is_empty() or selected_token_index >= character_tokens.size():
		return null
	return character_tokens[selected_token_index]


func get_active_state() -> GridEntityState:
	if character_states.is_empty() or selected_token_index >= character_states.size():
		return null
	return character_states[selected_token_index]


func cycle_selected() -> void:
	if character_states.size() <= 1:
		return

	var old_state: GridEntityState = get_active_state()
	var old_token: CharacterToken = get_active_token()
	if old_state:
		old_state.deselect()
	if old_token:
		old_token.set_selected_visual(false)

	selected_token_index = (selected_token_index + 1) % character_states.size()

	var new_state: GridEntityState = get_active_state()
	var new_token: CharacterToken = get_active_token()
	if new_state:
		new_state.select()
	if new_token:
		new_token.set_selected_visual(true)
		PartyManager.set_active_character(selected_token_index)


# ---------------------------------------------------------------------------
# Monster token helpers
# ---------------------------------------------------------------------------

## Spawn monster tokens for a combat encounter.
## Returns an array of {token: MonsterToken, cell: Vector2i, data: MonsterData}.
func spawn_monsters(encounter: CombatEncounterData) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for spawn in encounter.monster_spawns:
		var monster: MonsterData = DataRegistry.get_monster(spawn.monster_id)
		if monster == null:
			push_warning("GridTokenManager: Unknown monster '%s'" % spawn.monster_id)
			continue

		var count: int = spawn.count
		var base_cell: Vector2i = spawn.cell

		for i in count:
			var cell: Vector2i = base_cell + Vector2i(i, 0) if count > 1 else base_cell
			var token := MonsterToken.new()
			token.name = "%s_%d" % [spawn.monster_id, i]
			token.z_index = 2
			_parent.add_child(token)
			token.setup_visual(monster, _floor_layer.map_to_local(cell))
			results.append({token = token, cell = cell, data = monster})
			monster_tokens.append(token)

	return results


## Remove all monster tokens from the grid.
func remove_monsters() -> void:
	for token in monster_tokens:
		if is_instance_valid(token):
			token.queue_free()
	monster_tokens.clear()
