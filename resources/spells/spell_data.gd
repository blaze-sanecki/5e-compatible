class_name SpellData
extends Resource

## Complete definition of a spell, covering all 5e spell properties:
## level, school, casting time, range, components, duration, damage, and more.

## Unique identifier for this spell.
@export var id: StringName

## Human-readable spell name.
@export var display_name: String

## Full text description of the spell's effects.
@export_multiline var description: String

## Spell level from 0 (cantrip) to 9.
@export var spell_level: int = 0

## School of magic: "abjuration", "conjuration", "divination", "enchantment",
## "evocation", "illusion", "necromancy", "transmutation".
@export var school: StringName

## Action economy cost: "action", "bonus_action", "reaction", "1 minute", "10 minutes",
## "1 hour", "8 hours", "12 hours", "24 hours".
@export var casting_time: StringName = &"action"

## Whether the spell targets self, touch, or at range: "self", "touch", "ranged".
@export var range_type: StringName = &"self"

## Range in feet (only relevant when range_type is "ranged").
@export var range_ft: int = 0

## Whether the spell has a verbal component.
@export var components_verbal: bool = true

## Whether the spell has a somatic component.
@export var components_somatic: bool = true

## Whether the spell has a material component.
@export var components_material: bool = false

## Description of the material component (e.g., "a pinch of sulfur").
@export var material_description: String

## Gold piece cost of the material component (0 if no cost is specified).
@export var material_cost_gp: int = 0

## Whether the material component is consumed by the casting.
@export var material_consumed: bool = false

## How long the spell lasts (e.g., "instantaneous", "1 minute", "1 hour").
@export var duration: String = "instantaneous"

## Whether the spell requires concentration to maintain.
@export var concentration: bool = false

## Whether the spell can be cast as a ritual (adding 10 minutes to cast time).
@export var ritual: bool = false

## Damage roll for spells that deal damage. Null for non-damaging spells.
@export var damage: DamageRoll

## Description of additional effects when cast using a higher-level spell slot.
@export_multiline var higher_level_description: String

## Ability used for the saving throw this spell forces (e.g., "dexterity", "wisdom").
## Empty if the spell does not require a save.
@export var save_ability: StringName

## Area of effect shape: "none", "sphere", "cube", "cone", "line", "cylinder".
@export var aoe_shape: StringName

## Size of the area of effect in feet (radius for sphere/cylinder, side for cube, length for cone/line).
@export var aoe_size_ft: int = 0

## Which classes have this spell on their spell list.
@export var class_lists: Array[StringName]


## Returns a formatted components string such as "V, S, M (a pinch of dust)".
func get_components_string() -> String:
	var parts: PackedStringArray = PackedStringArray()

	if components_verbal:
		parts.append("V")
	if components_somatic:
		parts.append("S")
	if components_material:
		var mat: String = "M"
		if material_description != "":
			mat += " (%s)" % material_description
		parts.append(mat)

	return ", ".join(parts)
