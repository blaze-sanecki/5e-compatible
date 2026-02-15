class_name SpeciesData
extends Resource

## Resource defining a playable species (race) such as Human, Elf, or Dwarf.
## Contains all innate traits, movement, and physical characteristics.

## Unique identifier for this species (e.g., "elf", "dwarf").
@export var id: StringName
## Human-readable name for display (e.g., "Elf").
@export var display_name: String
## Full text description of the species.
@export_multiline var description: String

## The creature type for this species (e.g., "humanoid", "fey").
@export var creature_type: StringName = &"humanoid"
## Size category: "small", "medium", "large", etc.
@export var size: StringName = &"medium"
## Base walking speed in feet.
@export var base_speed: int = 30
## Darkvision range in feet. 0 means no darkvision.
@export var darkvision_range: int = 0

## Damage type resistances granted by this species (e.g., "fire", "poison").
@export var resistances: Array[StringName]
## Languages known by default (e.g., "common", "elvish").
@export var languages: Array[StringName]

## Racial traits for this species.
## Each entry is a Dictionary with keys: "name" (String), "description" (String).
@export var traits: Array[Dictionary]
