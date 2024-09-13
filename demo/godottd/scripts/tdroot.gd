extends Node3D

class_name TDRoot

# Temporary signals used by some scenes
signal previous
signal next

### System config
var projector : int = -1
var config : Dictionary = GodotTD.config
var server_ip = config["server_ip"]

### System states
@export var test_local : bool = false
var is_server : bool = false
var do_warping : bool = false
var mouse_capture = 1

### Window setup
var window_width
var window_height
var window_pos : Vector2i

### Tiled display calibration
var calibration : CalibrationData = null
var aspect
var material : ShaderMaterial = null
@onready var shader_viewport = preload("res://godottd/shader/cave_viewport.gdshader")
@onready var shader_server = preload("res://godottd/shader/cave_server.gdshader")

### Headtracking
var eye_dir : Vector3 = Vector3(0.0, 0.0, -1.0)
var headtracking:bool = false

### Network management
# High level multiplayer
var peer : ENetMultiplayerPeer
var peers = []
var peer_address = {}
var peer_lost = {}
var reconnect_timer : Timer = null
# TCP event messages
var server = null

### Important nodes
var scene : Node
var current_scene : String = ""
var origin : Node3D
var camera : Camera3D
var environment : Environment
var sky : MeshInstance3D
var vrpn : VRPNServer
		
# Prepare calibration data and window settings on start
func _init():
	# Projector id and window position can be specified using cmd arguments
	# order: window_x, window_y, projector_id, window_width, window_height, mouse_capture
	var args = OS.get_cmdline_args()
	var px = 0
	var py = 0
	
	# TODO: remove resolution from calibration formula
	var wx = 1920
	var wy = 1080
	
	# Window position
	if( len(args) >= 2 ):
		px = float(args[0])
		py = float(args[1])
	
	# Projector id
	if( len(args) >= 3 ):
		projector = int(args[2])
		
	# Window size
	if( len(args) >= 5 ):
		wx = int(args[3])
		wy = int(args[4])
		
	# Do mouse capture
	if len(args) >= 6:
		mouse_capture = int(args[5])
	
	# Init the window
	window_width = wx
	window_height = wy
	window_pos = Vector2i(px,py)
	
	DisplayServer.window_set_size(Vector2i(wx, wy))
	DisplayServer.window_set_position(Vector2i(px,py))
	
	# Load calibration depending on the projector id
	print("Projector: ",projector)
	calibration = CalibrationData.new()
	calibration.load_calibration(config["calibration_path"]+config["calibration_file"], projector)
	
	# Positive projector id represents a specific client, while -1 indicate the server instance
	if projector >= 0:
		do_warping = true
	else:
		mouse_capture = 0
		is_server = true
		
	# Capture mouse on clients if not disabled
	if not is_server and mouse_capture == 1:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Called when the node enters the scene tree for the first time.
func _ready():
	### Find important nodes
	scene = get_node("ViewportContainer/Viewport/SceneRoot")
	origin = scene.get_node("TDOrigin")
	camera = origin.get_node("Camera")
	environment = scene.get_node("WorldEnvironment").environment
	sky = origin.get_node("SkySphere")
	material = $ViewportContainer.get_material()
	vrpn = scene.get_node("VRPNServer")
	
	### Update window parameters
	DisplayServer.window_set_size(Vector2i(window_width, window_height))
	DisplayServer.window_set_position(window_pos)
	
	### Initialize tiled display calibration
	if calibration:
		camera.position = calibration.eye
	
	# The server will not use geometric or photometric calibration
	if is_server:
		$ViewportContainer/Viewport.size = Vector2(window_width, window_height)
		material.shader = shader_server
		
	# All cients have to initialze calibration parameters
	else:
		$Menu.visible = false
		
		aspect = calibration.frustum_size.y/calibration.frustum_size.x
		$ViewportContainer/Viewport.size = Vector2(window_width, ceil(window_width*aspect))
		
		# Some output for debugging
		print("frustum size, offset, near: ", calibration.frustum_size, ", ", calibration.frustum_offset, ", ", calibration.near)
		print("projection offset, scale: ", calibration.proj_offset, ", ", calibration.scale)
		print("viewport original: ", $ViewportContainer/Viewport.size)
		
		# TODO: Temporary workaround (gray pixel line at bottom)
		if $ViewportContainer/Viewport.size.y == 1079:
			$ViewportContainer/Viewport.size.y = 1080
		print("viewport new: ", $ViewportContainer/Viewport.size)
		
		# Load alphamask and apply all values to the shader
		var alphamask = calibration.load_alphamask(config["calibration_path"])
		if !alphamask:
			print("Failed to load alphamask!")
		material.set_shader_parameter("Hx", calibration.get_Hx())
		material.set_shader_parameter("Hy", calibration.get_Hy())
		material.set_shader_parameter("F", calibration.get_F())
		material.set_shader_parameter("offset", calibration.proj_offset)
		material.set_shader_parameter("scale", calibration.scale)
		material.set_shader_parameter("alphamask", alphamask)

		camera.rotate_y(calibration.camera_rotation.y)
		camera.rotation.x = calibration.camera_rotation.x
		
		# Finally setup the initial camera frustum
		update_frustum()
		
	### Setup network
	if test_local:
		server_ip = "localhost"
	
	# We use the multiplayer peer for high level messages (RPC calls
	peer = ENetMultiplayerPeer.new()
	var error_network : Error
	
	# The server starts a multiplayer server as well as a TCP message server
	if is_server:
		# Start the high level multiplayer
		print("Starting server...")
		error_network = peer.create_server(config["server_port"], config["server_max_clients"])
		peer.peer_connected.connect(_on_client_connected)
		peer.peer_disconnected.connect(_on_client_disconnected)
		
		var error
		server = TCPServer.new()
		error = server.listen(10011)
		if error != OK:
			print("Error creating TCP server:", error)
			
	# The client just connects to the multiplayer server
	else:
		print("Starting client...")
		error_network = peer.create_client(server_ip, config["server_port"])
		
		# We prepare a reconnect timer, it will be started from _process if connection lost
		reconnect_timer = Timer.new()
		add_child(reconnect_timer)
		reconnect_timer.one_shot = true
		reconnect_timer.timeout.connect(self._client_reconnect)
		
	# Finally check whether everything is fine
	if error_network == OK and peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Network connection established...")
	else:
		print("Failed to establish network connection!")
	multiplayer.multiplayer_peer = peer
	
	# Load the default scene
	if not test_local and config["scene_default"] != "":
		load_scene(config["scene_default"])
		
	
