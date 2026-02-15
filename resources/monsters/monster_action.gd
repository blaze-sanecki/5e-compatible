class_name MonsterAction
extends Resource

## A single action, bonus action, reaction, or legendary action for a monster.

@export var name: String
@export var type: StringName = &""  ## "melee_attack", "ranged_attack", or empty for special.
@export var attack_bonus: int = 0
@export var reach: int = 5          ## Melee reach in feet.
@export var range_normal: int = 0   ## Normal range for ranged attacks.
@export var range_long: int = 0     ## Long range for ranged attacks.
@export var damage: String          ## Dice expression, e.g., "1d6+2".
@export var damage_type: StringName = &""
@export_multiline var description: String
@export var save_dc: int = 0
@export var save_ability: StringName = &""
@export var save_effect: String
@export var cost: int = 1           ## Legendary action cost.
