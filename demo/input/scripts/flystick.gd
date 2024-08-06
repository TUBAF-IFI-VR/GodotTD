extends TrackingDevice

var vrpn : VRPNServer = null
var local_direction : Vector3 = Vector3(0.0, 0.0, -1.0)
var speed = 1.0

# The flysticks buttons
# Option buttons are sorted from left to right
enum Buttons {
	Trigger = 0,
	Option1 = 4,
	Option2 = 3,
	Option3 = 2,
	Option4 = 1,
	Thumbstick = 5
}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Check if a tiled display is available
	if GodotTD.tiled_display:
		# Register at the VRPN server
		vrpn = GodotTD.vrpn
		vrpn.register_device(self)
		vrpn.register_input_analog(self)
		vrpn.register_input_buttons(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if analog_channels.size() < 2:
		return
	
	# Fly forwards or backwards according to flystick orientation	
	if analog_channels[1] <= -0.1 or analog_channels[1] >= 0.1:
		vrpn.player_move(local_direction, analog_channels[1]**3, 	delta*speed)
		
	#if (analog_channels[0] <= -0.1 or analog_channels[0] >= 0.1) and buttons.has(0) and buttons[0]:
	#	vrpn.player_rotate(0.01 * delta)

#func update_analog(channels : Array):
#	super(channels)
	
# Button event
func update_button(button : int, pressed : bool):
	super(button, pressed)
	
	match button:
		Buttons.Trigger:
			if pressed:
				vrpn.start_panning(quaternion)
			else:
				vrpn.stop_panning()
				
		# Change speed
		Buttons.Option1:
			speed = 1.0;
		Buttons.Option2:
			speed = 2.0;
		Buttons.Option3:
			speed = 4.0;
		Buttons.Option4:
			speed = 8.0;

# Flystick moved, update panning if necessary
func update_transform(pos : Vector3, offset : Vector3, quat : Quaternion):
	super(pos, offset, quat)
	
	local_direction = Vector3(0.0, 0.0, -1.0) * quat.inverse()
	vrpn.update_pan(quaternion)
