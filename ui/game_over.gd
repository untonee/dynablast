extends Control

## Экран Game Over: текущий счёт, место в таблице рекордов, топ-10 рекордов, кнопки управления

@onready var title_label: Label = $TitleLabel
@onready var score_label: Label = $ScoreLabel
@onready var ranks_label: Label = $RanksLabel
@onready var restart_button: Button = $Buttons/RestartButton
@onready var menu_button: Button = $Buttons/MenuButton

func _ready() -> void:
	title_label.text = "GAME OVER"
	score_label.text = "YOUR SCORE: %05d" % GlobalVar.score
	var idx := GlobalVar.high_scores.find("N%0*d" % [GlobalVar.HIGH_SCORE_DIGITS, GlobalVar.score])
	if idx >= 0:
		ranks_label.text = "HIGH SCORES (your place: #%d)\n%s" % [idx + 1, _format_scores()]
	else:
		ranks_label.text = "HIGH SCORES\n%s" % _format_scores()
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	restart_button.grab_focus()

func _format_scores() -> String:
	var s := ""
	for i in GlobalVar.high_scores.size():
		s += "%d. %s\n" % [i + 1, GlobalVar.high_scores[i].substr(1)]
	return s

## рестарт текущего уровня (сброс состояния делает level_1._ready -> reset_player_stats)
func _on_restart_pressed() -> void:
	GlobalVar.reset_player_stats(true)
	get_tree().reload_current_scene()

## возврат в главное меню (когда будет создан menu.tscn - поменять путь на res://ui/menu.tscn)
func _on_menu_pressed() -> void:
	GlobalVar.reset_player_stats(true)
	get_tree().change_scene_to_file("res://levels/level1/level1.tscn")
