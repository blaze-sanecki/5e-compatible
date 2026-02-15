extends Control

## Full-screen character sheet overlay.
## Left: Abilities, saves, skills. Center: Combat stats, features. Right: Proficiencies, spells.

var _character: CharacterData

@onready var name_label: Label = %NameLabel
@onready var class_label: Label = %ClassLabel
@onready var level_label: Label = %LevelLabel
@onready var xp_label: Label = %XPLabel
@onready var abilities_container: VBoxContainer = %AbilitiesContainer
@onready var saves_container: VBoxContainer = %SavesContainer
@onready var skills_container: VBoxContainer = %SkillsContainer
@onready var ac_label: Label = %ACLabel
@onready var hp_label: Label = %HPLabel
@onready var speed_label: Label = %SpeedLabel
@onready var initiative_label: Label = %InitiativeLabel
@onready var hit_dice_label: Label = %HitDiceLabel
@onready var features_container: VBoxContainer = %FeaturesContainer
@onready var proficiencies_label: RichTextLabel = %ProficienciesLabel
@onready var spellcasting_label: RichTextLabel = %SpellcastingLabel
@onready var level_up_btn: Button = %LevelUpBtn
@onready var close_btn: Button = %CloseBtn


func _ready() -> void:
	_character = PartyManager.get_active_character()
	if _character == null:
		push_error("CharacterSheetScreen: No active character.")
		return

	close_btn.pressed.connect(_on_close)
	level_up_btn.pressed.connect(_on_level_up)

	_refresh()


func _refresh() -> void:
	if _character == null:
		return

	# Header.
	name_label.text = _character.character_name
	class_label.text = "%s %s" % [
		_character.species.display_name if _character.species else "",
		_character.character_class.display_name if _character.character_class else "",
	]
	level_label.text = "Level %d" % _character.level
	xp_label.text = "XP: %d" % _character.experience_points
	level_up_btn.visible = LevelUpHandler.can_level_up(_character)

	# Ability scores.
	_clear_container(abilities_container)
	for ability in AbilityScores.ABILITIES:
		var score: int = _character.ability_scores.get_score(ability)
		var mod: int = _character.ability_scores.get_modifier(ability)
		var lbl := Label.new()
		lbl.text = "%s: %d (%+d)" % [String(ability).to_upper().left(3), score, mod]
		abilities_container.add_child(lbl)

	# Saving throws.
	_clear_container(saves_container)
	for ability in AbilityScores.ABILITIES:
		var mod: int = _character.get_modifier(ability)
		var is_prof: bool = _character.character_class != null and ability in _character.character_class.saving_throw_proficiencies
		if is_prof:
			mod += _character.get_proficiency_bonus()
		var lbl := Label.new()
		lbl.text = "%s %s: %+d" % ["*" if is_prof else " ", String(ability).to_upper().left(3), mod]
		saves_container.add_child(lbl)

	# Skills.
	_clear_container(skills_container)
	var sorted_skills: Array = CharacterData.SKILL_ABILITY_MAP.keys()
	sorted_skills.sort()
	for skill in sorted_skills:
		var mod: int = _character.get_skill_modifier(skill)
		var is_prof: bool = _character.is_proficient_in_skill(skill)
		var has_exp: bool = _character.has_expertise_in(skill)
		var marker: String = "**" if has_exp else ("*" if is_prof else " ")
		var lbl := Label.new()
		lbl.text = "%s %s: %+d" % [marker, String(skill).capitalize().replace("_", " "), mod]
		skills_container.add_child(lbl)

	# Combat stats.
	ac_label.text = "AC: %d" % _character.armor_class
	hp_label.text = "HP: %d / %d" % [_character.current_hp, _character.max_hp]
	if _character.temp_hp > 0:
		hp_label.text += " (+%d temp)" % _character.temp_hp
	speed_label.text = "Speed: %d ft." % _character.speed
	var init_mod: int = RulesEngine.calculate_initiative(_character)
	initiative_label.text = "Initiative: %+d" % init_mod
	hit_dice_label.text = "Hit Dice: %dd%d" % [_character.hit_dice_remaining, _character.character_class.hit_die if _character.character_class else 8]

	# Features.
	_clear_container(features_container)
	if _character.character_class != null:
		for feature in _character.character_class.class_features:
			var feat_level: int = feature.get("level", 0)
			if feat_level <= _character.level:
				var lbl := Label.new()
				lbl.text = "%s (Lv %d)" % [feature.get("name", ""), feat_level]
				lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
				features_container.add_child(lbl)
	# Feats.
	for feat in _character.feats:
		var lbl := Label.new()
		lbl.text = feat.display_name + " (Feat)"
		features_container.add_child(lbl)

	# Proficiencies.
	var prof_text := "[b]Proficiency Bonus:[/b] +%d\n\n" % _character.get_proficiency_bonus()
	if _character.character_class != null:
		if _character.character_class.armor_proficiencies.size() > 0:
			var names: PackedStringArray = []
			for p in _character.character_class.armor_proficiencies:
				names.append(String(p).capitalize())
			prof_text += "[b]Armor:[/b] %s\n" % ", ".join(names)
		if _character.character_class.weapon_proficiencies.size() > 0:
			var names: PackedStringArray = []
			for p in _character.character_class.weapon_proficiencies:
				names.append(String(p).capitalize())
			prof_text += "[b]Weapons:[/b] %s\n" % ", ".join(names)
	if _character.languages.size() > 0:
		var names: PackedStringArray = []
		for l in _character.languages:
			names.append(String(l).capitalize())
		prof_text += "[b]Languages:[/b] %s\n" % ", ".join(names)

	# Equipment preview.
	prof_text += "\n[b]Equipment:[/b]\n"
	if _character.equipped_armor != null:
		prof_text += "  Armor: %s\n" % _character.equipped_armor.display_name
	if _character.equipped_shield != null:
		prof_text += "  Shield: %s\n" % _character.equipped_shield.display_name
	for w in _character.equipped_weapons:
		prof_text += "  Weapon: %s\n" % w.display_name
	proficiencies_label.text = prof_text

	# Spellcasting.
	if _character.character_class != null and _character.character_class.is_spellcaster:
		var spell_text := "[b]Spellcasting (%s)[/b]\n" % String(_character.character_class.spellcasting_ability).capitalize()
		spell_text += "Spell DC: %d\n" % RulesEngine.calculate_spell_dc(_character)
		spell_text += "Spell Attack: +%d\n\n" % RulesEngine.calculate_spell_attack(_character)
		spell_text += "[b]Spell Slots:[/b]\n"
		for i in 9:
			if _character.max_spell_slots[i] > 0:
				spell_text += "  Level %d: %d / %d\n" % [i + 1, _character.spell_slots[i], _character.max_spell_slots[i]]
		spellcasting_label.text = spell_text
		spellcasting_label.visible = true
	else:
		spellcasting_label.visible = false


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()


func _on_level_up() -> void:
	var dialog_scene: PackedScene = load("res://ui/character_sheet/level_up_dialog.tscn")
	var dialog: Control = dialog_scene.instantiate()
	dialog.character = _character
	dialog.level_up_completed.connect(_on_level_up_completed)
	add_child(dialog)


func _on_level_up_completed() -> void:
	_refresh()


func _on_close() -> void:
	GameManager.change_state(GameManager.GameState.EXPLORING)
	queue_free()
