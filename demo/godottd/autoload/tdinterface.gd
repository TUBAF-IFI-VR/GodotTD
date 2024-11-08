extends Node

class_name TDInterface

# Configuration data
const config_file = "res://godottd/config/display_config.json"
var config : Dictionary = {}

# References to essential tiled display components
var tiled_display : Node3D = null
var scene_root : Node3D = null
var vrpn = null
var origin : Node3D = null
var camera : Camera3D = null
var environment : Environment = null
var sky : MeshInstance3D = null

# Get methods for system states
var is_server : bool = false : get=_get_is_server
var headtracking : bool = false : get=_get_headtracking

func _get_is_server():
	if tiled_display:
		return tiled_display.is_server
	return false
	
func _get_headtracking():
	if tiled_display:
		return tiled_display.headtracking
	return false
	
# Load tiled display configuration on start
func _init():
	var file = FileAccess.open(config_file, FileAccess.READ)
	if file == null:
		print("Warning: The config file '"+config_file+"' does not exist!")
		print("\tYou can ignore this warning if you are testing your scene locally.")
		return

	var json = JSON.new()
	json.parse(file.get_as_text())
	config = json.data
	file.close()
	
# Called when the node enters the scene_root tree for the first time.
func _ready():
	tiled_display = get_node_or_null("/root/TDRoot")
	
	# If a tiled system is set up, find the important nodes
	if tiled_display:
		scene_root = tiled_display.get_node("ViewportContainer/Viewport/SceneRoot")
		vrpn = scene_root.get_node("VRPNServer")
		origin = scene_root.get_node("TDOrigin")
		camera = origin.get_node("Camera")
		environment = scene_root.get_node("WorldEnvironment").environment
		sky = origin.get_node("SkySphere")
		print("TDInterface initialized")
	
