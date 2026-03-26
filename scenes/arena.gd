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

@rpc("call_local", "reliable")
func announce_start_game(_random_seed, _peers):
	state = State.STARTING
