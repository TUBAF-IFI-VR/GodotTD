extends RayCast3D

var DebugPoint = preload("res://scenes/debug_point.tscn")

var selection = null
var last_collider = null
var dist = Vector3(0,0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	if not GodotTD.is_server:
		enabled = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not GodotTD.is_server:
		return
	
	if selection:
		selection.global_position = to_global(target_position) + dist
	else:
		if is_colliding() and get_collider().has_method("hover_start"):
			last_collider = get_collider()
			last_collider.hover_start.rpc()
		elif last_collider != null and last_collider.has_method("hover_end"):
			last_collider.hover_end.rpc()
			last_collider = null
	
func click(pressed:bool):
	if pressed:
		return
	
	if selection != null:
		selection = null
	else:
		if is_colliding():
			selection = get_collider()
			dist = selection.global_position - to_global(target_position)

# 'Draw' colored spheres if collision is detected
func paint():
	if is_colliding():
		var pos = get_collision_point()
		var point = DebugPoint.instantiate()
		point.name = "point"
		point.position = pos
		#print(pos)
		get_node("../../Spawn").add_child(point,true)


func _on_multiplayer_spawner_spawned(node):
	print("spawned node ",node.name)
