extends Control

## Level-up dialog shown from the character sheet.
## Shows new features, HP choice (roll vs average), and ASI/feat at appropriate levels.

signal level_up_completed

var character: CharacterData

@onready var title_label: Label = %DialogTitle
@onready var features_label: RichTextLabel = %FeaturesLabel
@onready var hp_average_btn: Button = %HPAverageBtn
@onready var hp_roll_btn: Button = %HPRollBtn
@onready var hp_result_label: Label = %HPResultLabel
@onready var asi_container: VBoxContainer = %ASIContainer
@onready var asi_info_label: Label = %ASIInfoLabel
@onready var confirm_btn: Button = %ConfirmBtn
@onready var cancel_btn: Button = %CancelBtn

var _hp_value: int = 0
var _hp_chosen: bool = false
var _asi_choices: Dictionary = {}
var _asi_spinboxes: Dictionary = {}


func _ready() -> void:
	if character == null:
		push_error("LevelUpDialog: No character set.")
		return

	var new_level: int = character.level + 1
	title_label.text = "Level Up to %d!" % new_level

	# Features.
	var features: Array[ClassFeature] = LevelUpHandler.get_features_at_level(character, new_level)
	var feat_text := "[b]New Features:[/b]\n"
	if features.size() == 0:
		feat_text += "  No new features at this level.\n"
	else:
		for f in features:
			feat_text += "  [b]%s:[/b] %s\n" % [f.name, f.description]
	features_label.text = feat_text

	# HP options.
	var hp_opts: Dictionary = LevelUpHandler.get_hp_options(character)
	hp_average_btn.text = "Take Average (%d)" % hp_opts["average"]
	hp_roll_btn.text = "Roll d%d" % hp_opts["hit_die"]
	hp_average_btn.pressed.connect(_on_hp_average.bind(hp_opts["average"]))
	hp_roll_btn.pressed.connect(_on_hp_roll.bind(hp_opts["hit_die"]))

	# ASI.
	var is_asi_level: bool = LevelUpHandler.level_grants_asi(new_level)
	asi_container.visible = is_asi_level
	if is_asi_level:
		asi_info_label.text = "Increase abilities by 2 total (e.g. +2 to one or +1 to two):"
		for ability in AbilityScores.ABILITIES:
			var row := HBoxContainer.new()
			var lbl := Label.new()
			lbl.text = "%s (%d):" % [String(ability).capitalize(), character.ability_scores.get_score(ability)]
			lbl.custom_minimum_size.x = 140
			row.add_child(lbl)

			var spin := SpinBox.new()
			spin.min_value = 0
			spin.max_value = 2
			spin.value = 0
			spin.value_changed.connect(_on_asi_changed.bind(ability))
			row.add_child(spin)
			_asi_spinboxes[ability] = spin

			asi_container.add_child(row)

	confirm_btn.pressed.connect(_on_confirm)
	cancel_btn.pressed.connect(_on_cancel)
	confirm_btn.disabled = true


func _on_hp_average(avg: int) -> void:
	_hp_value = avg
	_hp_chosen = true
	hp_result_label.text = "HP gain: +%d (+ CON mod applied on confirm)" % avg
	hp_average_btn.disabled = true
	hp_roll_btn.disabled = true
	_check_confirm()


func _on_hp_roll(die: int) -> void:
	_hp_value = randi_range(1, die)
	_hp_chosen = true
	hp_result_label.text = "Rolled: %d (+ CON mod applied on confirm)" % _hp_value
	hp_average_btn.disabled = true
	hp_roll_btn.disabled = true
	_check_confirm()


func _on_asi_changed(_value: float, ability: StringName) -> void:
	_asi_choices[String(ability)] = int(_asi_spinboxes[ability].value)
	# Remove zero entries.
	var keys_to_remove: Array = []
	for key in _asi_choices:
		if _asi_choices[key] == 0:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		_asi_choices.erase(key)
	_check_confirm()


func _check_confirm() -> void:
	if not _hp_chosen:
		confirm_btn.disabled = true
		return

	var is_asi_level: bool = LevelUpHandler.level_grants_asi(character.level + 1)
	if is_asi_level:
		# Must allocate exactly 2 points.
		var total: int = 0
		for key in _asi_choices:
			total += int(_asi_choices[key])
		confirm_btn.disabled = total != 2
	else:
		confirm_btn.disabled = false


func _on_confirm() -> void:
	LevelUpHandler.apply_level_up(character, _hp_value, _asi_choices)
	level_up_completed.emit()
	queue_free()


func _on_cancel() -> void:
	queue_free()
