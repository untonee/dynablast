extends CanvasLayer

## HUD уровня: очки, жизни, лимит бомб, радиус взрыва + сообщения ("LEVEL CLEAR!")
## уровень управляет им через get_tree().call_group("hud", ...)

@onready var score_label: Label = $Panel/ScoreLabel
@onready var lives_label: Label = $Panel/LivesLabel
@onready var bombs_label: Label = $Panel/BombsLabel
@onready var radius_label: Label = $Panel/RadiusLabel
@onready var message_label: Label = $MessageLabel
@onready var flash_timer: Timer = $FlashTimer

func _ready() -> void:
	add_to_group("hud")
	message_label.visible = false
	flash_timer.timeout.connect(_on_flash_timer_timeout)
	update_all()

func _process(_delta: float) -> void:
	# очки меняются из brick/enemy_ball напрямую (GlobalVar.score), поэтому просто обновляем label
	score_label.text = "SCORE: %05d" % GlobalVar.score

func update_all() -> void:
	update_lives()
	update_bombs()
	update_radius()

func update_lives() -> void:
	lives_label.text = "LIVES: %d" % GlobalVar.lives

func update_bombs() -> void:
	bombs_label.text = "BOMBS: %d" % GlobalVar.max_bomb

func update_radius() -> void:
	radius_label.text = "RADIUS: %d" % GlobalVar.bomb_radius

## мигание счётчика жизней при гибели игрока
func flash_life() -> void:
	lives_label.modulate = Color(1, 0.2, 0.2)
	flash_timer.start()

func _on_flash_timer_timeout() -> void:
	lives_label.modulate = Color.WHITE

## показать крупное сообщение по центру экрана на 2 секунды
func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	get_tree().create_timer(2.0).timeout.connect(func(): message_label.visible = false)

## скрыть HUD (вызывается уровнем при Game Over / победе)
func hide_hud() -> void:
	$Panel.visible = false
	message_label.visible = false
