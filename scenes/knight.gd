extends CharacterBody2D


const SPEED = 50.0

@export var peer_id = -1
@export var device_id = -1
@export var direction = Vector2.ZERO
var facing = null
var sword = null

func init(initial_peer_id, initial_device_id, initial_global_position):
	peer_id = initial_peer_id
	device_id = initial_device_id
	global_position = initial_global_position

func _ready():
	$AnimatedSprite2D.play("idle")

	if not multiplayer.is_server():
		return

	var arena = NodeUtils.get_first_ancestor_in_group_for_node(self, "Arena")
	sword = load("res://scenes/sword.tscn").instantiate()
	arena.get_node("Replicated").add_child(sword, true)
	request_sheath.rpc_id(1)

func _physics_process(_delta: float) -> void:
	if velocity != Vector2.ZERO:
		$AnimatedSprite2D.play("move")
	else:
		$AnimatedSprite2D.play("idle")

	if velocity.x < -1.0:
		$AnimatedSprite2D.flip_h = true
	elif velocity.x > 1.0:
		$AnimatedSprite2D.flip_h = false

	if multiplayer.get_unique_id() == peer_id:
		var new_direction = calculate_new_direction()
	
		if new_direction != direction:
			request_update_direction.rpc_id(1, new_direction)

		if Input.is_joy_button_pressed(device_id, JOY_BUTTON_A) or Input.is_joy_button_pressed(device_id, JOY_BUTTON_B) or Input.is_joy_button_pressed(device_id, JOY_BUTTON_X) or Input.is_joy_button_pressed(device_id, JOY_BUTTON_Y):
			request_unsheath.rpc_id(1)
		else:
			request_sheath.rpc_id(1)

	if not multiplayer.is_server():
		return

	velocity = direction * SPEED
	move_and_slide()

func calculate_new_direction():
	var stick = Vector2(
		Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	)

	var dpad = Vector2(
		int(Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_RIGHT)) - int(Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_LEFT)),
		int(Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_DOWN)) - int(Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_UP))
	)

	var deadzone = 0.2

	if stick.length() >= deadzone:
		return stick.normalized()

	if dpad != Vector2.ZERO:
		return dpad.normalized()

	return Vector2.ZERO

@rpc("any_peer", "call_local", "unreliable")
func request_update_direction(new_direction):
	if not multiplayer.is_server():
		return

	assert(peer_id == multiplayer.get_remote_sender_id())
	direction = new_direction

	if direction != Vector2.ZERO:
		if direction.x > 0 and abs(direction.x) >= abs(direction.y):
			facing = "right"
		if direction.x < 0 and abs(direction.x) > abs(direction.y):
			facing = "left"
		if direction.y > 0 and abs(direction.y) >= abs(direction.x):
			facing = "down"
		if direction.y < 0 and abs(direction.y) > abs(direction.x):
			facing = "up"

@rpc("any_peer", "call_local", "unreliable")
func request_sheath():
	if not multiplayer.is_server():
		return

	sword.global_position = Vector2(-1024.0, -1024.0)

@rpc("any_peer", "call_local", "unreliable")
func request_unsheath():
	if not multiplayer.is_server():
		return

	if facing == "right":
		sword.get_node("AnimatedSprite2D").frame = 0
		sword.get_node("AnimatedSprite2D").flip_h = false
		sword.global_position = global_position + Vector2(8, 0)
	if facing == "left":
		sword.get_node("AnimatedSprite2D").frame = 0
		sword.get_node("AnimatedSprite2D").flip_h = true
		sword.global_position = global_position + Vector2(-8, 0)
	if facing == "down":
		sword.get_node("AnimatedSprite2D").frame = 1
		sword.get_node("AnimatedSprite2D").flip_v = false
		sword.global_position = global_position + Vector2(0, 8)
	if facing == "up":
		sword.get_node("AnimatedSprite2D").frame = 1
		sword.get_node("AnimatedSprite2D").flip_v = true
		sword.global_position = global_position + Vector2(0, -8)
