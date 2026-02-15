class_name StepIndicator
extends HBoxContainer

## Displays the step progress for character creation.
## Shows numbered step labels with the current step highlighted.

const STEP_NAMES: Array[String] = [
	"Class", "Species", "Background", "Abilities", "Skills", "Equipment", "Review",
]

var _labels: Array[Label] = []
var _current_step: int = 0


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	for i in STEP_NAMES.size():
		if i > 0:
			var sep := Label.new()
			sep.text = ">"
			sep.add_theme_color_override("font_color", UITheme.COLOR_STEP_FUTURE)
			add_child(sep)

		var lbl := Label.new()
		lbl.text = "%d. %s" % [i + 1, STEP_NAMES[i]]
		lbl.add_theme_color_override("font_color", UITheme.COLOR_STEP_FUTURE)
		add_child(lbl)
		_labels.append(lbl)

	set_current_step(0)


func set_current_step(step: int) -> void:
	_current_step = step
	for i in _labels.size():
		if i < step:
			_labels[i].add_theme_color_override("font_color", UITheme.COLOR_STEP_COMPLETE)  # Completed
		elif i == step:
			_labels[i].add_theme_color_override("font_color", UITheme.COLOR_STEP_CURRENT)  # Current
		else:
			_labels[i].add_theme_color_override("font_color", UITheme.COLOR_STEP_FUTURE)  # Future
