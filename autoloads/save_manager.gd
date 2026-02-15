## Save/load game state to JSON files in user://saves/.
##
## Registered as an autoload singleton. Delegates party and quest
## serialization to PartySerializer and QuestSerializer.
extends Node

const SAVE_DIR: String = "user://saves/"
const SAVE_VERSION: int = 1
const MAX_SLOTS: int = 3

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Save the current game state to the given slot (0-2).
## Returns true on success.
func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("SaveManager: Invalid slot %d" % slot)
		return false

	var data: Dictionary = _serialize_game_state()
	if data.is_empty():
		push_error("SaveManager: Failed to serialize game state")
		return false

	_ensure_save_dir()
	var path: String = _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Cannot open '%s' for writing (error %d)" % [path, FileAccess.get_open_error()])
		return false

	var json_str: String = JSON.stringify(data, "\t")
	file.store_string(json_str)
	file.close()

	EventBus.game_saved.emit(slot)
	print("SaveManager: Game saved to slot %d" % slot)
	return true


## Load a game from the given slot (0-2).
## Returns true on success.
func load_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("SaveManager: Invalid slot %d" % slot)
		return false

	var path: String = _slot_path(slot)
	if not FileAccess.file_exists(path):
		push_error("SaveManager: No save at slot %d" % slot)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Cannot open '%s' for reading" % path)
		return false

	var json_str: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err: int = json.parse(json_str)
	if err != OK:
		push_error("SaveManager: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return false

	var data: Dictionary = json.data
	if data.get("version", 0) != SAVE_VERSION:
		push_warning("SaveManager: Save version mismatch (expected %d, got %s)" % [SAVE_VERSION, data.get("version", "?")])

	_deserialize_game_state(data)
	EventBus.game_loaded.emit(slot)
	print("SaveManager: Game loaded from slot %d" % slot)
	return true


## Get metadata about a save slot for UI display.
## Returns an empty Dictionary if no save exists.
func get_save_info(slot: int) -> Dictionary:
	var path: String = _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var json_str: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_str) != OK:
		return {}

	var data: Dictionary = json.data
	return {
		"character_name": data.get("character_name", "Unknown"),
		"level": data.get("party", [{}])[0].get("level", 1) if not data.get("party", []).is_empty() else 1,
		"save_date": data.get("save_date", ""),
		"game_time": data.get("game_time", {}),
		"current_map": data.get("current_map", ""),
	}


## Whether a save exists in the given slot.
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


## Delete the save in the given slot.
func delete_save(slot: int) -> void:
	var path: String = _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("SaveManager: Deleted save at slot %d" % slot)


## Get the most recently modified save slot, or -1 if no saves exist.
func get_most_recent_slot() -> int:
	var best_slot: int = -1
	var best_time: int = 0
	for i in MAX_SLOTS:
		var path: String = _slot_path(i)
		if FileAccess.file_exists(path):
			var mod_time: int = FileAccess.get_modified_time(path)
			if mod_time > best_time:
				best_time = mod_time
				best_slot = i
	return best_slot


## Whether any save exists across all slots.
func has_any_save() -> bool:
	for i in MAX_SLOTS:
		if has_save(i):
			return true
	return false


# ---------------------------------------------------------------------------
# Serialization (orchestration)
# ---------------------------------------------------------------------------

func _serialize_game_state() -> Dictionary:
	var current_scene: Node = get_tree().current_scene
	var map_path: String = current_scene.scene_file_path if current_scene else ""

	var char_name: String = ""
	if not PartyManager.party.is_empty():
		var first: Resource = PartyManager.party[0]
		char_name = first.character_name if first.get("character_name") else ""

	return {
		"version": SAVE_VERSION,
		"save_date": Time.get_datetime_string_from_system(),
		"character_name": char_name,
		"game_time": GameManager.game_time.duplicate(),
		"current_map": map_path,
		"active_character_index": PartyManager.active_character_index,
		"party": PartySerializer.serialize(PartyManager.party),
		"quests": QuestSerializer.serialize(),
		"exploration": _serialize_exploration(current_scene),
	}


func _deserialize_game_state(data: Dictionary) -> void:
	# Restore game time.
	var time_data: Dictionary = data.get("game_time", {})
	GameManager.game_time["day"] = int(time_data.get("day", 1))
	GameManager.game_time["hour"] = int(time_data.get("hour", 8))
	GameManager.game_time["minute"] = int(time_data.get("minute", 0))

	# Restore party and quests via serializers.
	PartySerializer.deserialize(data.get("party", []))
	PartyManager.active_character_index = int(data.get("active_character_index", 0))
	QuestSerializer.deserialize(data.get("quests", {}))

	# Transition to the saved map, then restore exploration state.
	var map_path: String = data.get("current_map", "")
	if map_path.is_empty():
		return

	var exploration_data: Dictionary = data.get("exploration", {})
	_load_map_and_restore(map_path, exploration_data)


# ---------------------------------------------------------------------------
# Exploration state serialization
# ---------------------------------------------------------------------------

func _serialize_exploration(scene: Node) -> Dictionary:
	if scene is GridDungeonController:
		return (scene as GridDungeonController).get_save_state()
	elif scene is HexOverworldController:
		return (scene as HexOverworldController).get_save_state()
	return {}


# ---------------------------------------------------------------------------
# Map loading and state restoration
# ---------------------------------------------------------------------------

func _load_map_and_restore(map_path: String, exploration_data: Dictionary) -> void:
	# Manually control the transition so we can restore positions while the
	# screen is still black (before fade-in), preventing the visible snap.
	TransitionManager.is_transitioning = true
	await TransitionManager._fade_out()
	await TransitionManager._load_and_spawn(map_path)

	# Restore positions, fog, and interactable state.
	var new_scene: Node = get_tree().current_scene
	if new_scene and new_scene.has_method("restore_save_state"):
		new_scene.restore_save_state(exploration_data)

	# Wait a frame so token transforms fully settle, then force-snap the
	# camera before the fade reveals the scene.
	await get_tree().process_frame
	if new_scene and new_scene.has_method("snap_camera"):
		new_scene.snap_camera()

	await TransitionManager._fade_in()
	TransitionManager.is_transitioning = false


# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
