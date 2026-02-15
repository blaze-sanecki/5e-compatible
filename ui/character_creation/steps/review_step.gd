extends Control

## Step 7: Review and finalize.
## Shows summary of all choices, computed HP/AC/speed, and name input.

var _creator: CharacterCreator

@onready var name_edit: LineEdit = %NameEdit
@onready var summary_label: RichTextLabel = %SummaryLabel


func setup(creator: CharacterCreator) -> void:
	_creator = creator


func _ready() -> void:
	name_edit.text_changed.connect(_on_name_changed)

	if _creator != null:
		# Restore name if going back.
		if _creator.character_name != "":
			name_edit.text = _creator.character_name
		_update_summary()


func _on_name_changed(new_text: String) -> void:
	_creator.set_name(new_text)
	_refresh_parent()


func _update_summary() -> void:
	if _creator == null:
		return

	var text := ""

	# Class.
	if _creator.chosen_class != null:
		text += "[b]Class:[/b] %s (d%d)\n" % [_creator.chosen_class.display_name, _creator.chosen_class.hit_die]

	# Species.
	if _creator.chosen_species != null:
		text += "[b]Species:[/b] %s\n" % _creator.chosen_species.display_name

	# Background.
	if _creator.chosen_background != null:
		text += "[b]Background:[/b] %s\n" % _creator.chosen_background.display_name

	# Ability scores with background bonuses.
	if _creator.ability_scores != null:
		text += "\n[b]Ability Scores:[/b]\n"
		for ability in AbilityScores.ABILITIES:
			var base: int = _creator.ability_scores.get_score(ability)
			var bonus: int = 0
			if _creator.chosen_background != null:
				bonus = int(_creator.chosen_background.ability_score_increases.get(String(ability), 0))
			var total: int = mini(base + bonus, 20)
			var mod: int = int(floor(float(total - 10) / 2.0))
			if bonus > 0:
				text += "  %s: %d (+%d) = %d (%+d)\n" % [String(ability).capitalize(), base, bonus, total, mod]
			else:
				text += "  %s: %d (%+d)\n" % [String(ability).capitalize(), total, mod]

	# Skills.
	if _creator.chosen_skills.size() > 0 or (_creator.chosen_background != null and _creator.chosen_background.skill_proficiencies.size() > 0):
		text += "\n[b]Skill Proficiencies:[/b]\n"
		if _creator.chosen_background != null:
			for skill in _creator.chosen_background.skill_proficiencies:
				text += "  - %s (background)\n" % String(skill).capitalize().replace("_", " ")
		for skill in _creator.chosen_skills:
			text += "  - %s (class)\n" % String(skill).capitalize().replace("_", " ")

	# Computed stats.
	text += "\n[b]Computed Stats:[/b]\n"

	# HP.
	if _creator.chosen_class != null and _creator.ability_scores != null:
		var con_score: int = _creator.ability_scores.get_score(&"constitution")
		var con_bonus: int = 0
		if _creator.chosen_background != null:
			con_bonus = int(_creator.chosen_background.ability_score_increases.get("constitution", 0))
		var total_con: int = mini(con_score + con_bonus, 20)
		var con_mod: int = int(floor(float(total_con - 10) / 2.0))
		var hp: int = maxi(_creator.chosen_class.hit_die + con_mod, 1)
		text += "  HP: %d (d%d + %d CON)\n" % [hp, _creator.chosen_class.hit_die, con_mod]

	# Speed.
	if _creator.chosen_species != null:
		text += "  Speed: %d ft.\n" % _creator.chosen_species.base_speed

	# Origin feat.
	if _creator.chosen_background != null and _creator.chosen_background.origin_feat != &"":
		var feat: FeatData = DataRegistry.get_feat(_creator.chosen_background.origin_feat)
		if feat != null:
			text += "\n[b]Origin Feat:[/b] %s\n" % feat.display_name

	summary_label.text = text


func _refresh_parent() -> void:
	var parent_screen = get_parent()
	while parent_screen != null and not parent_screen.has_method("refresh_navigation"):
		parent_screen = parent_screen.get_parent()
	if parent_screen != null:
		parent_screen.refresh_navigation()


func is_valid() -> bool:
	return name_edit.text.strip_edges().length() > 0


func apply(creator: CharacterCreator) -> void:
	creator.set_name(name_edit.text.strip_edges())
