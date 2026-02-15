extends Control

## Step 3: Background selection.
## Shows backgrounds with skills, ability increases, and origin feat details.

var _creator: CharacterCreator
var _backgrounds: Array = []
var _selected_index: int = -1

@onready var bg_list: ItemList = %BackgroundList
@onready var details_label: RichTextLabel = %DetailsLabel


func setup(creator: CharacterCreator) -> void:
	_creator = creator


func _ready() -> void:
	_backgrounds = DataRegistry.get_all_backgrounds()
	_backgrounds.sort_custom(func(a, b): return a.display_name < b.display_name)

	for bg in _backgrounds:
		bg_list.add_item(bg.display_name)

	bg_list.item_selected.connect(_on_bg_selected)

	if _creator != null and _creator.chosen_background != null:
		for i in _backgrounds.size():
			if _backgrounds[i].id == _creator.chosen_background.id:
				bg_list.select(i)
				_on_bg_selected(i)
				break


func _on_bg_selected(index: int) -> void:
	_selected_index = index
	var bg: BackgroundData = _backgrounds[index]

	var text := "[b]%s[/b]\n\n" % bg.display_name
	text += "%s\n\n" % bg.description

	var skill_names: PackedStringArray = []
	for s in bg.skill_proficiencies:
		skill_names.append(String(s).capitalize().replace("_", " "))
	text += "[b]Skill Proficiencies:[/b] %s\n" % ", ".join(skill_names)

	if bg.tool_proficiencies.size() > 0:
		var tool_names: PackedStringArray = []
		for t in bg.tool_proficiencies:
			tool_names.append(String(t).capitalize().replace("_", " "))
		text += "[b]Tool Proficiencies:[/b] %s\n" % ", ".join(tool_names)

	if bg.ability_score_increases.size() > 0:
		text += "\n[b]Ability Score Increases:[/b]\n"
		for ability_key in bg.ability_score_increases:
			text += "  %s +%d\n" % [String(ability_key).capitalize(), bg.ability_score_increases[ability_key]]

	if bg.origin_feat != &"":
		var feat: FeatData = DataRegistry.get_feat(bg.origin_feat)
		if feat != null:
			text += "\n[b]Origin Feat: %s[/b]\n" % feat.display_name
			text += "  %s\n" % feat.description

	text += "\n[b]Starting Gold:[/b] %d gp\n" % bg.starting_gold

	details_label.text = text

	var parent_screen = get_parent()
	while parent_screen != null and not parent_screen.has_method("refresh_navigation"):
		parent_screen = parent_screen.get_parent()
	if parent_screen != null:
		parent_screen.refresh_navigation()


func is_valid() -> bool:
	return _selected_index >= 0


func apply(creator: CharacterCreator) -> void:
	if _selected_index >= 0:
		creator.set_background(_backgrounds[_selected_index])
