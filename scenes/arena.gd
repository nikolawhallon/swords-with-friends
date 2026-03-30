extends Node2D


signal leave_requested

var match_id = null

enum State {
	VOID,
	STARTING,
	PLAYING,
	GAME_OVER
}

var state := State.VOID

func _process(_delta: float) -> void:
	if state == State.STARTING:
		state = State.PLAYING

	if Input.is_action_just_pressed("leave"):
		emit_signal("leave_requested")

	var knights = NodeUtils.get_nodes_in_group_for_node(self, "Knight")
	if len(knights) > 0:
		var knight_center = Vector2.ZERO
		for knight in knights:
			knight_center.x += knight.global_position.x
			knight_center.y += knight.global_position.y
		knight_center = knight_center / len(knights)
		$Camera2D.global_position = knight_center

	$Camera2D.limit_left   = int($Map.get_map_origin().x)
	$Camera2D.limit_top    = int($Map.get_map_origin().y)
	$Camera2D.limit_right  = int($Map.get_map_origin().x + $Map.get_map_size().x)
	$Camera2D.limit_bottom = int($Map.get_map_origin().y + $Map.get_map_size().y)

func _input(event):
	if event is InputEventJoypadButton:
		for knight in NodeUtils.get_nodes_in_group_for_node(self, "Knight"):
			if knight.device_id == event.device:
				return

		request_spawn_knight.rpc_id(1, event.device)

@rpc("call_local", "reliable")
func announce_start_game(random_seed, _peers):
	state = State.STARTING
	$Map.init(random_seed)

@rpc("any_peer", "call_local", "unreliable")
func request_spawn_knight(device_id):
	var pos = $Map.get_random_ground_position()
	
	while pos.distance_to($Camera2D.global_position) > 128:
		pos = $Map.get_random_ground_position()

	var knight = load("res://scenes/knight.tscn").instantiate()
	knight.init(multiplayer.get_remote_sender_id(), device_id, pos)
	$Replicated.add_child(knight, true)
