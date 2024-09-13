extends VRPNController

class_name VRPNServer

## Subscriber management
# TODO: merge device tracking and other trackers?
var devices : Dictionary = {}
var tracker : Dictionary = {}
var sub_input_analog = []
var sub_input_buttons = []

## Helping variables for navigation
var is_panning : bool = false
var offset = Vector3()
var rotate_start_head : Quaternion
var rotate_start_device : Quaternion

## References for quick access
@onready var Origin = GodotTD.origin

# Called when the node enters the scene tree for the first time.
func _ready():
	if GodotTD.is_server:
		#base_pos = cave.calibration.eye_default
		#base_quat = Origin.quaternion
		print("Initialize tracking...")
		self.init(GodotTD.config["vrpn_system"], GodotTD.config["vrpn_ip"], GodotTD.config["vrpn_port"])
		
		self.poll()
	else:
		# Clients don't have to manage VRPN events
		set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if GodotTD.is_server:
		self.poll()

func register_device(device : TrackingDevice):
	devices[device.id] = device
	
func register_tracker(device : TrackingDevice):
	tracker[device.id] = device
	
func register_input_analog(device : TrackingDevice):
	sub_input_analog.append(device)
	
func register_input_buttons(device : TrackingDevice):
	sub_input_buttons.append(device)
	
func start_panning(device_quat : Quaternion):
	rotate_start_device = device_quat
	rotate_start_head = Origin.quaternion
	self.is_panning = true
	
func stop_panning():
	self.is_panning = false

# Move the main camera (target in tracking coordinates)
func player_move(target : Vector3, velocity : float, multiplier : float):
	if is_panning:
		return
		
	# Apply Origin rotation to get the actual target direction
	target = (target * Origin.quaternion.inverse()).normalized()
	offset = target * velocity * multiplier

	GodotTD.tiled_display.update_head(Origin.position+offset)
	
# User is rotating using a pointing device
func update_pan(quat : Quaternion):
	if is_panning:
		Origin.quaternion = rotate_start_head * rotate_start_device * quat.inverse()
		GodotTD.tiled_display.rpc("update_head_transform", Origin.transform)

# Discrete rotation
func player_rotate(angle : float):
	Origin.rotate_y(angle)
	GodotTD.tiled_display.rpc("update_head_transform", Origin.transform)

# Joystick (thumbstick) button event
func _on_vrpn_controller_analog_changed(_num_channels, channels):
	# Notify subscribers
	for d in sub_input_analog:
		d.update_analog(channels)

# Discrete button event
func _on_vrpn_controller_button_pressed(button, pressed):
	# Notify subscribers
	for d in sub_input_buttons:
		d.update_button(button, pressed)

# A tracker movement was detected
func _on_vrpn_controller_tracker_changed(sensor, tracker_pos, tracker_quat):
	#print("TRACKER: ", sensor, tracker_pos, tracker_quat)
	var temp_pos = Vector3(tracker_pos.x, tracker_pos.z, -tracker_pos.y)
	var temp_quat = Quaternion(tracker_quat.x, tracker_quat.z, -tracker_quat.y, tracker_quat.w)
	var d : TrackingDevice = null
	
	# Trigger passive trackers
	if tracker.has(sensor):
		d = tracker[sensor]
		d.update_transform(temp_pos, offset, temp_quat)
	
	# Notify subscribing devices
	if devices.has(sensor):
		d = devices[sensor]
		d.update_transform(temp_pos, offset, temp_quat)
		
