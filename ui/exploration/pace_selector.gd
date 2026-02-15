extends PanelContainer

## UI widget for selecting travel pace (Slow / Normal / Fast).
##
## Shows current pace, speed, and modifier information. Emits pace_changed
## when the player selects a new pace.

signal pace_changed(pace: int)

@onready var slow_button: Button = %SlowButton
@onready var normal_button: Button = %NormalButton
@onready var fast_button: Button = %FastButton
@onready var modifiers_label: Label = %ModifiersLabel

var _travel_system: OverworldTravelSystem


func setup(travel_system: OverworldTravelSystem) -> void:
	_travel_system = travel_system
	_update_display()


func _ready() -> void:
	slow_button.pressed.connect(func() -> void: _set_pace(OverworldTravelSystem.TravelPace.SLOW))
	normal_button.pressed.connect(func() -> void: _set_pace(OverworldTravelSystem.TravelPace.NORMAL))
	fast_button.pressed.connect(func() -> void: _set_pace(OverworldTravelSystem.TravelPace.FAST))


func _set_pace(pace: OverworldTravelSystem.TravelPace) -> void:
	if _travel_system == null:
		return
	_travel_system.set_pace(pace)
	_update_display()
	pace_changed.emit(pace)


func _update_display() -> void:
	if _travel_system == null:
		return

	# Update button states.
	var current: OverworldTravelSystem.TravelPace = _travel_system.current_pace
	slow_button.button_pressed = current == OverworldTravelSystem.TravelPace.SLOW
	normal_button.button_pressed = current == OverworldTravelSystem.TravelPace.NORMAL
	fast_button.button_pressed = current == OverworldTravelSystem.TravelPace.FAST

	# Update modifiers display.
	var mods: Dictionary = _travel_system.get_pace_modifiers()
	var text: String = "%s - %d mph" % [_travel_system.get_pace_name(), roundi(mods["speed_mph"])]

	if mods["stealth_allowed"]:
		text += "\nCan use Stealth"
	var penalty: int = mods["perception_penalty"] as int
	if penalty != 0:
		text += "\nPassive Perception %d" % penalty

	modifiers_label.text = text
