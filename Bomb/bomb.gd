class_name BombComponent extends RigidBody2D

## Радиус взрыва считаем в тайлах
@export var radius := 4
## Обратный таймер взрыва бомбы
@export var countdown := 3.5 
## Скорость анимации волны
@export var anim_speed := 1


const BOMBWAVE = preload("res://Bomb/Wave/bombwave.tscn")

# таймер обратного отсчета
@onready var count_down_timer: Timer = $CountDownTimer

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@onready var left_detector_ray_cast_2d: RayCast2D = $LeftDetectorRayCast2D
@onready var right_detector_ray_cast_2d: RayCast2D = $RightDetectorRayCast2D
@onready var up_detector_ray_cast_2d: RayCast2D = $UpDetectorRayCast2D
@onready var down_detector_ray_cast_2d: RayCast2D = $DownDetectorRayCast2D

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


# переменные необходимые для рассчета длинны волны 
var tsx := GlobalVar.tile_size.x
var tsy := GlobalVar.tile_size.y
var halfx := tsx / 2 
var halfy := tsy / 2

func _ready() -> void:
	add_to_group("bomb")
	count_down_timer.start(countdown)
	# бросаем в 4 стороны лучи для определния препятствий:
	# луч влево
	var tp := Vector2(radius * tsx * -1, 0)
	left_detector_ray_cast_2d.position.x -= halfx - 1
	left_detector_ray_cast_2d.target_position = tp
	# луч вправо
	tp = Vector2(radius * tsx, 0)
	right_detector_ray_cast_2d.position.x += halfx - 1
	right_detector_ray_cast_2d.target_position = tp
	# луч вверх
	tp = Vector2(0, radius * tsy * -1)
	up_detector_ray_cast_2d.position.y -= halfy - 1
	up_detector_ray_cast_2d.target_position = tp
	# луч вниз
	tp = Vector2(0, radius * tsy)
	down_detector_ray_cast_2d.position.y += halfy - 1
	down_detector_ray_cast_2d.target_position = tp

# при окончании таймера взрываем бомбу 
func _on_count_down_timer_timeout() -> void:
	make_explosion()

## создание и отрисовка взрыва
## взрывная волна от бомбы не может проходить стены уровня и препятствия уровня, взрывная волна может накладываться на взрывную волну
## алгоритм работы
## кидаем луч в каждую сторону(влево, вправо, вверх, вних) на расстояние radius * GlobalVar.tile_size
## находим первое препятсивие и до него рисуем волну, если препятствия нет рисуем волну на весь radius
# "не заморачивался" с оптимизацией, просто написал, что бы работало 02.02.2026 22:28
func make_explosion() -> void:
	animated_sprite_2d.hide() #прячем бомбу, т.к. вместо нее будет рисовать эпицентр взрыва
	collision_shape_2d.disabled = true #отключаем столкновение бомбы, чобы луч не задетектил его
	count_down_timer.stop()

	# ВАЖНО: волны добавляем НЕ в саму бомбу, а в уровень (родитель бомбы).
	# Иначе queue_free() бомбы удалит из дерева и всех её детей: волны исчезнут
	# вместе с ней, body_entered не сработает и взрыв будет "без эффекта".
	var wave_parent := get_parent()
	if wave_parent == null:
		wave_parent = self
	
	# описание работы алгоритма отрисовки волны взрыва. Исходим из условия:  размер тайла равен 48*48
	# луч выпускается из середины клетки тайла
	# луч может столкнуться далее 24 пикселя
	# если столкновение проихошло дальше 24 пискселя считаем сколько клеток волны взрыва нужно отрисовать, 
	# в последней клетке рисуем конец волны взрыва.
	
	# переменные для отрисовки волны
	var p : Vector2 # точка до которой будет рисоваться взрывная волна
	var dist : Vector2 # расстояние от эпицентра взрыва до конца в пикселях
	var cells_int : Vector2i # расстояние в клетках от начала волны до конца
	var obj #обьект на оторый попал луч
	
	# отрисуем эпциентр взрыва
	var b = BOMBWAVE.instantiate() as BombWave
	b.name += "epicenter" 
	b.animation_name = "epicenter" 	
	b.anim_speed = anim_speed #скорость анимации
	wave_parent.add_child(b, true)

	#
	# рисуем ВЛЕВО волну взрыва
	#
#region полна влево
	obj = null
	p = Vector2(global_position.x - radius * tsx, global_position.y) # установим точку окончания рисования взрывной волны по умолчанию на длинну radius
	if left_detector_ray_cast_2d.is_colliding(): # если луч столкнулся укоротим волну
		p = left_detector_ray_cast_2d.get_collision_point() # получаем координаты в которой луч столкнулся 
	
		# если столкнулись с кирпичом добавим чтобы волны заходила на него
		obj = left_detector_ray_cast_2d.get_collider()
		if obj != null:
			if str(obj.name).find("Brick") != -1:
				p.x -= tsx
	
	dist = global_position - p # рассчитаем дистанцию от координат начала луча до обьекта с которым столнулся луч
	cells_int = dist / Vector2(tsx, tsy) # получаем целое количество клеток взрывной волны
		
	if cells_int.x >= 1: # убедимся что надо рисовать
		#отрисуем сначала конец волны	
		b = BOMBWAVE.instantiate() as BombWave
		b.name += "left" 
		b.global_position.x -= cells_int.x * tsx #сместим рисования от конца
		b.animation_name = "wave_end" 
		b.fliph = true
		b.anim_speed = anim_speed #скорость анимации
		wave_parent.add_child(b, true)
		
		# отрисуем по необходимости отстаток взрывной волны
		if cells_int.x >= 2:
			for w in range(1, cells_int.x):
				b = BOMBWAVE.instantiate()
				b.name += "left"
				b.global_position.x -= w * tsx
				b.animation_name = "wave_middle"
				b.fliph = true
				b.anim_speed = anim_speed
				wave_parent.add_child(b, true)
