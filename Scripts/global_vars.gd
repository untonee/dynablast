class_name GlobalVars extends Node

## размер тайла в пикселях (тайлы 16x16, визуальное увеличение достигается zoom камеры)
var tile_size := Vector2(16, 16)

## стартовое количество бомб, которые игрок может установить одновременно
const START_MAX_BOMB := 1
## стартовый радиус взрыва (в тайлах)
const START_RADIUS := 2
## стартовое количество жизней
const START_LIVES := 3
## максимальная длина строки рекорда (N + 5 цифр)
const HIGH_SCORE_DIGITS := 5

# ------- глобальное состояние игры (сохраняется между уровнями) -------
var lives := START_LIVES
var score := 0
var max_bomb := START_MAX_BOMB
var bomb_radius := START_RADIUS
var high_scores: Array = [] # массив строк "N00123"

func _ready() -> void:
	load_high_scores()

## сохранить рекорды в файл
func save_high_scores() -> void:
	var f = FileAccess.open("user://highscores.dat", FileAccess.WRITE)
	if f:
		for s in high_scores:
			f.store_line(s)

## загрузить рекорды из файла
func load_high_scores() -> void:
	high_scores.clear()
	if not FileAccess.file_exists("user://highscores.dat"):
		return
	var f = FileAccess.open("user://highscores.dat", FileAccess.READ)
	if f:
		while not f.eof_reached():
			var line = f.get_line().strip_edges()
			if line.length() > 1 and line[0] == "N":
				high_scores.append(line)

## добавить текущий счёт в таблицу рекордов, вернуть индекс записи или -1
## записи сортируются по убыванию счёта (индекс 0 - лучший рекорд)
func register_score() -> int:
	var entry := "N%0*d" % [HIGH_SCORE_DIGITS, score]
	high_scores.append(entry)
	high_scores.sort_custom(func(a, b): return a > b) # строки одинаковой длины -> лексикографическая сортировка = по убыванию счёта
	while high_scores.size() > 10:
		high_scores.pop_back()
	save_high_scores()
	return high_scores.find(entry)

@export_group("PowerUps")
## на сколько увеличивать лимит бомб за один бонус
@export var bomb_add_count := 1
## на сколько увеличивать радиус взрыва за один бонус
@export var radius_add_count := 1
## максимальный лимит бомб
@export var max_bomb_limit := 8
## максимальный радиус взрыва
@export var max_radius_limit := 8

## увеличить лимит бомб (подбираем бонус)
func add_bomb() -> void:
	max_bomb = min(max_bomb + bomb_add_count, max_bomb_limit)

## увеличить радиус взрыва (подбираем бонус)
func add_radius() -> void:
	bomb_radius = min(bomb_radius + radius_add_count, max_radius_limit)

## сброс параметров игрока для нового уровня / новой игры
func reset_player_stats(full := false) -> void:
	if full:
		lives = START_LIVES
		score = 0
		max_bomb = START_MAX_BOMB
		bomb_radius = START_RADIUS
