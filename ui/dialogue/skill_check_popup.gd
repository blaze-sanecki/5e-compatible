class_name SkillCheckPopup
extends CanvasLayer

## Brief popup showing the result of a dialogue skill check.
## Auto-dismisses after 2 seconds.

var _panel: PanelContainer
var _label: Label
var _dismiss_timer: Timer


func _ready() -> void:
	layer = 25
	# UI is built here so it's ready before show_result() is called.
	_build_ui()


## Display the skill check result. Safe to call right after add_child().
func show_result(skill: StringName, dc: int, roll_total: int, success: bool) -> void:
	# Ensure UI exists even if _ready hasn't fired yet.
	if _panel == null:
		_build_ui()

	var skill_name: String = str(skill).capitalize()
	var result_text: String = "Success!" if success else "Failure!"

	_label.text = "%s Check: %d vs DC %d — %s" % [skill_name, roll_total, dc, result_text]
	_label.add_theme_color_override("font_color", Color.LIME_GREEN if success else Color.INDIAN_RED)

	_panel.visible = true

	# Auto-dismiss after 2 seconds. Timer must be deferred until in tree.
	_start_dismiss_timer.call_deferred()


func _start_dismiss_timer() -> void:
	_dismiss_timer = Timer.new()
	_dismiss_timer.wait_time = 2.0
	_dismiss_timer.one_shot = true
	_dismiss_timer.timeout.connect(_dismiss)
	add_child(_dismiss_timer)
	_dismiss_timer.start()


func _dismiss() -> void:
	queue_free()


func _build_ui() -> void:
	if _panel != null:
		return

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.25
	_panel.anchor_right = 0.75
	_panel.anchor_top = 0.4
	_panel.anchor_bottom = 0.5
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.2, 0.95)
	style.border_color = Color(0.7, 0.6, 0.3, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", style)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	_panel.add_child(_label)

	_panel.visible = false
	add_child(_panel)
