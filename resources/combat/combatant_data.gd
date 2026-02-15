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

static func from_character(character: Resource) -> CombatantData:
	var c := CombatantData.new()
	c.source = character
	c.type = CombatantType.PLAYER
	c.display_name = character.character_name if character.get("character_name") else "Player"
	c.current_hp = character.current_hp
	c.max_hp = character.max_hp
	c.temp_hp = character.temp_hp if character.get("temp_hp") else 0
	c.movement_remaining = character.speed if character.get("speed") else 30
	c.death_save_successes = character.death_save_successes if character.get("death_save_successes") else 0
	c.death_save_failures = character.death_save_failures if character.get("death_save_failures") else 0
	c.instance_id = _next_id
	_next_id += 1

	# Check for Extra Attack
	if character.get("character_class") and character.get("level"):
		c.attacks_remaining = _get_attack_count(character)

	# Copy existing conditions
	if character.get("conditions"):
		for cond in character.conditions:
			c.conditions.append(cond)

	# Track concentration
	if character.get("concentration_spell") and character.concentration_spell != null:
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
	if source.has_method("get_modifier"):
		return source.get_modifier(ability)
	return 0


func get_ac() -> int:
	if is_player():
		return RulesEngine.calculate_ac(source)
	return source.armor_class


func get_speed() -> int:
	if is_player():
		return source.speed if source.get("speed") else 30
	return source.speed.get("walk", 30) as int


func get_level() -> int:
	if is_player():
		return source.level if source.get("level") else 1
	# Monsters use CR-derived proficiency
	return 1


func get_proficiency_bonus() -> int:
	if is_player():
		return RulesEngine.get_proficiency_bonus(get_level())
	return source.proficiency_bonus if source.get("proficiency_bonus") else 2


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
		attacks_remaining = _get_attack_count(source)
	else:
		attacks_remaining = 1


## Sync HP back to the source resource (for players).
func sync_to_source() -> void:
	if is_player():
		source.current_hp = current_hp
		source.temp_hp = temp_hp
		source.death_save_successes = death_save_successes
		source.death_save_failures = death_save_failures


func is_alive() -> bool:
	return not is_dead and current_hp > 0


func is_unconscious() -> bool:
	return current_hp <= 0 and not is_dead and is_player()


func has_condition(condition_id: StringName) -> bool:
	return condition_id in conditions


func get_initiative_modifier() -> int:
	if is_player():
		return RulesEngine.calculate_initiative(source)
	return get_modifier(&"dexterity")


## Get the best melee action for monsters, or equipped weapon for players.
func get_primary_weapon() -> Variant:
	if is_player():
		if source.get("equipped_weapons") and not source.equipped_weapons.is_empty():
			return source.equipped_weapons[0]
		return null
	# Monster: return first melee action
	if source.get("actions"):
		for action in source.actions:
			if action.type == &"melee_attack":
				return action
	return null


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

static func _get_attack_count(character: Resource) -> int:
	if character.get("character_class") == null or character.get("level") == null:
		return 1
	var class_data: Resource = character.character_class
	if class_data == null:
		return 1
	# Check class features for Extra Attack
	if class_data.get("class_features"):
		for feature in class_data.class_features:
			if feature.name == "Extra Attack" and character.level >= feature.level:
				return 2
	return 1
