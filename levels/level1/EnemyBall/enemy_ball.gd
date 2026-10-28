extends CharacterBody2D

# интеллект шарика - это его поведние на уровне
# шарик видет только то, что вокруг него с помощью
# четырех Area2D. Сталкиваясь с препядствием, он меняет
# случайно направление движения в зависимости от того, где свободна клетка
# в алгоритме есть таймер при срабаывании которого
# шарик случайно меняет направление, это добавляет эффект непредсказуемости

@onready var ball_change_dir_timer: Timer = $BallChangeDirTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var left_area_2d: Area2D = $LeftArea2D
@onready var right_area_2d: Area2D = $RightArea2D
@onready var up_area_2d: Area2D = $UpArea2D
@onready var down_area_2d: Area2D = $DownArea2D

enum MOVE_STATE { UP, DOWN, LEFT, RIGHT, IDLE }

@export var idle_time := 30.0 # время в секунда когда шарик случайно выберет новое направление
@export var speed := 30.0 # скорость передвижения шарика
@export var pos : Vector2 

var cur_move_state := MOVE_STATE.IDLE
var dying := false # враг уже умирает (попадание волны) - не двигается и не убивает игрока

## очки за уничтожение этого врага взрывом
const SCORE_VALUE := 100

func _ready() -> void:
	position = pos
	ball_change_dir_timer.wait_time = randf_range(1.0, idle_time) # разнесём старт таймеров врагов по времени
	animation_player.play("walk")

func _physics_process(delta: float) -> void:
	if dying:
		return
	ball_ai(delta)
	move_and_slide()
	
func ball_ai(delta: float) -> void:	
	match cur_move_state:
		MOVE_STATE.UP:
			velocity = Vector2.UP * speed
			
		MOVE_STATE.DOWN:
			velocity = Vector2.DOWN * speed
			
		MOVE_STATE.LEFT:
			velocity = Vector2.LEFT * speed
			
		MOVE_STATE.RIGHT:
			velocity = Vector2.RIGHT * speed
			
		MOVE_STATE.IDLE:
			velocity = Vector2.ZERO

	if ball_change_dir_timer.is_stopped():
		think_what_todo(cur_move_state)
		ball_change_dir_timer.start()

# подумаем куда идти дальше?
# проверим куда мы шли
# проверим куда можно идити
# удалим из возможны направлений то в котором уже двигались
# выберем случайно одно из возможных направлений движения
# выравняем position EnemyBall по сетке
func think_what_todo(dir: MOVE_STATE) -> void:
	# в переменной храняться значеняи куда можно двинуться	  
	var can_move = [] ## допустимые значения: 0 - up, 1 - down, 2 - left, 3 - right,
	
	# заполним массив can_move значениями где нет препятствий
	if cur_move_state == dir:
		if !up_area_2d.has_overlapping_bodies():
			can_move.push_front(MOVE_STATE.UP)
		if !down_area_2d.has_overlapping_bodies():
			can_move.push_front(MOVE_STATE.DOWN)
		if !left_area_2d.has_overlapping_bodies():
			can_move.push_front(MOVE_STATE.LEFT)
		if !right_area_2d.has_overlapping_bodies():
			can_move.push_front(MOVE_STATE.RIGHT)
		
		# исключим из массива движение в уже существующем направлении
		# к примеру, если двигался вверх, то исключим возможность движения ещё раз вверх
		can_move.erase(cur_move_state)
			
		if can_move.is_empty():
			print_debug("!!! ERROR ball - can't make movement.")
			cur_move_state = MOVE_STATE.IDLE
		else:
			cur_move_state = can_move.pick_random()
			

# уничтожение врага взрывной волной (вызывается из обработчиков Area2D)
func kill_by_wave() -> void:
	if dying:
		return
	dying = true
	GlobalVar.score += SCORE_VALUE
	velocity = Vector2.ZERO
	cur_move_state = MOVE_STATE.IDLE
	animation_player.play("die")
	# после проигрывания анимации смерти удаляем врага из дерева;
	# сигнал tree_exited уровень использует для проверки условия победы
	var timer := get_tree().create_timer(animation_player.current_animation_length)
	timer.timeout.connect(queue_free)


func _on_left_area_2d_body_entered(body: Node2D) -> void:
	if String(body.name).begins_with("Wave"):
		kill_by_wave()
		return
	think_what_todo(MOVE_STATE.LEFT)

func _on_right_area_2d_body_entered(body: Node2D) -> void:
	if String(body.name).begins_with("Wave"):
		kill_by_wave()
		return
	think_what_todo(MOVE_STATE.RIGHT)

func _on_up_area_2d_body_entered(body: Node2D) -> void:
	if String(body.name).begins_with("Wave"):
		kill_by_wave()
		return
	think_what_todo(MOVE_STATE.UP)

func _on_down_area_2d_body_entered(body: Node2D) -> void:
	if String(body.name).begins_with("Wave"):
		kill_by_wave()
		return
	think_what_todo(MOVE_STATE.DOWN)


func _on_ball_idle_timer_timeout() -> void:
	pass
