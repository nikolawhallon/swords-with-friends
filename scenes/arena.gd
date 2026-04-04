extends Node2D


signal leave_requested

var match_id = null

enum State {
	VOID,
	STARTING,
	PLAYING,
	GAME_OVER
}

var state = State.VOID
var score = 0

func _process(_delta: float) -> void:
	if state == State.STARTING:
		state = State.PLAYING

	if Input.is_action_just_pressed("leave"):
		emit_signal("leave_requested")

	var knights = NodeUtils.get_nodes_in_group_for_node(self, "Knight")
	var denominator = 0
	var knight_center = Vector2.ZERO
	for knight in knights:
		if knight.peer_id != multiplayer.get_unique_id():
			continue
		knight_center.x += knight.global_position.x
		knight_center.y += knight.global_position.y
		denominator += 1
	if denominator > 0:
		knight_center = knight_center / denominator
		$Camera2D.global_position = knight_center

	$Camera2D.limit_left   = int($Map.get_map_origin().x)
	$Camera2D.limit_top    = int($Map.get_map_origin().y)
	$Camera2D.limit_right  = int($Map.get_map_origin().x + $Map.get_map_size().x)
	$Camera2D.limit_bottom = int($Map.get_map_origin().y + $Map.get_map_size().y)

	if not multiplayer.is_server():
		return

	for ghost in NodeUtils.get_nodes_in_group_for_node(self, "Ghost"):
		# TODO: using just the width is hacky
		if $Map.get_map_center().distance_to(ghost.global_position) > $Map.get_map_size().x * 2:
			ghost.queue_free()

func _input(event):
	if event is InputEventJoypadButton:
		for knight in NodeUtils.get_nodes_in_group_for_node(self, "Knight"):
			if knight.device_id == event.device and knight.peer_id == multiplayer.get_unique_id():
				return

		request_spawn_knight.rpc_id(1, event.device)

	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_SPACE or event.keycode == KEY_UP or event.keycode == KEY_DOWN or event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT:
			for knight in NodeUtils.get_nodes_in_group_for_node(self, "Knight"):
				if knight.device_id == -1 and knight.peer_id == multiplayer.get_unique_id():
					return

			request_spawn_knight.rpc_id(1, -1)

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

func _on_ghost_timer_timeout() -> void:
	if not multiplayer.is_server():
		return

	var ghost = load("res://scenes/ghost.tscn").instantiate()
	var initial_global_position = get_random_position_around_map()
	var initial_velocity = (get_random_position_in_map() - initial_global_position).normalized() * 100.0
	ghost.init(initial_global_position, initial_velocity)
	ghost.killed.connect(_on_ghost_killed)
	$Replicated.add_child(ghost, true)

func _on_ghost_killed():
	if not multiplayer.is_server():
		return

	score += 1
	for peer in NodeUtils.get_first_ancestor_in_group_for_node(self, "App").get_peer_ids_for_match(match_id):
		announce_update_score.rpc_id(peer, score)

func get_random_position_in_map() -> Vector2:
	var size = $Map.get_map_size()
	var origin = $Map.get_map_origin()

	return Vector2(
		randf_range(origin.x, origin.x + size.x),
		randf_range(origin.y, origin.y + size.y)
	)

func get_random_position_around_map() -> Vector2:
	var margin = 64.0
	var size = $Map.get_map_size()
	var origin = $Map.get_map_origin()

	match randi() % 4:
		0: # top
			return Vector2(
				randf_range(origin.x - margin, origin.x + size.x + margin),
				origin.y - margin
			)
		1: # bottom
			return Vector2(
				randf_range(origin.x - margin, origin.x + size.x + margin),
				origin.y + size.y + margin
			)
		2: # left
			return Vector2(
				origin.x - margin,
				randf_range(origin.y - margin, origin.y + size.y + margin)
			)
		3: # right
			return Vector2(
				origin.x + size.x + margin,
				randf_range(origin.y - margin, origin.y + size.y + margin)
			)

	return origin

@rpc("authority", "call_local", "reliable")
func announce_update_score(new_score: int) -> void:
	score = new_score
	$CanvasLayer/MarginContainer/ScoreLabel.text = "SCORE: %d" % score
