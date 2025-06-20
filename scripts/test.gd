extends Node3D

func _ready():
	print("=== ТЕСТИК ===")
	
	var camera = Camera3D.new()
	camera.position = Vector3(0, 2, 5)
	add_child(camera)
	
	camera.look_at(Vector3.ZERO)
	print("Камера")
	
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, 0, 0)
	add_child(light)
	print("Свет")
