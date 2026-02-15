extends Control

## Step 1: Class selection.
## Shows a list of classes on the left and details on the right.

var _creator: CharacterCreator
var _classes: Array = []
var _selected_index: int = -1

@onready var class_list: ItemList = %ClassList
@onready var details_label: RichTextLabel = %DetailsLabel


func setup(creator: CharacterCreator) -> void:
	_creator = creator


func _ready() -> void:
	_classes = DataRegistry.get_all_classes()
	_classes.sort_custom(func(a, b): return a.display_name < b.display_name)

	for cls in _classes:
		class_list.add_item(cls.display_name)

	class_list.item_selected.connect(_on_class_selected)

	# Restore previous selection if going back.
	if _creator != null and _creator.chosen_class != null:
		for i in _classes.size():
			if _classes[i].id == _creator.chosen_class.id:
				class_list.select(i)
				_on_class_selected(i)
				break


func _on_class_selected(index: int) -> void:
	_selected_index = index
	var cls: ClassData = _classes[index]

	var text := "[b]%s[/b]\n\n" % cls.display_name
	text += "%s\n\n" % cls.description
	text += "[b]Hit Die:[/b] d%d\n" % cls.hit_die
	text += "[b]Primary Ability:[/b] %s\n" % cls.primary_ability.capitalize()
	text += "[b]Saving Throws:[/b] %s\n" % _join_names(cls.saving_throw_proficiencies)
	text += "[b]Armor:[/b] %s\n" % _join_names(cls.armor_proficiencies)
	text += "[b]Weapons:[/b] %s\n" % _join_names(cls.weapon_proficiencies)
	text += "[b]Skills:[/b] Choose %d from %s\n" % [cls.num_skill_choices, _join_names(cls.skill_choices)]

	if cls.is_spellcaster:
		text += "[b]Spellcasting:[/b] %s\n" % cls.spellcasting_ability.capitalize()

	text += "\n[b]Features (Levels 1-5):[/b]\n"
	for feature in cls.class_features:
		if feature.level <= 5:
			text += "  Level %d — %s: %s\n" % [feature.level, feature.name, feature.description]

	details_label.text = text

	# Notify parent to refresh navigation.
	var parent_screen = get_parent()
	while parent_screen != null and not parent_screen.has_method("refresh_navigation"):
		parent_screen = parent_screen.get_parent()
	if parent_screen != null:
		parent_screen.refresh_navigation()


func _join_names(arr: Array) -> String:
	var names: PackedStringArray = []
	for item in arr:
		names.append(String(item).capitalize())
	if names.is_empty():
		return "None"
	return ", ".join(names)


func is_valid() -> bool:
	return _selected_index >= 0


func apply(creator: CharacterCreator) -> void:
	if _selected_index >= 0:
		creator.set_class(_classes[_selected_index])
