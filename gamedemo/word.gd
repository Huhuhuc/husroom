extends Node2D

@onready var tile_map: TileMap = $TileMap
@onready var camera_2d: Camera2D = $Player/Camera2D

func _ready() -> void:
	var used_rect := tile_map.get_used_rect().grow(-1)
	var tile_size := tile_map.tile_set.tile_size
	
	var map_left = used_rect.position.x * tile_size.x + tile_map.position.x
	var map_top = used_rect.position.y * tile_size.y + tile_map.position.y
	var map_right = (used_rect.position.x + used_rect.size.x) * tile_size.x + tile_map.position.x
	var map_bottom = (used_rect.position.y + used_rect.size.y) * tile_size.y + tile_map.position.y
	
	camera_2d.limit_left = map_left
	camera_2d.limit_top = map_top
	camera_2d.limit_right = map_right
	camera_2d.limit_bottom = map_bottom
	
	camera_2d.make_current()
	camera_2d.position = Vector2.ZERO
