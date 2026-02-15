class_name OverworldTravelSystem
extends RefCounted

## Manages overworld travel pace, time advancement, and encounter checks.
##
## SRD travel rates (per hour): Slow 2mi, Normal 3mi, Fast 4mi.
## Each hex represents roughly 1 mile of travel.

# ---------------------------------------------------------------------------
# Travel pace
# ---------------------------------------------------------------------------

enum TravelPace { SLOW, NORMAL, FAST }

## Miles per hour by pace.
const PACE_SPEED: Dictionary = {
	TravelPace.SLOW: 2.0,
	TravelPace.NORMAL: 3.0,
	TravelPace.FAST: 4.0,
}

## Minutes to cross one hex (1 mile) at each pace.
const PACE_MINUTES_PER_HEX: Dictionary = {
	TravelPace.SLOW: 30,    # 60 / 2
	TravelPace.NORMAL: 20,  # 60 / 3
	TravelPace.FAST: 15,    # 60 / 4
}

## Perception penalty at fast pace (-5 to passive Perception).
const FAST_PACE_PERCEPTION_PENALTY: int = -5

## Stealth bonus at slow pace (can use stealth while traveling).
const SLOW_PACE_STEALTH_ALLOWED: bool = true

## Current travel pace.
var current_pace: TravelPace = TravelPace.NORMAL

## Number of hexes traveled since last encounter check.
var _hexes_since_check: int = 0

## Check for encounters every N hexes.
var encounter_check_interval: int = 3


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Process movement into a new hex. Returns a Dictionary with travel results:
## { "time_minutes": int, "encounter_triggered": bool, "encounter_chance": float }
func process_hex_entered(terrain: TerrainData) -> Dictionary:
	var base_minutes: int = PACE_MINUTES_PER_HEX[current_pace]
	var time_minutes: int = roundi(float(base_minutes) * terrain.movement_cost_multiplier)

	# Advance in-game time.
	GameManager.advance_time(time_minutes)

	_hexes_since_check += 1

	var result: Dictionary = {
		"time_minutes": time_minutes,
		"encounter_triggered": false,
		"encounter_chance": 0.0,
	}

	# Check for encounters at interval.
	if _hexes_since_check >= encounter_check_interval:
		_hexes_since_check = 0
		var chance: float = _calculate_encounter_chance(terrain)
		result["encounter_chance"] = chance
		result["encounter_triggered"] = randf() < chance

	return result


## Set the travel pace.
func set_pace(pace: TravelPace) -> void:
	current_pace = pace


## Get a display string for the current pace.
func get_pace_name() -> String:
	match current_pace:
		TravelPace.SLOW:
			return "Slow"
		TravelPace.NORMAL:
			return "Normal"
		TravelPace.FAST:
			return "Fast"
	return "Normal"


## Get modifiers for the current pace.
func get_pace_modifiers() -> Dictionary:
	var mods: Dictionary = {
		"perception_penalty": 0,
		"stealth_allowed": false,
		"speed_mph": PACE_SPEED[current_pace],
	}
	match current_pace:
		TravelPace.SLOW:
			mods["stealth_allowed"] = true
		TravelPace.FAST:
			mods["perception_penalty"] = FAST_PACE_PERCEPTION_PENALTY
	return mods


## Reset the hex counter (e.g. after loading a map).
func reset_counter() -> void:
	_hexes_since_check = 0


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _calculate_encounter_chance(terrain: TerrainData) -> float:
	var chance: float = terrain.base_encounter_chance

	# Fast pace increases encounter chance (harder to be stealthy).
	if current_pace == TravelPace.FAST:
		chance *= 1.5

	# Slow pace decreases encounter chance (more cautious).
	if current_pace == TravelPace.SLOW:
		chance *= 0.5

	return clampf(chance, 0.0, 1.0)
