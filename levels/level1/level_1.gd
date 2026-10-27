extends Node2D

## safe_brick_zone : Vector2i
## хранит в себе координаты от начала уровня до safe_brick_zone
## в которых не будут появляться кирпичи (сделано, что бы не замуровать персонажа)
## по умолчанию = 4, 4
@export var safe_brick_zone := Vector2i(4, 4) # зона где не будут появляться враи и кирпичи от начала уровня считается
@onready var level_grass: TileMapLayer = $LevelGrass
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


const BRICK = preload("res://levels/level1/BrickWall/brick.tscn")
const ENEMY_BALL = preload("uid://dblbex7sf2rqs") 

func _ready() -> void:
	generate_bricks_enemies(22, Vector2(13, 11), 3)
	audio_stream_player_2d.play()
	
## generate_bricks_enemies(num: int, size: Vector2, enemies := 3) -> void:
## num - кол-во крипичей
## size - размер прямоуголного поля для размещения задается в клетках
## enemies - кол-во врагов
func generate_bricks_enemies(num: int, size: Vector2, enemies := 3) -> void:
	
	var bricks_arr = [] # хранит координаты кирпичей, чтобы в дальнейшем туда не ставить врагов
	
	# генерим крипичи
	var nx: int = randi_range(safe_brick_zone.x, size.x + 1)
	var ny: int = randi_range(safe_brick_zone.y, size.y + 1)
	
	var data = level_grass.get_cell_tile_data(Vector2(nx, ny))
	
	var b
	
	for n in range(0, num):
		var alldone := false
		
		while alldone == false:
			nx = randi_range(safe_brick_zone.x, size.x + 1)
			ny = randi_range(safe_brick_zone.y, size.y + 1)
						
			data = level_grass.get_cell_tile_data(Vector2(nx, ny))
			
			if data != null:
				alldone = true

		b = BRICK.instantiate()
		b.pos = Vector2(nx * GlobalVar.tile_size.x + GlobalVar.tile_size.x / 2, ny * GlobalVar.tile_size.y + GlobalVar.tile_size.y / 2)
		bricks_arr.push_front(b.pos)
		
		add_child(b, true)
	
	# генерим врагов
	nx = randi_range(safe_brick_zone.x, size.x + 1)
	ny = randi_range(safe_brick_zone.y, size.y + 1)
	
	data = level_grass.get_cell_tile_data(Vector2(nx, ny))
	
	for n in range(0, enemies):
		var alldone := false
		
		while alldone == false:
			nx = randi_range(safe_brick_zone.x, size.x + 1)
			ny = randi_range(safe_brick_zone.y, size.y + 1)
						
			data = level_grass.get_cell_tile_data(Vector2(nx, ny))
			
			if data != null and !bricks_arr.has(Vector2(nx, ny)):
				alldone = true

		b = ENEMY_BALL.instantiate()
		b.pos = Vector2(nx * GlobalVar.tile_size.x + GlobalVar.tile_size.x / 2, ny * GlobalVar.tile_size.y + GlobalVar.tile_size.y / 2)
		bricks_arr.push_front(b.pos)
		
		add_child(b, true)
	
func _process(delta: float) -> void:
	
	
	# в случае нажатия action_1 выполним перерисовку кирпичных стен (BRICK)
	# старые удалим
	if Input.is_action_just_pressed("action_1"):
		# получим всем ноды
		var all_nodes = GlobalFunc.get_all_childs(get_tree().get_root())
		# найдём все ноды с названием Brick и удалим их
		for element in all_nodes:
			if String(element.name).begins_with("Brick"):
				element.queue_free()
		# отрисуем кирпичи
		generate_bricks_enemies(22, Vector2(13, 11), 3)

## func check_position()
## pos : координаты x, y
## area_size : размер прямоугольника проверяемой обаласти
## проверяет что находить в заданной области (body и area2d)
## возвращает null если ничего нет.
## иначе возвращает список обьектов
func check_position(pos: Vector2, area_size: Vector2):
	pass		
