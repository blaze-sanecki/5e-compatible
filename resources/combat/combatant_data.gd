class_name CombatantData
extends RefCounted

## Per-encounter wrapper around CharacterData or MonsterData.
##
## Provides a uniform interface for the combat system regardless of whether
## the underlying data is a player character or a monster. Stores mutable
## per-encounter state (initiative roll, action economy, per-instance HP for
## monsters) without polluting the data resources.

enum CombatantType { PLAYER, MONSTER }

## The underlying data resource.
var source: Resource

## Whether this is a player character or a monster.
var type: CombatantType

## Display name for UI.
var display_name: String

## Per-encounter hit points (monsters get their own copy; players use CharacterData directly).
var current_hp: int = 0
var max_hp: int = 0
var temp_hp: int = 0

## Initiative roll result.
var initiative: int = 0

## Grid position (synced with token).
var cell: Vector2i = Vector2i.ZERO

## Movement remaining this turn (in feet).
var movement_remaining: int = 0

## Action economy for the current turn.
var has_action: bool = true
var has_bonus_action: bool = true
var has_reaction: bool = true
var has_moved: bool = false

## Number of attacks allowed (Extra Attack).
var attacks_remaining: int = 1

## Active conditions on this combatant.
var conditions: Array[StringName] = []

## Whether this combatant is concentrating on a spell.
var is_concentrating: bool = false
var concentration_spell: Resource = null

## Death save tracking (players only).
var death_save_successes: int = 0
var death_save_failures: int = 0

## Whether this combatant has been defeated.
var is_dead: bool = false

## Whether this combatant used the Dodge action this turn.
var is_dodging: bool = false

## Whether this combatant used the Disengage action this turn.
var is_disengaging: bool = false

## Whether this combatant used the Hide action this turn.
var is_hidden: bool = false

## Reference to the visual token on the grid.
var token: Node2D = null

## Unique instance id (for multiple copies of same monster).
var instance_id: int = 0

## Static counter for generating unique instance IDs.
static var _next_id: int = 1


# ---------------------------------------------------------------------------
# Construction
# ---------------------------------------------------------------------------

static func from_character(character: CharacterData) -> CombatantData:
	var c := CombatantData.new()
	c.source = character
	c.type = CombatantType.PLAYER
	c.display_name = character.character_name
	c.current_hp = character.current_hp
	c.max_hp = character.max_hp
	c.temp_hp = character.temp_hp
	c.movement_remaining = character.speed
	c.death_save_successes = character.death_save_successes
	c.death_save_failures = character.death_save_failures
	c.instance_id = _next_id
	_next_id += 1

	# Check for Extra Attack
	if character.character_class != null:
		c.attacks_remaining = _get_attack_count(character)

	# Copy existing conditions
	for cond in character.conditions:
		c.conditions.append(cond)

	# Track concentration
	if character.concentration_spell != null:
		c.is_concentrating = true
		c.concentration_spell = character.concentration_spell

	return c


static func from_monster(monster: MonsterData) -> CombatantData:
	var c := CombatantData.new()
	c.source = monster
	c.type = CombatantType.MONSTER
	c.display_name = monster.display_name
	c.current_hp = monster.hit_points
	c.max_hp = monster.hit_points
	c.movement_remaining = monster.speed.get("walk", 30) as int
	c.instance_id = _next_id
	_next_id += 1
	return c


# ---------------------------------------------------------------------------
# Uniform interface
# ---------------------------------------------------------------------------

func is_player() -> bool:
	return type == CombatantType.PLAYER


func is_monster() -> bool:
	return type == CombatantType.MONSTER


func get_modifier(ability: StringName) -> int:
	if is_player():
		return (source as CharacterData).get_modifier(ability)
	return (source as MonsterData).get_modifier(ability)


func get_ac() -> int:
	if is_player():
		return RulesEngine.calculate_ac(source as CharacterData)
	return (source as MonsterData).armor_class


func get_speed() -> int:
	if is_player():
		return (source as CharacterData).speed
	return (source as MonsterData).speed.get("walk", 30) as int


func get_level() -> int:
	if is_player():
		return (source as CharacterData).level
	return 1


func get_proficiency_bonus() -> int:
	if is_player():
		return RulesEngine.get_proficiency_bonus(get_level())
	return (source as MonsterData).proficiency_bonus


## Reset action economy for a new turn.
func start_turn() -> void:
	has_action = true
	has_bonus_action = true
	has_reaction = true
	has_moved = false
	is_dodging = false
	is_disengaging = false
	is_hidden = false
	movement_remaining = get_speed()

	# Check speed-reducing conditions
	for cond_id in conditions:
		var cond_data: ConditionData = DataRegistry.get_condition(cond_id)
		if cond_data:
			for effect in cond_data.effects:
				if effect.type == "speed" and effect.value == 0:
					movement_remaining = 0
				elif effect.type == "incapacitated":
					has_action = false
					has_bonus_action = false

	# Extra Attack resets
	if is_player():
		attacks_remaining = _get_attack_count(source as CharacterData)
	else:
		attacks_remaining = 1


## Sync HP back to the source resource (for players).
func sync_to_source() -> void:
	if is_player():
		var char_data: CharacterData = source as CharacterData
		char_data.current_hp = current_hp
		char_data.temp_hp = temp_hp
		char_data.death_save_successes = death_save_successes
		char_data.death_save_failures = death_save_failures


func is_alive() -> bool:
	return not is_dead and current_hp > 0


func is_unconscious() -> bool:
	return current_hp <= 0 and not is_dead and is_player()


func has_condition(condition_id: StringName) -> bool:
	return condition_id in conditions


func get_initiative_modifier() -> int:
	if is_player():
		return RulesEngine.calculate_initiative(source as CharacterData)
	return get_modifier(&"dexterity")


## Get the best melee action for monsters, or equipped weapon for players.
func get_primary_weapon() -> Variant:
	if is_player():
		var char_data: CharacterData = source as CharacterData
		if not char_data.equipped_weapons.is_empty():
			return char_data.equipped_weapons[0]
		return null
	var monster: MonsterData = source as MonsterData
	for action in monster.actions:
		if action.type == &"melee_attack":
			return action
	return null


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

static func _get_attack_count(character: CharacterData) -> int:
	var class_data: ClassData = character.character_class
	if class_data == null:
		return 1
	for feature in class_data.class_features:
		if feature.name == "Extra Attack" and character.level >= feature.level:
			return 2
	return 1
