extends RigidBody2D

## очки за уничтожение этого кирпича взрывом
const SCORE_VALUE := 10

@export var pos: Vector2
@export var anim: String

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var brick: RigidBody2D = $"."

var destroyed := false

func _ready() -> void:
	global_position = pos
	animation_player.play("brick")

## уничтожить кирпич (вызывается волной взрыва)
func destroy() -> void:
	if destroyed:
		return
	destroyed = true
	GlobalVar.score += SCORE_VALUE
	animation_player.play("destroy")
