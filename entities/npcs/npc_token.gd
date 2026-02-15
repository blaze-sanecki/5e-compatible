class_name NPCToken
extends Area2D

## Visual representation of an NPC on a square-grid dungeon map.
##
## Implements the same duck-typed interact() + blocks_movement() interface
## as InteractableBase so that GridDungeonController discovers it via
## has_method("interact").

## Unique identifier for this NPC (used for quest objective tracking).
@export var npc_id: StringName

## Display name shown in dialogue and on the label.
@export var npc_name: String = "NPC"

## The dialogue tree id to start when the player interacts.
@export var dialogue_tree_id: StringName

## Grid cell this NPC occupies.
var current_cell: Vector2i = Vector2i.ZERO

## Reference to the floor tilemap for coordinate conversion.
var _floor_layer: TileMapLayer

## Child nodes created at runtime.
var _sprite: Sprite2D
var _label: Label


func _ready() -> void:
	collision_layer = 0b0010
	collision_mask = 0

	_create_visuals()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Initialize the NPC at a specific grid cell.
func setup(floor_layer: TileMapLayer, cell: Vector2i) -> void:
	_floor_layer = floor_layer
	current_cell = cell
	position = floor_layer.map_to_local(cell)


# ---------------------------------------------------------------------------
# Interaction interface (duck-typed, matches InteractableBase)
# ---------------------------------------------------------------------------

## Called by GridDungeonController when the player presses E adjacent to this NPC.
func interact() -> void:
	if dialogue_tree_id != &"":
		DialogueManager.start_dialogue(dialogue_tree_id)


## NPCs always block movement through their cell.
func blocks_movement() -> bool:
	return true


# ---------------------------------------------------------------------------
# Visuals
# ---------------------------------------------------------------------------

func _create_visuals() -> void:
	# Collision shape.
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)

	# Green circle placeholder sprite.
	_sprite = Sprite2D.new()
	_sprite.texture = TestMapGenerator.create_circle_texture(20, Color(0.2, 0.8, 0.3, 1.0))
	add_child(_sprite)

	# Name label above the sprite.
	_label = Label.new()
	_label.text = npc_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-30, -24)
	_label.size = Vector2(60, 20)
	_label.add_theme_font_size_override("font_size", 10)
	add_child(_label)


func _on_mouse_entered() -> void:
	modulate = Color(1.3, 1.3, 1.0, 1.0)


func _on_mouse_exited() -> void:
	modulate = Color.WHITE
