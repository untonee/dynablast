class_name Player extends CharacterBody2D

@export var speed := 60.0 # скорость передвижения персонажа 
@export var explosionRadius = 3 # радиус взрыва установленной бомбы
@export var maxBomb = 3 # количество действующих бомб которое игрок может установить
@export var tileSize := Vector2(16, 16) # размер тайлов в пикселях

const BOMB = preload("res://Bomb/bomb.tscn") #бомба

@onready var animation_player = $AnimationPlayer
@onready var sprite = $PlayerSprite
@onready var idle_timer = $IdleTimer 
@onready var step_audio_stream_player_2d: AudioStreamPlayer2D = $StepAudioStreamPlayer2D
@onready var die_audio_stream_player_2d: AudioStreamPlayer2D = $DieAudioStreamPlayer2D

@onready var label: Label = $Label


# 	PlayerStates - возможные действия игрока
# 	MovingStates - для напрвелнеи движение - для анимации движения
enum PlayerStates { IDLE, MOVING, DANCING, DIE, WIN, PUT_BOMB, DOWNTIME }
enum MovingStates { LEFT, RIGHT, UP, DOWN, IDLE }

# инициализация действия и анимации игрока по умолчанию 
var player_state : PlayerStates = PlayerStates.IDLE 
var moving_state : MovingStates = MovingStates.IDLE 

var velocity_local = Vector2.ZERO

func _ready():
	animation_player.play(get_new_animation())
	position = GlobalFunc.snap_to_grid(position)
	
func _physics_process(delta: float) -> void:
	handle_state(delta)

	move_and_slide()
	
	velocity = Vector2.ZERO
	
	label.text = str("X, Y: %d, %d " % [global_position.x, global_position.y])
	
	
# отслеживание действий игрока - нажатие кнопок	
func handle_state(delta: float):
	velocity_local = Vector2.ZERO
	
	# персонажем(player) можно управлять только если он IDLE или MOVING, DOWNTIME
	if (player_state == PlayerStates.DOWNTIME) or (player_state == PlayerStates.MOVING) or (player_state == PlayerStates.IDLE):
		
		moving_state = MovingStates.IDLE
		player_state = PlayerStates.IDLE
		
		if Input.is_action_pressed("right"):
			velocity_local.x = 1
			player_state = PlayerStates.MOVING
			moving_state = MovingStates.RIGHT
		
		if Input.is_action_pressed("left"):
			velocity_local.x = -1
			player_state = PlayerStates.MOVING
			moving_state = MovingStates.LEFT
	
		if Input.is_action_pressed("up"):
			velocity_local.y = -1
			player_state = PlayerStates.MOVING
			moving_state = MovingStates.UP
	
		if Input.is_action_pressed("down"):
			velocity_local.y = 1
			player_state = PlayerStates.MOVING
			moving_state = MovingStates.DOWN
		
		# действия при установке бомбы
		if Input.is_action_just_pressed("bomb"):
			var bomb := BOMB.instantiate() as BombComponent
			bomb.global_position = GlobalFunc.snap_to_grid(global_position, GlobalVar.tile_size)
			bomb.set_as_top_level(true)
			add_child(bomb, true)
			
	velocity_local.x *= speed
	velocity_local.y *= speed
 	
	velocity = velocity_local * delta * speed
	 
	var animation = get_new_animation()
	
	if animation != animation_player.current_animation:
		animation_player.play(animation)

# возвращает строку анимации в соостветствии с PlayerStates и MovingStates
func get_new_animation():
	var new_animation : String
	
	match player_state:
		
		PlayerStates.IDLE:
			new_animation = "idle"
		PlayerStates.DIE:
			new_animation = "die"
			
		PlayerStates.MOVING:
			match moving_state:
				MovingStates.UP:
					new_animation = "up"
				MovingStates.DOWN:
					new_animation = "down"
				MovingStates.LEFT:
					new_animation = "left"
				MovingStates.RIGHT:
					new_animation = "right"
				MovingStates.IDLE:
					new_animation = "idle"
					
		PlayerStates.PUT_BOMB:
			new_animation = "idle"
			
	return new_animation	

func _on_monitor_area_2d_body_entered(body: Node2D) -> void:
	player_state = PlayerStates.DIE


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	position = Vector2(120, 120)
	player_state = PlayerStates.MOVING
