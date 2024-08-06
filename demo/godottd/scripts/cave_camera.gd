extends Node3D

@onready var cave : Node3D = get_node_or_null("/root/CAVE")

var camera_angle = 0.0
var mouse_sensitivity = 0.001

var velocity = Vector3()
var direction = Vector3()

const MOVE_SPEED = 10.0
const MOVE_ACCEL = 0.3
const ROTATE_SPEED = 0.002
var speed = 1.0
var tilt_mode = -1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var change_x = -event.relative.x * mouse_sensitivity*1.3
		var change_y = -event.relative.y * mouse_sensitivity
		
		rotation.y = rotation.y + change_x
		rotation.x = clamp(rotation.x + change_y, -1.5, 1.5)
	

func _physics_process(delta):
	if !cave or !cave.is_server:
		return
	# Reset direction
	direction = Vector3()
	var aim = global_transform.basis.z
	var side = global_transform.basis.x
	#var up = global_transform.basis.y
	
	var target_speed = 1.0
	#if Input.is_action_pressed("fast"):
	#	target_speed *= 3.0
	#if Input.is_action_pressed("superfast"):
	#	target_speed *= 6.0
	speed = speed + (target_speed - speed) * delta * 3.0 * MOVE_ACCEL;
	
	# Move forward and backward
	#var rotate_multiplier = sqrt(speed)
	#if Input.is_action_pressed("look_left"):
	#	rotation.y += ROTATE_SPEED * rotate_multiplier
	#elif Input.is_action_pressed("look_right"):
	#	rotation.y -= ROTATE_SPEED * rotate_multiplier
	#if Input.is_action_pressed("look_up"):
	#	rotation.x = clamp(rotation.x + ROTATE_SPEED * rotate_multiplier * tilt_mode, -1.5, 1.5)
	#elif Input.is_action_pressed("look_down"):
	#	rotation.x = clamp(rotation.x - ROTATE_SPEED * rotate_multiplier * tilt_mode, -1.5, 1.5)
	#if Input.is_action_just_released("reset_forward"):
	#	rotation.x = 0.0
	#if Input.is_action_just_released("reset_down"):
	#	rotation.x = -1.5
	#if Input.is_action_just_released("toggle_tiltmode"):
	#	tilt_mode *= -1.0
	
	direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	direction = (aim*direction.y) + (side*direction.x)
	#if Input.is_action_pressed("move_up"):
	#	direction += up
	#if Input.is_action_pressed("move_down"):
	#	direction -= up
	
	var target = direction * MOVE_SPEED * speed
	
	# accelerate
	global_translate(Vector3().lerp(target, MOVE_ACCEL * delta));
	cave.update_head_transform(transform)
	
	#velocity = velocity.linear_interpolate(target, MOVE_ACCEL * delta)
	
	# move the player
	#translate(velocity)
	
