extends TrackingDevice

class_name Headtracker

var vrpn : VRPNServer = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# Check if a tiled display is available
	if GodotTD.tiled_display:
		# Register at the VRPN server
		vrpn = GodotTD.vrpn
		vrpn.register_device(self)

# Tracker moved, update origin if required
func update_transform(pos : Vector3, quat : Quaternion):
	super(pos, quat)
	
	# Currently origin tracking devices are competing
	if GodotTD.headtracking:
		var target = (Vector3(0,0,-1) * quat.inverse()).normalized()
		
		# TODO: Temporary fix, subtract 10cm to compensate offset of person's head axis and glasses
		pos -= 0.1*target
		
		# Trigger frustum update
		GodotTD.tiled_display.update_camera(pos)
