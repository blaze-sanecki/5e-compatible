extends Control

## Step 6: Equipment selection.
## Offers a "Accept Default Equipment" button showing class-specific defaults.

var _creator: CharacterCreator
var _accepted: bool = false

@onready var accept_button: Button = %AcceptButton
@onready var equipment_label: RichTextLabel = %EquipmentLabel


func setup(creator: CharacterCreator) -> void:
	_creator = creator


func _ready() -> void:
	accept_button.pressed.connect(_on_accept)

	if _creator == null:
		return

	var defaults: Array[StringName] = _creator.get_default_equipment()
	var text := "[b]Default Equipment for %s:[/b]\n\n" % _creator.chosen_class.display_name

	for item_id in defaults:
		var item: Resource = DataRegistry.get_item(item_id)
		if item != null:
			text += "  - %s\n" % item.display_name
		else:
			text += "  - %s\n" % String(item_id).capitalize().replace("_", " ")

	text += "\n[b]Starting Gold:[/b] %d gp (from background)\n" % (_creator.chosen_background.starting_gold if _creator.chosen_background != null else 0)

	equipment_label.text = text

	# Restore state if going back.
	if _creator.chosen_equipment_ids.size() > 0:
		_accepted = true
		accept_button.text = "Equipment Accepted"
		accept_button.disabled = true


func _on_accept() -> void:
	_accepted = true
	accept_button.text = "Equipment Accepted"
	accept_button.disabled = true
	_refresh_parent()


func _refresh_parent() -> void:
	var parent_screen = get_parent()
	while parent_screen != null and not parent_screen.has_method("refresh_navigation"):
		parent_screen = parent_screen.get_parent()
	if parent_screen != null:
		parent_screen.refresh_navigation()


func is_valid() -> bool:
	return _accepted


func apply(creator: CharacterCreator) -> void:
	creator.set_equipment(creator.get_default_equipment())
