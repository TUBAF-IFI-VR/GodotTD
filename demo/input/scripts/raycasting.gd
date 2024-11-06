extends RayCast3D

var DebugPoint = preload("res://scenes/debug_point.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

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
