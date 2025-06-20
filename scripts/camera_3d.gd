extends Camera3D

@export var acceler = 25.0
@export var moveSpeed = 5.0
@export var MouseSpeed = 300.0

var velocity = Vector3.ZERO
var lookAngle = Vector2(0,-90)

var is_free_look := false


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	if not is_free_look:
		return
		
	if Input.is_action_pressed("move_shift"):
		moveSpeed = 15.0
	if Input.is_action_just_released("move_shift"):
		moveSpeed = 5.0
		
	lookAngle.y = clamp(lookAngle.y, PI/ -2, PI / 2)
	set_rotation(Vector3(lookAngle.y, lookAngle.x, 0))
	var direction = updateDirection()
	if direction.length_squared() > 0:
		velocity += direction * acceler * delta
	if velocity.length() > moveSpeed:
		velocity = velocity.normalized() * moveSpeed
		
	translate(velocity * delta)
	
func _input(event):
	if event is InputEventMouseMotion and is_free_look:
		lookAngle -= event.relative / MouseSpeed
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_free_look = true
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				is_free_look = false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
func updateDirection():
	var dir = Vector3()
	if Input.is_action_pressed("move_forward"):
		dir += Vector3.FORWARD
	if Input.is_action_pressed("move_backward"):
		dir += Vector3.BACK
	if Input.is_action_pressed("move_left"):
		dir += Vector3.LEFT
	if Input.is_action_pressed("move_right"):
		dir += Vector3.RIGHT
	if Input.is_action_pressed("move_up"):
		dir += Vector3.UP
	if Input.is_action_pressed("move_down"):
		dir += Vector3.DOWN
	if dir == Vector3.ZERO:
		velocity = Vector3.ZERO
	
	return dir.normalized()