# We check for network status periodically
func _process(_delta):
	# The server listens for control events via TCP 
	# TODO: modernize legacy event message system
	if is_server:
		# New event message available
		if server.is_connection_available():
			var client_peer : StreamPeerTCP = server.take_connection()
			var bytes = client_peer.get_available_bytes()
			var data = client_peer.get_data(bytes)
			var packet = PackedByteArray(data[1]).get_string_from_ascii().split("\n")
			
			var cmd = packet[0]
			var value = packet[1].split(" ")[1]
			print("Received network command: ", cmd, value)
			
			# Process the recieved message
			if cmd == "go":
				if value == "-1":
					previous.emit()
				elif value == "1":
					next.emit()
			elif cmd == "SET_PLUGIN":
				reset_head()
				load_scene(value)
			elif cmd == "warping":
				#rpc("set_calibration",value=="1")
				$Menu/MenuLayout/Warping.button_pressed = value=="1"
			elif cmd == "alphamasks":
				#rpc("set_alphamask",value=="1")
				$Menu/MenuLayout/Alphamasks.button_pressed = value=="1"
			elif cmd == "DTrackFilter::setHeadTracking()":
				#rpc("set_headtracking",value=="1")
				$Menu/MenuLayout/Headtracking.button_pressed = value=="1"
			elif cmd == "audio":
				set_audio(int(value)==0)
	else:
		# If we are a client and lost connection, try to reconnect every 2 seconds
		var status = peer.get_connection_status()
		if status == ENetMultiplayerPeer.CONNECTION_DISCONNECTED and reconnect_timer.is_stopped():
			print("checking connection...")
			reconnect_timer.start(2.0)

func _input(_event):
	pass

func _exit_tree():
	pass

# A new client connected
func _on_client_connected(id:int):
	peers.append(id)
	peer_address[id] = peer.get_peer(id).get_remote_address()
	print("Client ",id," (", peer_address[id], ") connected")
	
	#rpc_id(id, "load_scene", current_scene)

# We lost a client
func _on_client_disconnected(id:int):
	print("Client ",id," (", peer_address[id], ") disconnected")
	peers.erase(id)
	
# Called by the client's reconnect timer
func _client_reconnect():
	var status = peer.get_connection_status()
	if status == ENetMultiplayerPeer.CONNECTION_CONNECTED:# or ENetMultiplayerPeer.CONNECTION_CONNECTING:
		print("connection fine?")
		return
	
	print("Disconnected, try to reconnect... ")
	peer.close()
	var error_network = peer.create_client(server_ip, config["server_port"])
	if error_network == OK and peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("Network connection established...")
	else:
		print("Failed to establish network connection!")
	
@rpc("call_remote", "reliable")
func load_scene(scene_name:String):
	if server:
		rpc("load_scene", scene_name)
	
	# Cancel if scene already loeded?
	if current_scene == scene_name or scene_name == "":
		return
		
	# Load packaged Godot project
	print("Loading scene ",scene_name,"...")
	var success = ProjectSettings.load_resource_pack(config["scene_path"]+scene_name)

	if success:
		# Currently the start scene has to be named demo
		var imported_scene = load("res://demo.tscn")
		
		# Cancel scene loading otherwise
		if not imported_scene:
			push_error("Failed to load demo.tscn from scene package '"+scene_name+"'!")
			return
			
		# Remove existing scene
		if scene.has_node("Demo"):
			var node = scene.get_node("Demo")
			#if node.has_method("_finish"):
			#	node._finish()
			scene.remove_child(node)
			node.queue_free()
			print("removed demo")
		
		# We hide the flystick by default and reset settings
		origin.get_node("Flystick").visible = false
		sky.visible = false
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_energy = 1.0
		set_audio(0)
		current_scene = scene_name
		
		# Finally add the scene
		scene.add_child(imported_scene.instantiate())

