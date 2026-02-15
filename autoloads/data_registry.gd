## Centralized registry for all game data resources.
##
## Registered as an autoload singleton. Scans the data/ directories at startup,
## loads every .tres file, and indexes them by their id field for fast lookup.
extends Node

var _classes: Dictionary = {}
var _species: Dictionary = {}
var _backgrounds: Dictionary = {}
var _feats: Dictionary = {}
var _weapons: Dictionary = {}
var _armor: Dictionary = {}
var _level_progressions: Dictionary = {}
var _items: Dictionary = {}
var _terrains: Dictionary = {}
var _monsters: Dictionary = {}
var _conditions: Dictionary = {}
var _encounters: Dictionary = {}
var _subclasses: Dictionary = {}
var _dialogues: Dictionary = {}
var _quests: Dictionary = {}


func _ready() -> void:
	_scan_directory("res://data/classes", _classes)
	_scan_directory("res://data/species", _species)
	_scan_directory("res://data/backgrounds", _backgrounds)
	_scan_directory("res://data/feats", _feats)
	_scan_directory("res://data/equipment", _items)
	_scan_directory("res://data/tables", _level_progressions)
	_scan_directory("res://data/exploration/terrains", _terrains)
	_scan_directory("res://data/monsters", _monsters)
	_scan_directory("res://data/conditions", _conditions)
	_scan_directory("res://data/encounters", _encounters)
	_scan_directory("res://data/subclasses", _subclasses)
	_scan_directory("res://data/dialogue", _dialogues)
	_scan_directory("res://data/quests", _quests)

	# Split equipment into weapons and armor for convenience.
	for key in _items.keys():
		var res: Resource = _items[key]
		if res is WeaponData:
			_weapons[key] = res
		elif res is ArmorData:
			_armor[key] = res

	print("DataRegistry: loaded %d classes, %d species, %d backgrounds, %d feats, %d weapons, %d armor, %d progressions, %d terrains, %d monsters, %d conditions, %d encounters, %d subclasses, %d dialogues, %d quests" % [
		_classes.size(), _species.size(), _backgrounds.size(), _feats.size(),
		_weapons.size(), _armor.size(), _level_progressions.size(), _terrains.size(),
		_monsters.size(), _conditions.size(), _encounters.size(),
		_subclasses.size(), _dialogues.size(), _quests.size(),
	])


# ---------------------------------------------------------------------------
# Classes
# ---------------------------------------------------------------------------

func get_all_classes() -> Array:
	return _classes.values()

func get_class_data(id: StringName) -> ClassData:
	return _classes.get(id) as ClassData

# ---------------------------------------------------------------------------
# Species
# ---------------------------------------------------------------------------

func get_all_species() -> Array:
	return _species.values()

func get_species(id: StringName) -> SpeciesData:
	return _species.get(id) as SpeciesData

# ---------------------------------------------------------------------------
# Backgrounds
# ---------------------------------------------------------------------------

func get_all_backgrounds() -> Array:
	return _backgrounds.values()

func get_background(id: StringName) -> BackgroundData:
	return _backgrounds.get(id) as BackgroundData

# ---------------------------------------------------------------------------
# Feats
# ---------------------------------------------------------------------------

func get_all_feats() -> Array:
	return _feats.values()

func get_feat(id: StringName) -> FeatData:
	return _feats.get(id) as FeatData

func get_feats_by_category(category: StringName) -> Array:
	var results: Array = []
	for feat in _feats.values():
		if feat.category == category:
			results.append(feat)
	return results

# ---------------------------------------------------------------------------
# Weapons
# ---------------------------------------------------------------------------

func get_all_weapons() -> Array:
	return _weapons.values()

func get_weapon(id: StringName) -> WeaponData:
	return _weapons.get(id) as WeaponData

# ---------------------------------------------------------------------------
# Armor
# ---------------------------------------------------------------------------

func get_all_armor() -> Array:
	return _armor.values()

func get_armor(id: StringName) -> ArmorData:
	return _armor.get(id) as ArmorData

# ---------------------------------------------------------------------------
# Level progressions
# ---------------------------------------------------------------------------

func get_all_level_progressions() -> Array:
	return _level_progressions.values()

func get_level_progression(class_id: StringName) -> LevelProgression:
	return _level_progressions.get(class_id) as LevelProgression

# ---------------------------------------------------------------------------
# Terrains
# ---------------------------------------------------------------------------

func get_all_terrains() -> Array:
	return _terrains.values()

func get_terrain(id: StringName) -> TerrainData:
	return _terrains.get(id) as TerrainData

# ---------------------------------------------------------------------------
# Generic items (all equipment)
# ---------------------------------------------------------------------------

func get_all_items() -> Array:
	return _items.values()

func get_item(id: StringName) -> Resource:
	return _items.get(id)

# ---------------------------------------------------------------------------
# Monsters
# ---------------------------------------------------------------------------

func get_all_monsters() -> Array:
	return _monsters.values()

func get_monster(id: StringName) -> MonsterData:
	return _monsters.get(id) as MonsterData

# ---------------------------------------------------------------------------
# Conditions
# ---------------------------------------------------------------------------

func get_all_conditions() -> Array:
	return _conditions.values()

func get_condition(id: StringName) -> ConditionData:
	return _conditions.get(id) as ConditionData

# ---------------------------------------------------------------------------
# Encounters
# ---------------------------------------------------------------------------

func get_all_encounters() -> Array:
	return _encounters.values()

func get_encounter(id: StringName) -> CombatEncounterData:
	return _encounters.get(id) as CombatEncounterData


# ---------------------------------------------------------------------------
# Subclasses
# ---------------------------------------------------------------------------

func get_all_subclasses() -> Array[SubclassData]:
	var result: Array[SubclassData] = []
	for v in _subclasses.values():
		result.append(v as SubclassData)
	return result

func get_subclass(id: StringName) -> SubclassData:
	return _subclasses.get(id) as SubclassData


# ---------------------------------------------------------------------------
# Dialogues
# ---------------------------------------------------------------------------

func get_all_dialogues() -> Array:
	return _dialogues.values()

func get_dialogue(id: StringName) -> DialogueTree:
	return _dialogues.get(id) as DialogueTree

# ---------------------------------------------------------------------------
# Quests
# ---------------------------------------------------------------------------

func get_all_quests() -> Array:
	return _quests.values()

func get_quest(id: StringName) -> QuestData:
	return _quests.get(id) as QuestData


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _scan_directory(path: String, target: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := path.path_join(file_name)
			var res := load(full_path)
			if res != null:
				var res_id: StringName = _get_resource_id(res)
				if res_id != &"":
					target[res_id] = res
				else:
					push_warning("DataRegistry: resource '%s' has no id field" % full_path)
			else:
				push_warning("DataRegistry: failed to load '%s'" % full_path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _get_resource_id(res: Resource) -> StringName:
	# LevelProgression uses class_id instead of id.
	if res is LevelProgression:
		return res.class_id
	if res.get("id") != null:
		return StringName(res.get("id"))
	return &""
