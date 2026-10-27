class_name GlobalFuncs extends Node

## snap_to_grid(pos: Vector2, tile_size := Vector2(48, 48))
## функция возвращает позицию обьекта привязаную к сетке
## pos - данные позиции обьекта
## tile_size - размер сетки
func snap_to_grid(pos: Vector2, tile_size := Vector2(16, 16)):
	var x = int(pos.x / tile_size.x) * tile_size.x + int(tile_size.x / 2)
	var y = int(pos.y / tile_size.y) * tile_size.y + int(tile_size.y / 2)
	
	return(Vector2(x, y))

## 	get_all_children(in_node, array := [])
## рекурсивная функция возвращает массив всех нодов от in_node
func get_all_childs(in_node, array := []):
	array.push_back(in_node)
	for child in in_node.get_children():
		array = get_all_childs(child, array)
	return array
