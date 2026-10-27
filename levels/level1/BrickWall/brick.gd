extends RigidBody2D

@export var pos: Vector2
@export var anim: String

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var brick: RigidBody2D = $"."
@onready var label: Label = $Label

func _ready() -> void:
	global_position = pos
	animation_player.play("brick")
	label.text = str(pos)
