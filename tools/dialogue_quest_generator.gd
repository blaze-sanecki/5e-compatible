## Generates dialogue trees and quest .tres data files.
## Run the dialogue_quest_generator.tscn scene (F6) to populate data/.
extends Node


# ---------------------------------------------------------------------------
# DialogueEvent helpers
# ---------------------------------------------------------------------------

static func _evt_quest(qid: StringName) -> DialogueEvent:
	var e := DialogueEvent.new()
	e.type = &"start_quest"
	e.quest_id = qid
	return e


static func _evt_item(iid: StringName, qty: int = 1) -> DialogueEvent:
	var e := DialogueEvent.new()
	e.type = &"give_item"
	e.item_id = iid
	e.quantity = qty
	return e


static func _evt_flag(f: String, v: bool = true) -> DialogueEvent:
	var e := DialogueEvent.new()
	e.type = &"set_flag"
	e.flag = f
	e.value = v
	return e


static func _evt_combat(encounter_id: StringName) -> DialogueEvent:
	var e := DialogueEvent.new()
	e.type = &"start_combat"
	e.quest_id = encounter_id
	return e


static func _evt_advance(qid: StringName, objective_id: StringName) -> DialogueEvent:
	var e := DialogueEvent.new()
	e.type = &"advance_objective"
	e.quest_id = qid
	e.item_id = objective_id
	return e


# ---------------------------------------------------------------------------
# DialogueCondition helpers
# ---------------------------------------------------------------------------

static func _cond_skill(s: StringName, d: int, fail_id: StringName = &"") -> DialogueCondition:
	var c := DialogueCondition.new()
	c.type = &"skill_check"
	c.skill = s
	c.dc = d
	c.fail_node_id = fail_id
	return c


static func _cond_quest(qid: StringName) -> DialogueCondition:
	var c := DialogueCondition.new()
	c.type = &"quest_complete"
	c.quest_id = qid
	return c


static func _cond_not_flag(f: String) -> DialogueCondition:
	var c := DialogueCondition.new()
	c.type = &"not_flag"
	c.flag = f
	return c


func _ready() -> void:
	print("=== Dialogue & Quest Data Generator ===")
	_generate_items()
	_generate_dialogues()
	_generate_quests()
	print("=== Dialogue & quest data generation complete! ===")
	get_tree().quit()


