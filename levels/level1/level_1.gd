extends Node2D

## safe_brick_zone : Vector2i
## хранит в себе координаты от начала уровня до safe_brick_zone
## в которых не будут появляться кирпичи (сделано, что бы не замуровать персонажа)
## по умолчанию = 4, 4
@export var safe_brick_zone := Vector2i(4, 4) # зона где не будут появляться враи и кирпичи от начала уровня считается

@onready var level_grass: TileMapLayer = $LevelGrass
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var player: Player = $Player

const BRICK = preload("res://levels/level1/BrickWall/brick.tscn")
const ENEMY_BALL = preload("uid://dblbex7sf2rqs")
const HUD = preload("res://ui/hud.tscn")
const GAME_OVER = preload("res://ui/game_over.tscn")

## стартовая позиция игрока (центр клетки тайла 2,2)
const PLAYER_SPAWN := Vector2(40, 40)

var enemies_left := 0 # сколько врагов ещё живо на уровне
var _game_over := false # игра окончена (что бы не плодить экраны Game Over)

func _ready() -> void:
	randomize()
	GlobalVar.reset_player_stats(true)
	generate_bricks_enemies(22, Vector2(13, 11), 3)
	audio_stream_player_2d.play()

	# игрок
	player.spawn_position = PLAYER_SPAWN
	player.died.connect(_on_player_died)
	player.death_finished.connect(_on_player_death_finished)

	# HUD
	var hud = HUD.instantiate()
	add_child(hud)

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
	enemies_left = 0
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
		# подписываемся на полное удаление врага из дерева (kill_by_wave -> анимация die -> queue_free)
		b.tree_exited.connect(_on_enemy_died)
		add_child(b, true)
		enemies_left += 1

## конец игры: сохраняем рекорд и показываем экран Game Over
func game_over() -> void:
	if _game_over:
		return
	_game_over = true
	audio_stream_player_2d.stop()
	GlobalVar.register_score()
	get_tree().call_group("hud", "hide_hud")
	var go = GAME_OVER.instantiate()
	add_child(go)

## игрок только что погиб
func _on_player_died() -> void:
	get_tree().call_group("hud", "flash_life")

## смерть игрока полностью завершена (анимация доиграна или истёк downtime)
func _on_player_death_finished() -> void:
	if _game_over:
		return
	GlobalVar.lives -= 1
	get_tree().call_group("hud", "update_lives")
	if GlobalVar.lives <= 0:
		game_over()
	else:
		player.respawn()

## враг полностью удалён из дерева (после анимации die) - проверяем условие победы
func _on_enemy_died() -> void:
	enemies_left -= 1
	if enemies_left <= 0 and not _game_over:
		# победа: бонус за оставшиеся жизни
		GlobalVar.score += GlobalVar.lives * 500
		get_tree().call_group("hud", "show_message", "LEVEL CLEAR!")
		get_tree().create_timer(2.0).timeout.connect(game_over)
