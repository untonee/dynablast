
class_name BombWave extends RigidBody2D

@export var animation_name := "epicenter"
@export var fliph := false
@export var flipv := false
@export var anim_speed := 1.0
@export var rot := 0

@onready var wave_anim: AnimatedSprite2D = $WaveAnim

func _ready() -> void:
	wave_anim.animation = animation_name
	wave_anim.flip_h = fliph
	wave_anim.flip_v = flipv
	wave_anim.speed_scale = anim_speed
	wave_anim.global_rotation_degrees = rot


func _on_wave_anim_animation_finished() -> void:
	get_parent().queue_free()	


func _on_body_entered(body: Node) -> void:
	var o = str(body.name).find("Brick")
	if o != -1:
		body.animation_player.play("destroy")
