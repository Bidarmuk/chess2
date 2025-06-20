extends Node

@onready var game = get_parent()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var viewport = get_viewport()
		var camera = viewport.get_camera_3d()
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 100
		var space_state = viewport.world_3d.direct_space_state
		var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
		
		if result:
			var click_pos = world_to_grid(result.position)
			print("Clicked at: ", click_pos)
			
			if game.pieces.has(click_pos):
				var piece = game.pieces[click_pos]
				# Получаем имя типа через метод самого piece
				print("Selected: ", piece.get_type_name(), " at ", piece.grid_position)

func world_to_grid(world_pos: Vector3) -> Vector2:
	return Vector2(floor(world_pos.x), floor(world_pos.z))
