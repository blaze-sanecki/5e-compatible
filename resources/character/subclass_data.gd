class_name SubclassData
extends Resource

## Resource defining a subclass specialization (e.g., Champion Fighter,
## School of Evocation Wizard). Subclasses provide additional features
## on top of the base class.

## Unique identifier for this subclass (e.g., "champion", "evocation").
@export var id: StringName
## Human-readable name for display (e.g., "Champion").
@export var display_name: String
## Full text description of the subclass.
@export_multiline var description: String

## The id of the parent class this subclass belongs to (e.g., "fighter").
@export var parent_class_id: StringName

## Subclass features gained at each level.
## Each entry is a Dictionary with keys: "level" (int), "name" (String), "description" (String).
@export var features: Array[Dictionary]

## Bonus spells granted by this subclass, if any (references to SpellData resources).
@export var bonus_spells: Array[Resource]


## Returns all subclass features gained at the specified level.
func get_features_at_level(level: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for feature in features:
		if feature.get("level", 0) == level:
			results.append(feature)
	return results
