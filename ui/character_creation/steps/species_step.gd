extends Control

## Step 2: Species selection.
## Shows a list of species on the left and traits/details on the right.

var _creator: CharacterCreator
var _species_list: Array = []
var _selected_index: int = -1

@onready var species_item_list: ItemList = %SpeciesList
@onready var details_label: RichTextLabel = %DetailsLabel


func setup(creator: CharacterCreator) -> void:
	_creator = creator


func _ready() -> void:
	_species_list = DataRegistry.get_all_species()
	_species_list.sort_custom(func(a, b): return a.display_name < b.display_name)

	for sp in _species_list:
		species_item_list.add_item(sp.display_name)

	species_item_list.item_selected.connect(_on_species_selected)

	if _creator != null and _creator.chosen_species != null:
		for i in _species_list.size():
			if _species_list[i].id == _creator.chosen_species.id:
				species_item_list.select(i)
				_on_species_selected(i)
				break


func _on_species_selected(index: int) -> void:
	_selected_index = index
	var sp: SpeciesData = _species_list[index]

	var text := "[b]%s[/b]\n\n" % sp.display_name
	text += "%s\n\n" % sp.description
	text += "[b]Size:[/b] %s\n" % String(sp.size).capitalize()
	text += "[b]Speed:[/b] %d ft.\n" % sp.base_speed
	text += "[b]Darkvision:[/b] %s\n" % ("%d ft." % sp.darkvision_range if sp.darkvision_range > 0 else "None")

	if sp.resistances.size() > 0:
		var names: PackedStringArray = []
		for r in sp.resistances:
			names.append(String(r).capitalize())
		text += "[b]Resistances:[/b] %s\n" % ", ".join(names)

	var lang_names: PackedStringArray = []
	for l in sp.languages:
		lang_names.append(String(l).capitalize())
	text += "[b]Languages:[/b] %s\n" % ", ".join(lang_names)

	text += "\n[b]Traits:[/b]\n"
	for trait_data in sp.traits:
		text += "  [b]%s:[/b] %s\n" % [trait_data.get("name", ""), trait_data.get("description", "")]

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
		creator.set_species(_species_list[_selected_index])
