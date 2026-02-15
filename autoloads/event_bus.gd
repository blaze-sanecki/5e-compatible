## Global signal bus for decoupled communication across all game systems.
##
## Registered as an autoload singleton. Any node can connect to or emit these
## signals without holding direct references to other systems.
extends Node

# ---------------------------------------------------------------------------
# Combat
# ---------------------------------------------------------------------------
signal character_damaged(character: Resource, amount: int, damage_type: StringName)
signal character_healed(character: Resource, amount: int)
signal character_died(character: Resource)

signal combat_started()
signal combat_ended()
signal turn_started(character: Resource)
signal turn_ended(character: Resource)
signal initiative_rolled(order: Array)
signal action_performed(character: Resource, action: Dictionary)
signal combat_round_started(round_number: int)
signal concentration_broken(character: Resource)

# ---------------------------------------------------------------------------
# Spellcasting
# ---------------------------------------------------------------------------
signal spell_cast(caster: Resource, spell: Resource)

# ---------------------------------------------------------------------------
# Conditions
# ---------------------------------------------------------------------------
signal condition_applied(character: Resource, condition: StringName)
signal condition_removed(character: Resource, condition: StringName)

# ---------------------------------------------------------------------------
# Items / Inventory
# ---------------------------------------------------------------------------
signal item_acquired(character: Resource, item: Resource)
signal item_used(character: Resource, item: Resource)
signal item_equipped(character: Resource, item: Resource)
signal item_unequipped(character: Resource, item: Resource)

# ---------------------------------------------------------------------------
# Quests
# ---------------------------------------------------------------------------
signal quest_started(quest_id: StringName)
signal quest_completed(quest_id: StringName)
signal quest_objective_updated(quest_id: StringName, objective_id: StringName)

# ---------------------------------------------------------------------------
# Dialogue
# ---------------------------------------------------------------------------
signal dialogue_started(npc_name: String)
signal dialogue_ended()
signal dialogue_choice_made(choice_index: int)

# ---------------------------------------------------------------------------
# Character progression
# ---------------------------------------------------------------------------
signal level_up(character: Resource, new_level: int)
signal experience_gained(character: Resource, amount: int)
signal gold_changed(character: Resource, new_total: int)

# ---------------------------------------------------------------------------
# Party
# ---------------------------------------------------------------------------
signal party_member_added(character: Resource)
signal party_member_removed(character: Resource)

# ---------------------------------------------------------------------------
# World / Navigation
# ---------------------------------------------------------------------------
signal map_transition(from_map: String, to_map: String)
signal interaction_triggered(interactable: Node)

# ---------------------------------------------------------------------------
# Ability checks & saves
# ---------------------------------------------------------------------------
signal skill_check_made(character: Resource, skill: StringName, result: Dictionary)
signal saving_throw_made(character: Resource, ability: StringName, result: Dictionary)
signal death_save_made(character: Resource, result: Dictionary)

# ---------------------------------------------------------------------------
# Resting
# ---------------------------------------------------------------------------
signal rest_started(rest_type: StringName)
signal rest_completed(rest_type: StringName)

# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------
signal game_saved(slot: int)
signal game_loaded(slot: int)
