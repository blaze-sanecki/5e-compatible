class_name InteractableBase
extends Area2D

## Base class for all dungeon interactable objects.
##
## Provides interaction detection, highlight on hover, lock checking
## via LockCheck, and emits EventBus.interaction_triggered when activated.
## Each instance owns an InteractableState for pure-logic tracking.

## The data resource defining this interactable's properties.
@export var interactable_data: InteractableData

## Pure-logic state (open/looted/activated/highlighted).
var state: InteractableState

## Whether this interactable can currently be used.
var is_active: bool = true


func _init() -> void:
	state = InteractableState.new()


func _ready() -> void:
	# Set to interactable collision layer (layer 2).
	collision_layer = 0b0010
	collision_mask = 0

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	state.state_changed.connect(_on_state_changed)


# ---------------------------------------------------------------------------
# Interaction
# ---------------------------------------------------------------------------

## Called when a character interacts with this object.
func interact() -> void:
	if not is_active:
		return

	if interactable_data and interactable_data.is_locked:
		if not LockCheck.try_unlock(interactable_data):
			return

	_perform_interaction()
	EventBus.interaction_triggered.emit(self)


## Override in subclasses to implement specific behavior.
func _perform_interaction() -> void:
	pass


## Whether this interactable blocks character movement through its cell.
## Override in subclasses (e.g. closed doors block, open doors don't).
func blocks_movement() -> bool:
	return false


# ---------------------------------------------------------------------------
# State change callback
# ---------------------------------------------------------------------------

## Called when InteractableState changes. Override for custom visuals.
func _on_state_changed(_property: StringName, _value: Variant) -> void:
	pass


# ---------------------------------------------------------------------------
# Highlight
# ---------------------------------------------------------------------------

func highlight() -> void:
	state.set_highlighted(true)


func unhighlight() -> void:
	state.set_highlighted(false)


func _update_highlight_visual() -> void:
	modulate = Color(1.3, 1.3, 1.0, 1.0) if state.is_highlighted else Color.WHITE


func _on_mouse_entered() -> void:
	highlight()


func _on_mouse_exited() -> void:
	unhighlight()