# Convert calibration parameters to match Godot's frustum camera settings
func update_frustum():
	eye_dir = Vector3(calibration.frustum_offset.x, calibration.frustum_offset.y, -calibration.near).normalized()
	eye_dir = (camera.transform * eye_dir).normalized()
	
	camera.projection = Camera3D.PROJECTION_FRUSTUM
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	
	camera.set_frustum(calibration.frustum_size.x*2.0*aspect, calibration.frustum_offset, calibration.near, 500.0)

## -----------------------------------------------------------
## Events synchronized via RPC calls
@rpc("call_remote", "reliable")
func exit():
	if is_server:
		rpc("exit")
	get_tree().quit()
	
@rpc("call_remote")
func update_camera(new_position:Vector3):
	camera.position = new_position
	calibration.eye = new_position
	#print(calibration.eye)
	if !is_server:
		calibration.calculate_frustum()
		update_frustum()
	else:
		rpc("update_camera", new_position)

@rpc("call_remote")
func update_head_transform(new_transform:Transform3D):
	origin.transform = new_transform
	if is_server:
		rpc("update_head_transform", new_transform)

@rpc("call_remote")
func update_head(new_position:Vector3):
	origin.position = new_position
	if is_server:
		rpc("update_head", new_position)
		
func reset_head():
	origin.position = Vector3(0,0,0)
	origin.rotation = Vector3(0,0,0)
	update_head_transform(origin.transform)
	update_camera(calibration.eye_default)
	#$ViewportContainer/Viewport/scene/VRPNController.base_pos = calibration.eye_default
	vrpn.offset = Vector3(0.0,0.0,0.0)

func set_headtracking(enabled:bool):
	headtracking = enabled
	if !enabled:
		reset_head()
	
@rpc("call_remote")
func update_transform(path:String, new_transform:Transform3D):
	get_node("ViewportContainer/Viewport/scene/"+path).transform = new_transform
	if is_server:
		rpc("update_transform", path, new_transform)
	
@rpc("call_remote", "reliable")
func update_visibility(object:Node3D, visibility:bool):
	object.visible = visibility
	if is_server:
		rpc("update_visibility", object, visibility)

@rpc("call_remote", "reliable")
func set_calibration(enabled:bool):
	if !is_server:
		if enabled:
			material.shader = shader_viewport
		else:
			material.shader = shader_server
	else:
		rpc("set_calibration", enabled)

@rpc("call_remote", "reliable")
func set_alphamask(enabled:bool):
	if !is_server:
		if enabled:
			material.set_shader_parameter("alphamask_hide", 0.0)
		else:
			material.set_shader_parameter("alphamask_hide", 1.0)
	else:
		rpc("set_alphamask", enabled)
		
@rpc("call_remote", "reliable")
func set_sky(enabled:bool):
	sky.visible = enabled
	if is_server:
		rpc("set_sky", enabled)
			
@rpc("call_remote", "reliable")
func set_ambient_light(enabled:bool, energy:float=1.0):
	if enabled:
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	else:
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	environment.ambient_light_energy = energy
	if is_server:
		rpc("set_ambient_light", enabled)
		
@rpc("call_remote", "reliable")
func set_audio(enabled:bool):
	AudioServer.set_bus_mute(0, !enabled)
	if is_server:
		rpc("set_audio", enabled)

@rpc("call_remote", "reliable")
func _on_debug_draw_item_selected(index):
	$ViewportContainer/Viewport.debug_draw = index
	if is_server:
		rpc("_on_debug_draw_item_selected", index)

func _on_ambient_value_changed(value):
	set_ambient_light($Menu/MenuLayout/AmbientLight.button_pressed, value)

@rpc("call_remote", "reliable")
func _on_ssao_toggled(button_pressed):
	environment.ssao_enabled = button_pressed
	if is_server:
		rpc("_on_ssao_toggled", button_pressed)

@rpc("call_remote", "reliable")
func _on_global_ilumination_toggled(button_pressed):
	environment.sdfgi_enabled = button_pressed
	if is_server:
		rpc("_on_global_ilumination_toggled", button_pressed)
		
@rpc("call_remote", "reliable")
func _on_glow_toggled(button_pressed):
	environment.glow_enabled = button_pressed
	if is_server:
		rpc("_on_glow_toggled", button_pressed)
		
@rpc("call_remote", "reliable")
func _on_volumetric_fog_toggled(button_pressed):
	environment.volumetric_fog_enabled = button_pressed
	if is_server:
		rpc("_on_volumetric_fog_toggled", button_pressed)

func _on_ambient_light_toggled(button_pressed):
	set_ambient_light(button_pressed, $Menu/MenuLayout/HSlider.value)
