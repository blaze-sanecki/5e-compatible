extends Control

## Full-screen character creation wizard.
## Manages step navigation, loads step panels dynamically, and finalizes
## the character via CharacterCreator.

const STEP_SCENES: Array[String] = [
	"res://ui/character_creation/steps/class_step.tscn",
	"res://ui/character_creation/steps/species_step.tscn",
	"res://ui/character_creation/steps/background_step.tscn",
	"res://ui/character_creation/steps/ability_score_step.tscn",
	"res://ui/character_creation/steps/skill_step.tscn",
	"res://ui/character_creation/steps/equipment_step.tscn",
	"res://ui/character_creation/steps/review_step.tscn",
]

var creator: CharacterCreator
var current_step: int = 0
var step_instance: Control

@onready var step_indicator: StepIndicator = %StepIndicator
@onready var step_container: PanelContainer = %StepContainer
@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton
@onready var title_label: Label = %TitleLabel


func _ready() -> void:
	creator = CharacterCreator.new()
	GameManager.change_state(GameManager.GameState.CHARACTER_CREATION)

	back_button.pressed.connect(_on_back_pressed)
	next_button.pressed.connect(_on_next_pressed)

	_load_step(0)


func _load_step(step: int) -> void:
	current_step = step
	step_indicator.set_current_step(step)

	# Remove old step content.
	if step_instance != null:
		step_instance.queue_free()
		step_instance = null

	# Load new step scene.
	var scene: PackedScene = load(STEP_SCENES[step])
	step_instance = scene.instantiate() as Control
	step_instance.setup(creator)
	step_container.add_child(step_instance)

	_update_buttons()


func _update_buttons() -> void:
	back_button.visible = current_step > 0
	var is_last: bool = current_step == STEP_SCENES.size() - 1
	next_button.text = "Finish" if is_last else "Next"

	# Enable/disable next based on step validity.
	if step_instance != null and step_instance.has_method("is_valid"):
		next_button.disabled = not step_instance.is_valid()
	else:
		next_button.disabled = false


func _on_back_pressed() -> void:
	if current_step > 0:
		_load_step(current_step - 1)


func _on_next_pressed() -> void:
	# Apply current step's choices to the creator.
	if step_instance != null and step_instance.has_method("apply"):
		step_instance.apply(creator)

	if current_step < STEP_SCENES.size() - 1:
		_load_step(current_step + 1)
	else:
		_finish_creation()


func _finish_creation() -> void:
	var character: CharacterData = creator.finalize()
	if character == null:
		push_error("CharacterCreationScreen: Failed to finalize character.")
		return

	PartyManager.add_member(character)
	# State transition handled by the parent (main menu listens for tree_exiting
	# and triggers TransitionManager, which sets EXPLORING via GameManager.load_map).
	queue_free()


## Called by step panels to refresh the Next button state.
func refresh_navigation() -> void:
	_update_buttons()
