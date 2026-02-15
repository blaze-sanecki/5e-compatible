## Game state management singleton.
##
## Registered as an autoload. Tracks the high-level game state (exploring,
## combat, dialogue, etc.), manages the in-game clock, and orchestrates
## map transitions and rest mechanics.
extends Node

# ===========================================================================
# Game states
# ===========================================================================

enum GameState {
	MAIN_MENU,
	EXPLORING,
	COMBAT,
	DIALOGUE,
	INVENTORY,
	CHARACTER_SHEET,
	PAUSED,
	LOADING,
	SAVING,
	CHARACTER_CREATION,
}

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU

signal state_changed(old_state: GameState, new_state: GameState)

# ===========================================================================
# In-game clock
# ===========================================================================

## Tracks the in-game calendar / time of day.
var game_time: Dictionary = {
	"day": 1,
	"hour": 8,
	"minute": 0,
}

# ===========================================================================
# State management
# ===========================================================================

## Transition to a new game state, storing the previous one.
func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return
	previous_state = current_state
	current_state = new_state
	state_changed.emit(previous_state, current_state)


## Convenience: is the game currently in combat?
func is_in_combat() -> bool:
	return current_state == GameState.COMBAT


## Convenience: is the player exploring?
func is_exploring() -> bool:
	return current_state == GameState.EXPLORING


## Pause the game (stores previous state so it can be restored).
func pause_game() -> void:
	if current_state != GameState.PAUSED:
		change_state(GameState.PAUSED)
		get_tree().paused = true


## Unpause the game (restores the state that was active before pausing).
func unpause_game() -> void:
	if current_state == GameState.PAUSED:
		get_tree().paused = false
		var old := current_state
		current_state = previous_state
		previous_state = old
		state_changed.emit(old, current_state)


# ===========================================================================
# Map / scene management
# ===========================================================================

## Load a new map scene by file path.
##
## Emits [code]EventBus.map_transition[/code] with the old and new paths.
func load_map(map_path: String) -> void:
	var current_scene := get_tree().current_scene
	var from_map := current_scene.scene_file_path if current_scene else ""

	change_state(GameState.LOADING)
	EventBus.map_transition.emit(from_map, map_path)

	var err := get_tree().change_scene_to_file(map_path)
	if err != OK:
		push_error("GameManager: Failed to load map '%s' (error %d)." % [map_path, err])
		return

	# Defer returning to the exploring state so the new scene has a frame to
	# initialise.
	await get_tree().process_frame
	change_state(GameState.EXPLORING)


# ===========================================================================
# In-game time
# ===========================================================================

## Advance the in-game clock by the given number of minutes.
##
## Handles hour and day rollovers automatically.
func advance_time(minutes: int) -> void:
	game_time["minute"] += minutes

	# Roll over minutes -> hours.
	while game_time["minute"] >= 60:
		game_time["minute"] -= 60
		game_time["hour"] += 1

	# Roll over hours -> days.
	while game_time["hour"] >= 24:
		game_time["hour"] -= 24
		game_time["day"] += 1


## Return the current time as a human-readable string (e.g. "Day 3, 14:30").
func get_time_string() -> String:
	return "Day %d, %02d:%02d" % [game_time["day"], game_time["hour"], game_time["minute"]]


# ===========================================================================
# Resting
# ===========================================================================

## Initiate a short rest (1 hour of in-game time).
##
## Characters may spend Hit Dice to recover HP. The actual healing logic lives
## on the character resources; this method orchestrates the flow and emits the
## appropriate signals.
func short_rest() -> void:
	EventBus.rest_started.emit(&"short")
	advance_time(60)

	for member in PartyManager.party:
		if member is CharacterData:
			RestSystem.short_rest(member as CharacterData)

	EventBus.rest_completed.emit(&"short")


## Initiate a long rest (8 hours of in-game time).
##
## Restores HP to maximum, resets spent spell slots, and recovers up to half
## of the character's total Hit Dice (minimum 1).
func long_rest() -> void:
	EventBus.rest_started.emit(&"long")
	advance_time(480)

	for member in PartyManager.party:
		if member is CharacterData:
			RestSystem.long_rest(member as CharacterData)

	EventBus.rest_completed.emit(&"long")
