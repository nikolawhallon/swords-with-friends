extends Area2D


signal killed

var velocity = Vector2.ZERO

func init(initial_global_position, initial_velocity):
	global_position = initial_global_position
	velocity = initial_velocity

func _ready():
	$AnimatedSprite2D.play("default")

func _process(delta):
	if not multiplayer.is_server():
		return

	position += velocity * delta

func _on_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if not multiplayer.is_server():
		return

	if area.is_in_group("Sword"):
		emit_signal("killed")
		queue_free()
