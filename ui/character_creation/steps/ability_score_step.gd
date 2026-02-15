extends Control

## Step 4: Ability score assignment.
## Supports Standard Array, Point Buy, and Roll 4d6 drop lowest.

var _creator: CharacterCreator
var _scores: AbilityScores
var _method: CharacterCreator.ScoreMethod = CharacterCreator.ScoreMethod.STANDARD_ARRAY
var _available_values: Array[int] = []

@onready var method_buttons: HBoxContainer = %MethodButtons
@onready var standard_btn: Button = %StandardArrayBtn
@onready var point_buy_btn: Button = %PointBuyBtn
@onready var roll_btn: Button = %RollBtn
@onready var score_grid: GridContainer = %ScoreGrid
@onready var info_label: Label = %InfoLabel

var _spinboxes: Dictionary = {}  # ability_name -> SpinBox


func setup(creator: CharacterCreator) -> void:
	_creator = creator


func _ready() -> void:
	_scores = AbilityScores.new()

	standard_btn.pressed.connect(_on_standard_array)
	point_buy_btn.pressed.connect(_on_point_buy)
	roll_btn.pressed.connect(_on_roll)

	# Build score assignment grid.
	score_grid.columns = 3
	for ability in AbilityScores.ABILITIES:
		var lbl := Label.new()
		lbl.text = String(ability).capitalize()
		lbl.custom_minimum_size.x = 120
		score_grid.add_child(lbl)

		var spin := SpinBox.new()
		spin.min_value = 3
		spin.max_value = 20
		spin.value = 10
		spin.custom_minimum_size.x = 80
		spin.value_changed.connect(_on_score_changed.bind(ability))
		score_grid.add_child(spin)
		_spinboxes[ability] = spin

		var mod_label := Label.new()
		mod_label.name = "Mod_" + String(ability)
		mod_label.text = "+0"
		mod_label.custom_minimum_size.x = 40
		score_grid.add_child(mod_label)

	# Restore previous scores if going back.
	if _creator != null and _creator.ability_scores != null:
		_scores = _creator.ability_scores
		for ability in AbilityScores.ABILITIES:
			_spinboxes[ability].value = _scores.get_score(ability)
		_method = _creator.score_method
	else:
		_on_standard_array()

	_update_modifiers()


func _on_standard_array() -> void:
	_method = CharacterCreator.ScoreMethod.STANDARD_ARRAY
	_available_values = _creator.get_standard_array()
	info_label.text = "Standard Array: Assign values %s to your abilities." % str(_available_values)

	# Set spinboxes to standard array mode — constrain to available values.
	var sorted_abilities := AbilityScores.ABILITIES.duplicate()
	for i in sorted_abilities.size():
		var val: int = _available_values[i] if i < _available_values.size() else 10
		_spinboxes[sorted_abilities[i]].value = val
		_scores.set_score(sorted_abilities[i], val)
	_update_modifiers()
	_refresh_parent()


func _on_point_buy() -> void:
	_method = CharacterCreator.ScoreMethod.POINT_BUY
	for ability in AbilityScores.ABILITIES:
		_spinboxes[ability].min_value = CharacterCreator.POINT_BUY_MIN
		_spinboxes[ability].max_value = CharacterCreator.POINT_BUY_MAX
		_spinboxes[ability].value = 8
		_scores.set_score(ability, 8)
	_update_point_buy_info()
	_update_modifiers()
	_refresh_parent()


func _on_roll() -> void:
	_method = CharacterCreator.ScoreMethod.ROLL
	var rolled: Array[int] = _creator.roll_all_stats()
	rolled.sort()
	rolled.reverse()  # Highest first.
	info_label.text = "Rolled: %s — Assign to your abilities." % str(rolled)

	var sorted_abilities := AbilityScores.ABILITIES.duplicate()
	for i in sorted_abilities.size():
		var val: int = rolled[i] if i < rolled.size() else 10
		_spinboxes[sorted_abilities[i]].min_value = 3
		_spinboxes[sorted_abilities[i]].max_value = 18
		_spinboxes[sorted_abilities[i]].value = val
		_scores.set_score(sorted_abilities[i], val)
	_update_modifiers()
	_refresh_parent()


func _on_score_changed(value: float, ability: StringName) -> void:
	_scores.set_score(ability, int(value))
	_update_modifiers()
	if _method == CharacterCreator.ScoreMethod.POINT_BUY:
		_update_point_buy_info()
	_refresh_parent()


func _update_modifiers() -> void:
	for ability in AbilityScores.ABILITIES:
		var mod: int = _scores.get_modifier(ability)
		var mod_label: Label = score_grid.find_child("Mod_" + String(ability), true, false)
		if mod_label != null:
			mod_label.text = "%+d" % mod


func _update_point_buy_info() -> void:
	var cost: int = _creator.calculate_point_buy_cost(_scores)
	var remaining: int = CharacterCreator.POINT_BUY_BUDGET - cost
	info_label.text = "Point Buy: %d / %d points spent (%d remaining)" % [cost, CharacterCreator.POINT_BUY_BUDGET, remaining]


func _refresh_parent() -> void:
	var parent_screen = get_parent()
	while parent_screen != null and not parent_screen.has_method("refresh_navigation"):
		parent_screen = parent_screen.get_parent()
	if parent_screen != null:
		parent_screen.refresh_navigation()


func is_valid() -> bool:
	if _method == CharacterCreator.ScoreMethod.POINT_BUY:
		return _creator.is_point_buy_valid(_scores)
	return true


func apply(creator: CharacterCreator) -> void:
	creator.set_ability_scores(_scores)
	creator.score_method = _method