#endregion

	#
	# рисуем ВПРАВО волну взрыва
	#
#region волна вправо
	obj = null
	p = Vector2(global_position.x + radius * tsx, global_position.y) # установим точку окончания рисования взрывной волны по умолчанию на длинну radius
	if right_detector_ray_cast_2d.is_colliding(): # если луч столкнулся укоротим волну
		p = right_detector_ray_cast_2d.get_collision_point() # получаем координаты в которой луч столкнулся 

		# если столкнулись с кирпичом добавим чтобы волны заходила на него
		obj = right_detector_ray_cast_2d.get_collider()
		if obj != null:
			if str(obj.name).find("Brick") != -1:
				p.x += tsx
		
	dist = p - global_position  # рассчитаем дистанцию от координат начала луча до обьекта с которым столнулся луч
	cells_int = dist / Vector2(tsx, tsy) # получаем целое количество клеток взрывной волны
	
	if cells_int.x >= 1: # убедимся что надо рисовать
		#отрисуем сначала конец волны	
		b = BOMBWAVE.instantiate() as BombWave
		b.name += "right" 
		b.global_position.x += cells_int.x * tsx #сместим рисования от конца
		b.animation_name = "wave_end" 
		b.fliph = false
		b.anim_speed = anim_speed #скорость анимации
		wave_parent.add_child(b, true)
		
		# отрисуем по необходимости отстаток взрывной волны
		if cells_int.x >= 2:
			for w in range(1, cells_int.x):
				b = BOMBWAVE.instantiate()
				b.name += "right"
				b.global_position.x += w * tsx
				b.animation_name = "wave_middle"
				b.fliph = false
				b.anim_speed = anim_speed
				wave_parent.add_child(b, true)
#endregion
	
	#
	# рисуем ВНИЗ волну взрыва
	#
#region волна вниз
	obj = null
	p = Vector2(global_position.x, global_position.y + radius * tsy) # установим точку окончания рисования взрывной волны по умолчанию на длинну radius
	if down_detector_ray_cast_2d.is_colliding(): # если луч столкнулся укоротим волну
		p = down_detector_ray_cast_2d.get_collision_point() # получаем координаты в которой луч столкнулся 
		
		# если столкнулись с кирпичом добавим чтобы волны заходила на него
		obj = down_detector_ray_cast_2d.get_collider()
		if obj != null:
			if str(obj.name).find("Brick") != -1:
				p.y += tsy
		
	dist = p - global_position # рассчитаем дистанцию от координат начала луча до обьекта с которым столнулся луч
	
	cells_int = dist / Vector2(tsx, tsy) # получаем целое количество клеток взрывной волны
		
	if cells_int.y >= 1: # убедимся что надо рисовать
		#отрисуем сначала конец волны	
		b = BOMBWAVE.instantiate() as BombWave
		b.name += "down" 
		b.global_position.y += cells_int.y * tsy #сместим рисования от конца
		b.animation_name = "wave_end" 
		b.rot = 90
		b.anim_speed = anim_speed #скорость анимации
		wave_parent.add_child(b, true)
		
		# отрисуем по необходимости отстаток взрывной волны
		if cells_int.y >= 2:
			for w in range(1, cells_int.y):
				b = BOMBWAVE.instantiate()
				b.name += "down"
				b.global_position.y += w * tsy
				b.animation_name = "wave_middle"
				b.rot = 90
				b.anim_speed = anim_speed
				wave_parent.add_child(b, true)
#endregion

	#
	# рисуем ВВЕРХ волну взрыва
	#
#region волна ВВЕРХ
	obj = null
	p = Vector2(global_position.x, global_position.y - radius * tsy) # установим точку окончания рисования взрывной волны по умолчанию на длинну radius
	if up_detector_ray_cast_2d.is_colliding(): # если луч столкнулся укоротим волну
		p = up_detector_ray_cast_2d.get_collision_point() # получаем координаты в которой луч столкнулся 
		
		# если столкнулись с кирпичом добавим чтобы волны заходила на него
		obj = up_detector_ray_cast_2d.get_collider()
		if obj != null:
			if str(obj.name).find("Brick") != -1:
				p.y -= tsy
		
	dist = global_position - p # рассчитаем дистанцию от координат начала луча до обьекта с которым столнулся луч
	
	cells_int = dist / Vector2(tsx, tsy) # получаем целое количество клеток взрывной волны
		
	if cells_int.y >= 1: # убедимся что надо рисовать
		#отрисуем сначала конец волны	
		b = BOMBWAVE.instantiate() as BombWave
		b.name += "up" 
		b.global_position.y -= cells_int.y * tsy #сместим рисования от конца
		b.animation_name = "wave_end" 
		b.rot = -90
		b.anim_speed = anim_speed #скорость анимации
		wave_parent.add_child(b, true)
		
		# отрисуем по необходимости отстаток взрывной волны
		if cells_int.y >= 2:
			for w in range(1, cells_int.y):
				b = BOMBWAVE.instantiate()
				b.name += "up"
				b.global_position.y -= w * tsy
				b.animation_name = "wave_middle"
				b.rot = -90
				b.anim_speed = anim_speed
				wave_parent.add_child(b, true)
#endregion

	audio_stream_player_2d.play()
	queue_free() #бомба взорвалась - удаляем её (волны живут сами по себе)
