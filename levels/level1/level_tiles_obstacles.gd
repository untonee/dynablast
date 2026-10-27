extends TileMapLayer

@onready var level_tiles: TileMapLayer = $"."

func _draw() -> void:	
	pass
	# рисует сетку 
	#var dx = level_tiles.position.x * 48
	#var dy = level_tiles.position.y * 48
	#
	#for x in range(dx, 1000, 16):
		#draw_line(Vector2(x, dy), Vector2(x, 2000), Color.AQUA, 0.34)
	#for y in range(dy, 1000, 16):
		#draw_line(Vector2(dx, y), Vector2(2000, y), Color.AQUA, 0.34)
