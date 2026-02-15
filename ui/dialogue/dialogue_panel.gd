class_name DialoguePanel
extends CanvasLayer

## Bottom-anchored dialogue panel with speaker name, typewriter text,
## and choice buttons. Connects to DialogueManager signals.

## Speed of the typewriter effect (characters per second).
@export var typewriter_speed: float = 40.0

# Node references (created in _build_ui).
var _panel: PanelContainer
var _speaker_label: Label
var _text_label: RichTextLabel
var _choices_container: VBoxContainer
var _advance_hint: Label

## Whether the typewriter is still animating.
var _is_typing: bool = false

## Tween for the typewriter effect.
var _type_tween: Tween

## Skill check popup instance.
var _skill_popup: Node


func _ready() -> void:
	layer = 20
	_build_ui()
	_hide_panel()

	DialogueManager.node_changed.connect(_on_node_changed)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	DialogueManager.skill_check_resolved.connect(_on_skill_check_resolved)


func _unhandled_input(event: InputEvent) -> void:
	if not DialogueManager.is_active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event as InputEventKey
		if key.keycode == KEY_SPACE or key.keycode == KEY_ENTER:
			if _is_typing:
				_finish_typing()
			else:
				DialogueManager.advance()
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# DialogueManager callbacks
# ---------------------------------------------------------------------------

func _on_node_changed(node: DialogueNode) -> void:
	_show_panel()
	_speaker_label.text = node.speaker
	_text_label.text = node.text
	_start_typewriter()
	_update_choices()


func _on_dialogue_finished() -> void:
	_hide_panel()


func _on_skill_check_resolved(skill: StringName, dc: int, roll_total: int, success: bool) -> void:
	_show_skill_popup(skill, dc, roll_total, success)


# ---------------------------------------------------------------------------
# Typewriter effect
# ---------------------------------------------------------------------------

func _start_typewriter() -> void:
	_is_typing = true
	_text_label.visible_ratio = 0.0
	_advance_hint.visible = false

	var char_count: int = _text_label.text.length()
	if char_count == 0:
		_finish_typing()
		return

	var duration: float = float(char_count) / typewriter_speed

	if _type_tween and _type_tween.is_running():
		_type_tween.kill()

	_type_tween = create_tween()
	_type_tween.tween_property(_text_label, "visible_ratio", 1.0, duration)
	_type_tween.finished.connect(_finish_typing, CONNECT_ONE_SHOT)


func _finish_typing() -> void:
	if _type_tween and _type_tween.is_running():
		_type_tween.kill()
	_text_label.visible_ratio = 1.0
	_is_typing = false

	var choices: Array = DialogueManager.get_visible_choices()
	if choices.is_empty():
		_advance_hint.visible = true
	_show_choice_buttons()


# ---------------------------------------------------------------------------
# Choice buttons
# ---------------------------------------------------------------------------

func _update_choices() -> void:
	# Clear old buttons.
	for child in _choices_container.get_children():
		child.queue_free()
	_choices_container.visible = false


func _show_choice_buttons() -> void:
	var choices: Array = DialogueManager.get_visible_choices()
	if choices.is_empty():
		return

	_advance_hint.visible = false
	_choices_container.visible = true

	for i in choices.size():
		var choice: DialogueChoice = choices[i]
		var btn := Button.new()

		var label_text: String = choice.text

		# Append skill check info if present.
		for cond in choice.conditions:
			if cond.type == &"skill_check":
				var skill_name: String = str(cond.skill).capitalize()
				label_text += " [%s DC %d]" % [skill_name, cond.dc]

		# Gray out if non-skill conditions fail.
		var selectable: bool = true
		for cond in choice.conditions:
			if cond.type != &"skill_check":
				if not DialogueManager.evaluate_condition(cond):
					selectable = false
					break

		btn.text = label_text
		btn.disabled = not selectable
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var choice_index: int = i
		btn.pressed.connect(func() -> void:
			DialogueManager.select_choice(choice_index)
		)

		_choices_container.add_child(btn)


# ---------------------------------------------------------------------------
# Skill check popup
# ---------------------------------------------------------------------------

func _show_skill_popup(skill: StringName, dc: int, roll_total: int, success: bool) -> void:
	if _skill_popup and is_instance_valid(_skill_popup):
		_skill_popup.queue_free()

	var popup := SkillCheckPopup.new()
	add_child(popup)
	popup.show_result(skill, dc, roll_total, success)
	_skill_popup = popup


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Root panel anchored to bottom of screen.
	_panel = PanelContainer.new()
	_panel.name = "DialoguePanel"
	_panel.anchor_left = 0.05
	_panel.anchor_right = 0.95
	_panel.anchor_top = 0.65
	_panel.anchor_bottom = 0.95
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0

	_panel.add_theme_stylebox_override("panel", UIStyler.create_panel_style(
		UITheme.COLOR_PANEL_BG, UITheme.COLOR_BORDER, 2, 6, 12))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	# Speaker name.
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", UITheme.FONT_MEDIUM)
	_speaker_label.add_theme_color_override("font_color", UITheme.COLOR_TITLE)
	vbox.add_child(_speaker_label)

	# Dialogue text.
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("normal_font_size", UITheme.FONT_SMALL)
	vbox.add_child(_text_label)

	# Choices container.
	_choices_container = VBoxContainer.new()
	_choices_container.add_theme_constant_override("separation", 4)
	_choices_container.visible = false
	vbox.add_child(_choices_container)

	# Advance hint.
	_advance_hint = Label.new()
	_advance_hint.text = "[Space / Enter to continue]"
	_advance_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_advance_hint.add_theme_font_size_override("font_size", UITheme.FONT_TINY)
	_advance_hint.add_theme_color_override("font_color", UITheme.COLOR_HINT_TEXT)
	_advance_hint.visible = false
	vbox.add_child(_advance_hint)

	add_child(_panel)


func _show_panel() -> void:
	_panel.visible = true


func _hide_panel() -> void:
	_panel.visible = false
	_choices_container.visible = false
	_advance_hint.visible = false