func _save(resource: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("Failed to save: %s (error %d)" % [path, err])
	else:
		print("  Saved: %s" % path)


# ===========================================================================
# Items needed by dialogue/quests
# ===========================================================================

func _generate_items() -> void:
	print("Generating quest-related items...")

	var potion := ItemData.new()
	potion.id = &"health_potion"
	potion.display_name = "Potion of Healing"
	potion.description = "A vial of red liquid that restores 2d4+2 hit points when consumed."
	potion.weight = 0.5
	potion.cost_gp = 50.0
	potion.stackable = true
	potion.max_stack = 10
	potion.item_type = &"consumable"
	potion.effects = [{"type": "heal", "dice": "2d4+2"}]
	_save(potion, "res://data/equipment/health_potion.tres")

	var trade_goods := ItemData.new()
	trade_goods.id = &"trade_goods"
	trade_goods.display_name = "Trade Goods"
	trade_goods.description = "A bundle of assorted trade goods: cloth, spices, and small tools."
	trade_goods.weight = 2.0
	trade_goods.cost_gp = 5.0
	trade_goods.stackable = true
	trade_goods.max_stack = 20
	trade_goods.item_type = &"treasure"
	_save(trade_goods, "res://data/equipment/trade_goods.tres")

	var artifact := ItemData.new()
	artifact.id = &"ancient_artifact"
	artifact.display_name = "Ancient Artifact"
	artifact.description = "A mysterious stone tablet covered in arcane runes. It pulses faintly with residual magic."
	artifact.weight = 3.0
	artifact.cost_gp = 500.0
	artifact.stackable = false
	artifact.item_type = &"treasure"
	_save(artifact, "res://data/equipment/ancient_artifact.tres")


# ===========================================================================
# Dialogue Trees
# ===========================================================================

func _generate_dialogues() -> void:
	print("Generating dialogue trees...")
	_generate_elder_maren()
	_generate_merchant_tomas()
	_generate_goblin_chief()


func _generate_elder_maren() -> void:
	var tree := DialogueTree.new()
	tree.id = &"elder_maren"
	tree.npc_name = "Elder Maren"
	tree.start_node_id = &"greeting"

	# --- Node: greeting ---
	var greeting := DialogueNode.new()
	greeting.node_id = &"greeting"
	greeting.speaker = "Elder Maren"
	greeting.text = "Ah, traveler. Our village has been plagued by goblins from the den to the north. We desperately need someone to deal with them."

	var c1 := DialogueChoice.new()
	c1.text = "I'll help clear the goblin den."
	c1.next_node_id = &"accept_quest"
	c1.events = [_evt_quest(&"clear_goblin_den")]

	var c2 := DialogueChoice.new()
	c2.text = "What's in it for me?"
	c2.next_node_id = &"negotiate"

	var c3 := DialogueChoice.new()
	c3.text = "Not my problem."
	c3.next_node_id = &"refuse"

	greeting.choices = [c1, c2, c3]

	# --- Node: negotiate ---
	var negotiate := DialogueNode.new()
	negotiate.node_id = &"negotiate"
	negotiate.speaker = "Elder Maren"
	negotiate.text = "We can offer 100 gold pieces for clearing the den. But if you think you deserve more..."

	var c_persuade := DialogueChoice.new()
	c_persuade.text = "I think this job is worth more."
	c_persuade.next_node_id = &"persuade_success"
	c_persuade.conditions = [_cond_skill(&"persuasion", 12, &"persuade_fail")]

	var c_accept := DialogueChoice.new()
	c_accept.text = "100 gold is fair. I'll do it."
	c_accept.next_node_id = &"accept_quest"
	c_accept.events = [_evt_quest(&"clear_goblin_den")]

	negotiate.choices = [c_persuade, c_accept]

	# --- Node: persuade_success ---
	var persuade_success := DialogueNode.new()
	persuade_success.node_id = &"persuade_success"
	persuade_success.speaker = "Elder Maren"
	persuade_success.text = "You drive a hard bargain, but you're right — this is dangerous work. 150 gold and a healing potion. Deal?"
	persuade_success.next_node_id = &"accept_quest_bonus"
	persuade_success.events = [_evt_flag("maren_bonus_reward")]

	# --- Node: persuade_fail ---
	var persuade_fail := DialogueNode.new()
	persuade_fail.node_id = &"persuade_fail"
	persuade_fail.speaker = "Elder Maren"
	persuade_fail.text = "I'm sorry, but 100 gold is all we can spare. Will you still help us?"

	var c_ok := DialogueChoice.new()
	c_ok.text = "Fine, I'll take the job."
	c_ok.next_node_id = &"accept_quest"
	c_ok.events = [_evt_quest(&"clear_goblin_den")]

	var c_no := DialogueChoice.new()
	c_no.text = "I need to think about it."
	c_no.next_node_id = &"maybe_later"

	persuade_fail.choices = [c_ok, c_no]

	# --- Node: accept_quest ---
	var accept := DialogueNode.new()
	accept.node_id = &"accept_quest"
	accept.speaker = "Elder Maren"
	accept.text = "Thank you, brave adventurer. The goblin den is in the caves to the north. Be careful — their chief is cunning."
	accept.is_end = true

	# --- Node: accept_quest_bonus ---
	var accept_bonus := DialogueNode.new()
	accept_bonus.node_id = &"accept_quest_bonus"
	accept_bonus.speaker = "Elder Maren"
	accept_bonus.text = "Excellent! Here, take this potion for the road. The goblin den is to the north. Good luck!"
	accept_bonus.is_end = true
	accept_bonus.events = [
		_evt_quest(&"clear_goblin_den"),
		_evt_item(&"health_potion"),
	]

	# --- Node: refuse ---
	var refuse := DialogueNode.new()
	refuse.node_id = &"refuse"
	refuse.speaker = "Elder Maren"
	refuse.text = "I understand. If you change your mind, you know where to find me."
	refuse.is_end = true

	# --- Node: maybe_later ---
	var maybe_later := DialogueNode.new()
	maybe_later.node_id = &"maybe_later"
	maybe_later.speaker = "Elder Maren"
	maybe_later.text = "Of course. Take your time. We'll be here... if the goblins haven't gotten to us first."
	maybe_later.is_end = true

	# --- Node: post_quest (shown after quest is completed) ---
	var post_quest := DialogueNode.new()
	post_quest.node_id = &"post_quest"
	post_quest.speaker = "Elder Maren"
	post_quest.text = "You've done it! The village is safe once more. You have our eternal gratitude."
	post_quest.is_end = true

	# Make greeting branch to post_quest if quest is completed.
	var c_post := DialogueChoice.new()
	c_post.text = "(Quest complete greeting)"
	c_post.next_node_id = &"post_quest"
	c_post.visible_conditions = [_cond_quest(&"clear_goblin_den")]

	# Add post-quest option to top of greeting choices.
	greeting.choices = [c_post, c1, c2, c3]

	# Hide the regular choices if quest is already complete.
	var _hide_after_quest: Array[DialogueCondition] = [_cond_not_flag("quest_complete_clear_goblin_den")]
	c1.visible_conditions = _hide_after_quest
	c2.visible_conditions = _hide_after_quest
	c3.visible_conditions = _hide_after_quest

	tree.nodes = [greeting, negotiate, persuade_success, persuade_fail, accept, accept_bonus, refuse, maybe_later, post_quest]
	_save(tree, "res://data/dialogue/elder_maren.tres")


func _generate_merchant_tomas() -> void:
	var tree := DialogueTree.new()
	tree.id = &"merchant_tomas"
	tree.npc_name = "Merchant Tomas"
	tree.start_node_id = &"greeting"

	# --- Node: greeting ---
	var greeting := DialogueNode.new()
	greeting.node_id = &"greeting"
	greeting.speaker = "Merchant Tomas"
	greeting.text = "Welcome, welcome! Tomas the merchant, at your service. Though times have been hard — bandits stole half my stock on the road here."

	var c1 := DialogueChoice.new()
	c1.text = "That's terrible. Can I help?"
	c1.next_node_id = &"offer_help"

	var c2 := DialogueChoice.new()
	c2.text = "Do you have anything for sale?"
	c2.next_node_id = &"shop_talk"

	var c3 := DialogueChoice.new()
	c3.text = "Heard any rumors?"
	c3.next_node_id = &"rumors"

	greeting.choices = [c1, c2, c3]

	# --- Node: offer_help ---
	var offer_help := DialogueNode.new()
	offer_help.node_id = &"offer_help"
	offer_help.speaker = "Merchant Tomas"
	offer_help.text = "Really? The bandits scattered my trade goods along the road. If you could recover 3 bundles, I'd pay you well — 75 gold and a free potion!"

	var c_accept := DialogueChoice.new()
	c_accept.text = "I'll find your goods."
	c_accept.next_node_id = &"quest_accepted"
	c_accept.events = [_evt_quest(&"merchants_lost_goods")]

	var c_decline := DialogueChoice.new()
	c_decline.text = "Sorry, too busy right now."
	c_decline.next_node_id = &"decline"

	offer_help.choices = [c_accept, c_decline]

	# --- Node: quest_accepted ---
	var quest_accepted := DialogueNode.new()
	quest_accepted.node_id = &"quest_accepted"
	quest_accepted.speaker = "Merchant Tomas"
	quest_accepted.text = "Thank you! The bundles should be scattered along the northern trail. They're wrapped in brown cloth — hard to miss."
	quest_accepted.is_end = true

	# --- Node: decline ---
	var decline := DialogueNode.new()
	decline.node_id = &"decline"
	decline.speaker = "Merchant Tomas"
	decline.text = "No worries, friend. If you change your mind, I'll be here."
	decline.is_end = true

	# --- Node: shop_talk ---
	var shop_talk := DialogueNode.new()
	shop_talk.node_id = &"shop_talk"
	shop_talk.speaker = "Merchant Tomas"
	shop_talk.text = "I've got a few potions left, but my prices are steep after the losses."

	var c_haggle := DialogueChoice.new()
	c_haggle.text = "Surely you can offer a discount?"
	c_haggle.next_node_id = &"discount_success"
	c_haggle.conditions = [_cond_skill(&"deception", 14, &"discount_fail")]

	var c_buy := DialogueChoice.new()
	c_buy.text = "I'll take a potion at full price."
	c_buy.next_node_id = &"buy_potion"

	shop_talk.choices = [c_haggle, c_buy]

	# --- Node: discount_success ---
	var discount_success := DialogueNode.new()
	discount_success.node_id = &"discount_success"
	discount_success.speaker = "Merchant Tomas"
	discount_success.text = "Well... I suppose I can part with one for free. You look like someone who'll spread the word about my shop."
	discount_success.is_end = true
	discount_success.events = [_evt_item(&"health_potion")]

	# --- Node: discount_fail ---
	var discount_fail := DialogueNode.new()
	discount_fail.node_id = &"discount_fail"
	discount_fail.speaker = "Merchant Tomas"
	discount_fail.text = "Nice try, but I wasn't born yesterday. Full price or nothing."
	discount_fail.is_end = true

	# --- Node: buy_potion ---
	var buy_potion := DialogueNode.new()
	buy_potion.node_id = &"buy_potion"
	buy_potion.speaker = "Merchant Tomas"
	buy_potion.text = "Here you go! One Potion of Healing. Stay safe out there."
	buy_potion.is_end = true
	buy_potion.events = [_evt_item(&"health_potion")]

	# --- Node: rumors ---
	var rumors := DialogueNode.new()
	rumors.node_id = &"rumors"
	rumors.speaker = "Merchant Tomas"
	rumors.text = "Word is there are old ruins east of here. Dangerous place, but I've heard there's a powerful artifact hidden inside. Might be worth checking out — if you survive the goblins first."
	rumors.is_end = true

	tree.nodes = [greeting, offer_help, quest_accepted, decline, shop_talk, discount_success, discount_fail, buy_potion, rumors]
	_save(tree, "res://data/dialogue/merchant_tomas.tres")


func _generate_goblin_chief() -> void:
	var tree := DialogueTree.new()
	tree.id = &"goblin_chief"
	tree.npc_name = "Goblin Chief Grak"
	tree.start_node_id = &"greeting"

	# --- Node: greeting ---
	var greeting := DialogueNode.new()
	greeting.node_id = &"greeting"
	greeting.speaker = "Goblin Chief Grak"
	greeting.text = "You! Human! You come to Grak's den and kill Grak's warriors? Grak will crush you!"

	var c1 := DialogueChoice.new()
	c1.text = "Leave this place or face my wrath."
	c1.next_node_id = &"intimidate_success"
	c1.conditions = [_cond_skill(&"intimidation", 15, &"intimidate_fail")]

	var c2 := DialogueChoice.new()
	c2.text = "We can settle this peacefully."
	c2.next_node_id = &"diplomacy"

	var c3 := DialogueChoice.new()
	c3.text = "Prepare to die, goblin!"
	c3.next_node_id = &"fight"

	greeting.choices = [c1, c2, c3]

	# --- Node: intimidate_success ---
	var intimidate_success := DialogueNode.new()
	intimidate_success.node_id = &"intimidate_success"
	intimidate_success.speaker = "Goblin Chief Grak"
	intimidate_success.text = "G-Grak... Grak doesn't want to die. Fine! Grak will leave. Take whatever you want."
	intimidate_success.is_end = true
	intimidate_success.events = [
		_evt_flag("goblin_chief_fled"),
		_evt_advance(&"clear_goblin_den", &"talk_chief"),
	]

	# --- Node: intimidate_fail ---
	var intimidate_fail := DialogueNode.new()
	intimidate_fail.node_id = &"intimidate_fail"
	intimidate_fail.speaker = "Goblin Chief Grak"
	intimidate_fail.text = "Ha! You don't scare Grak! GRAK SMASH!"
	intimidate_fail.is_end = true
	intimidate_fail.events = [
		_evt_flag("goblin_chief_hostile"),
		_evt_combat(&"test_goblin_ambush"),
	]

	# --- Node: diplomacy ---
	var diplomacy := DialogueNode.new()
	diplomacy.node_id = &"diplomacy"
	diplomacy.speaker = "Goblin Chief Grak"
	diplomacy.text = "Peacefully? Grak's warriors are hungry. You bring food, maybe Grak leaves. But Grak doubts you will."
	diplomacy.is_end = true

	# --- Node: fight ---
	var fight := DialogueNode.new()
	fight.node_id = &"fight"
	fight.speaker = "Goblin Chief Grak"
	fight.text = "GRAK KNEW IT! ATTACK!"
	fight.is_end = true
	fight.events = [
		_evt_flag("goblin_chief_hostile"),
		_evt_combat(&"test_goblin_ambush"),
	]

	tree.nodes = [greeting, intimidate_success, intimidate_fail, diplomacy, fight]
	_save(tree, "res://data/dialogue/goblin_chief.tres")


# ===========================================================================
# Quests
# ===========================================================================

func _generate_quests() -> void:
	print("Generating quests...")

	# --- Clear the Goblin Den ---
	var goblin_quest := QuestData.new()
	goblin_quest.id = &"clear_goblin_den"
	goblin_quest.display_name = "Clear the Goblin Den"
	goblin_quest.description = "Elder Maren has asked you to eliminate the goblin threat from the caves to the north. Defeat the goblins and deal with their chief."
	goblin_quest.rewards_xp = 100
	goblin_quest.rewards_gold = 100
	goblin_quest.is_main_quest = false

	var obj_kill := QuestObjective.new()
	obj_kill.id = &"kill_goblins"
	obj_kill.description = "Defeat goblins"
	obj_kill.objective_type = &"kill"
	obj_kill.target_id = &"goblin"
	obj_kill.required_count = 3

	var obj_chief := QuestObjective.new()
	obj_chief.id = &"talk_chief"
	obj_chief.description = "Deal with the Goblin Chief"
	obj_chief.objective_type = &"talk"
	obj_chief.target_id = &"goblin_chief"
	obj_chief.required_count = 1
	obj_chief.is_optional = true

	goblin_quest.objectives = [obj_kill, obj_chief]
	_save(goblin_quest, "res://data/quests/clear_goblin_den.tres")

	# --- Merchant's Lost Goods ---
	var merchant_quest := QuestData.new()
	merchant_quest.id = &"merchants_lost_goods"
	merchant_quest.display_name = "Merchant's Lost Goods"
	merchant_quest.description = "Merchant Tomas lost his trade goods when bandits attacked his caravan. Recover 3 bundles of trade goods scattered along the northern trail."
	merchant_quest.rewards_xp = 75
	merchant_quest.rewards_gold = 75

	var obj_collect := QuestObjective.new()
	obj_collect.id = &"collect_goods"
	obj_collect.description = "Recover trade goods"
	obj_collect.objective_type = &"collect"
	obj_collect.target_id = &"trade_goods"
	obj_collect.required_count = 3

	merchant_quest.objectives = [obj_collect]
	_save(merchant_quest, "res://data/quests/merchants_lost_goods.tres")

	# --- Explore the Ruins ---
	var ruins_quest := QuestData.new()
	ruins_quest.id = &"explore_ruins"
	ruins_quest.display_name = "Explore the Ancient Ruins"
	ruins_quest.description = "Rumors speak of ancient ruins east of the village, said to contain a powerful artifact. Clear the goblins first, then investigate."
	ruins_quest.rewards_xp = 150
	ruins_quest.rewards_gold = 50
	ruins_quest.prerequisite_quests = [&"clear_goblin_den"]

	var obj_reach := QuestObjective.new()
	obj_reach.id = &"reach_ruins"
	obj_reach.description = "Find the ancient ruins"
	obj_reach.objective_type = &"reach"
	obj_reach.target_id = &"ruins_entrance"
	obj_reach.required_count = 1

	var obj_artifact := QuestObjective.new()
	obj_artifact.id = &"find_artifact"
	obj_artifact.description = "Recover the ancient artifact"
	obj_artifact.objective_type = &"collect"
	obj_artifact.target_id = &"ancient_artifact"
	obj_artifact.required_count = 1

	ruins_quest.objectives = [obj_reach, obj_artifact]
	_save(ruins_quest, "res://data/quests/explore_ruins.tres")
