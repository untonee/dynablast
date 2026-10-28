class_name Player extends CharacterBody2D

@export var speed := 60.0 # скорость передвижения персонажа (пикселей в секунду)

const BOMB = preload("res://Bomb/bomb.tscn") #бомба

@onready var animation_player = $AnimationPlayer
@onready var sprite = $PlayerSprite
@onready var idle_timer = $IdleTimer
@onready var step_audio_stream_player_2d: AudioStreamPlayer2D = $StepAudioStreamPlayer2D
@onready var die_audio_stream_player_2d: AudioStreamPlayer2D = $DieAudioStreamPlayer2D


#       PlayerStates - возможные действия игрока
#       MovingStates - для напрвелнеи движение - для анимации движения
enum PlayerStates { IDLE, MOVING, DANCING, DIE, WIN, PUT_BOMB, DOWNTIME }
enum MovingStates { LEFT, RIGHT, UP, DOWN, IDLE }

# инициализация действия и анимации игрока по умолчанию
var player_state : PlayerStates = PlayerStates.IDLE
var moving_state : MovingStates = MovingStates.IDLE

var velocity_local = Vector2.ZERO

## сигнал о том что игрок погиб (уровень подписывается на перерождение/конец игры)
signal died
## сигнал о том что смерть завершена (анимация доиграна или истёк DOWNTIME) - уровень списывает жизнь
signal death_finished

## время "простоя" после смерти, если анимация die не была доиграна (сек)
const DOWNTIME := 3.0

## стартовая позиция уровня (устанавливается уровнем при старте)
var spawn_position := Vector2(40, 40)

func _ready():
	animation_player.play(get_new_animation())
	position = GlobalFunc.snap_to_grid(position)
	idle_timer.timeout.connect(_on_idle_timer_timeout)

func _physics_process(delta: float) -> void:
	# после смерти управлением не занимаемся, ждём death_finished от уровня (respawn)
	if player_state == PlayerStates.DIE:
		return

	handle_state(delta)

	move_and_slide()

	velocity = Vector2.ZERO


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
			place_bomb()

	velocity_local.x *= speed
	velocity_local.y *= speed

	velocity = velocity_local * delta * speed

	var animation = get_new_animation()

	if animation != animation_player.current_animation:
		animation_player.play(animation)

## установка бомбы: учитываем лимит одновременно действующих бомб (GlobalVar.max_bomb)
func place_bomb() -> void:
	var bombs_count := 0
	for b in get_tree().get_nodes_in_group("bomb"):
		if b is BombComponent and not b.is_queued_for_deletion():
			bombs_count += 1
	if bombs_count >= GlobalVar.max_bomb:
		return

	var bomb := BOMB.instantiate() as BombComponent
	bomb.radius = GlobalVar.bomb_radius
	# ВАЖНО: добавляем бомбу в уровень (root), а НЕ child-ом игрока.
	# Иначе при queue_free() игрока (смерть/переход между уровнями) Godot удалит из
	# дерева и все его дочерние бомбы - взрыв "пропадал без волны". set_as_top_level
	# здесь не спасает: узел всё равно остаётся ребёнком игрока в дереве сцены.
	var level_root: Node = self
	while level_root.get_parent() is Node2D:
		level_root = level_root.get_parent()
	level_root.add_child(bomb)
	bomb.global_position = GlobalFunc.snap_to_grid(global_position, GlobalVar.tile_size)

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

## перерождение игрока на стартовой позиции
func respawn(at: Vector2 = Vector2.INF) -> void:
	if at != Vector2.INF:
		spawn_position = at
	player_state = PlayerStates.IDLE
	global_position = GlobalFunc.snap_to_grid(spawn_position, GlobalVar.tile_size)
	animation_player.play("idle")

## игрок погиб (коснулся врага или взрывной волны): запускаем анимацию смерти
func die() -> void:
	if player_state == PlayerStates.DIE:
		return
	player_state = PlayerStates.DIE
	animation_player.play("die")
	died.emit()
	idle_timer.wait_time = DOWNTIME # страховка: если анимация не доиграна, уровень всё равно получит death_finished
	idle_timer.start()

func _on_monitor_area_2d_body_entered(body: Node2D) -> void:
	if player_state == PlayerStates.DIE:
		return
	# смерть от взрывной волны списывает жизнь сразу - не ждём окончания анимации die
	if body is BombWave:
		player_state = PlayerStates.DIE
		animation_player.play("die")
		died.emit()
		death_finished.emit()
		return
	die()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"die":
		idle_timer.stop()
		death_finished.emit()

func _on_idle_timer_timeout() -> void:
	# таймер используется и как "downtime" после смерти
	if player_state == PlayerStates.DIE:
		death_finished.emit()
