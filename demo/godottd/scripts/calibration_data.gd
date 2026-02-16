extends Object

class_name CalibrationData

# Data objects
var data
var wall : Dictionary
var camera : Dictionary
var client : Dictionary
var projector : Dictionary

# Near clipping plane can be in front of the screen
const near_ratio = 0.1

# Projector to use
var projector_id : int =-1

# Calibration and camera parameters
var eye : Vector3
var eye_default : Vector3

var frustum_offset : Vector2
var frustum_size : Vector2
var near : float
var proj_offset : Vector2
var scale : Vector2
var camera_rotation : Vector3

# Helper function to get Vector3 from JSON arrays
func to_vector3(array : Array) -> Vector3:
	return 	Vector3(array[0], array[1], array[2])
	
# Helper function to get Vector2 from JSON arrays
func to_vector2(array : Array) -> Vector2:
	return 	Vector2(array[0], array[1])
	
func calculate_orientation_angle(eye_dir:Vector3, v:Vector3) -> Array:
	var c = eye_dir.cross(v)
	return [atan2(c.length(), eye_dir.dot(v)),c]
	
func calculate_camera_orientation(eye_dir:Vector3, wall_normal:Vector3) -> Vector3:
	var orientation : Vector3
	#var proj_xy = Vector3(eye_dir.x, eye_dir.y, 0.0)
	#var proj_xz = Vector3(eye_dir.x, 0.0, eye_dir.z)
	var wall_xz = Vector3(wall_normal.x, 0.0, wall_normal.z)
	var wall_yz = Vector3(0.0, wall_normal.y, wall_normal.z)
	var res
	
	if wall_xz.length() > 0.0:
		res = calculate_orientation_angle(eye_dir, wall_xz)
		orientation.y = res[0]
		if res[1].y < 0.0:
			orientation.y = -orientation.y
	if wall_yz.length() > 0.0:
		res = calculate_orientation_angle(eye_dir, wall_yz)
		orientation.x = res[0]
		if res[1].x < 0.0:
			orientation.x = -orientation.x
	return orientation
	
# Calculate new camera frustum parameters
func calculate_frustum():
	# Godot does currently not allow arbitrary frustum setups using vertices
	# The necessary parameters have to be calculated
	# TODO: This still needs to be optimized!
	
	# Calculate center point
	var tl = to_vector3(wall["bounds"]["top_left"])
	#var br = to_vector3(wall["bounds"]["bottom_right"])
	var p1 = to_vector2(projector["corners"]["display_space"]["top_left"])
	var p2 = to_vector2(projector["corners"]["display_space"]["top_right"])
	var p3 = to_vector2(projector["corners"]["display_space"]["bottom_right"])
	var p4 = to_vector2(projector["corners"]["display_space"]["bottom_left"])
	
	var width = wall["size"][0]*near_ratio
	var height = wall["size"][1]*near_ratio
	#var wall_center = 0.5 * Vector2(width,height)
	#var wall_focus = Vector2(0.5,0.5)
	var wall_focus = Vector2(0.5,eye.y/wall["size"][1]-0.5)
	
	# We focus on a point on the screen perpendicular to the viewer
	# All frusta will be shifted related to this focus point
	# TODO: generalization of camera rotation
	# TODO: generalization of near plane for other tiled displays
	# X-SITE setup: projectors 0-11 left, 12-17 right, 18-23 front, 24 floor
	# Calculate camera orientation from display wall normal vector
	var n = to_vector3(wall["normal"]).normalized()
	print(n)
	var eye_dir = Vector3(0,0,1)
	camera_rotation = calculate_camera_orientation(eye_dir, n)
	near = 0.8
	if n.x > 0.0:		# Left wall
		wall_focus.x = (tl.z - eye.z) / wall["size"][0]
		near = -(wall["bounds"]["top_left"][0] - eye.x)
	elif n.x < 0.0:		# Right wall
		wall_focus.x = (eye.z - tl.z) / wall["size"][0]
		near = wall["bounds"]["top_left"][0] - eye.x
	elif n.y > 0.0:		# Floor
		wall_focus.x = (eye.x - tl.x) / wall["size"][0]
		wall_focus.y = (1.0 - (eye.z - tl.z) / wall["size"][1]) - 0.5
		near = eye.y + 0.01
	else:				# Front wall
		wall_focus.x = (eye.x - tl.x) / wall["size"][0]
		near = -(wall["bounds"]["top_left"][2] - eye.z)
	near *= near_ratio
	
	var left = p1.x
	if p4.x < left: left = p4.x
	var right = p2.x
	if p3.x > right: right = p3.x
	var top = p1.y
	if p2.y < top: top = p2.y
	var bottom = p3.y
	if p4.y > bottom: bottom = p4.y
	
	# Transform frustum corners into Godot's frustum camera parameters
	proj_offset = Vector2(left, top)
	scale = Vector2(right-left, bottom-top)
	
	# TODO: optimize parameter conversion!
	frustum_offset = Vector2(0.5*(right+left)-wall_focus.x, 0.5-0.5*(top+bottom)-wall_focus.y)
	#print(center, width, height)
	frustum_offset = frustum_offset * Vector2(width, height)
	frustum_size.x = 0.5*(right-left)*width
	frustum_size.y = 0.5*(bottom-top)*height;

# Load calibration data from a JSON file
func load_calibration(filename : String, new_projector_id : int) -> bool:
	# Read JSON file
	var file = FileAccess.open(filename, FileAccess.READ)
	if file == null:
		print("Failed to read calibration file '"+filename+"'!")
		return false
		
	var json = JSON.new()
	json.parse(file.get_as_text())
	data = json.data
	file.close()
	
	print(data["system"])
	self.projector_id = new_projector_id
	eye = to_vector3(data["eye"])
	eye_default = eye
	
	# The server does not use calibration
	if projector_id < 0:
		return true
	
	var success = false
	
	# Read all data if projector is contained in calibration file
	for w in data["walls"]:
		for c in w["clients"]:
			for p in c["projectors"]:
				if p["id"] == projector_id:
					success = true
					wall = w
					camera = wall["camera"]
					client = c
					projector = p
	
	if not success:
		print("Error parsing calibration file!")
		return false
		
	# Initialize frustum parameters
	calculate_frustum()
		
	print("Loaded calibration data successfully!")
	return true
	
# Load the projectors alphamask
func load_alphamask(path) -> CompressedTexture2D:
	var filename = path + "alphamasks/" + projector["alphamask"]
	var texture = load(filename)
	
	return texture
	
# Build the transformation matrix F
func get_F() -> Transform3D:
	var pF = camera["F"]
	var F = Transform3D()
	
	F.basis.x = Vector3(pF[0],pF[1],pF[2])
	F.basis.y = Vector3(pF[3],pF[4],pF[5])
	F.basis.z = Vector3(pF[6],pF[7],pF[8])
	
	return F
	
# Encode the 10 x coefficients in a 3x4 matrix
func get_Hx() -> Transform3D:
	var pH = projector["H_x"]
	var H = Transform3D()
	
	H.basis.x = Vector3(pH[0],pH[1],pH[2])
	H.basis.y = Vector3(pH[3],pH[4],pH[5])
	H.basis.z = Vector3(pH[6],pH[7],pH[8])
	H.origin = Vector3(pH[9],0,0)
	
	return H
	
# Encode the 10 y coefficients in a 3x4 matrix
func get_Hy() -> Transform3D:
	var pH = projector["H_y"]
	var H = Transform3D()
	
	H.basis.x = Vector3(pH[0],pH[1],pH[2])
	H.basis.y = Vector3(pH[3],pH[4],pH[5])
	H.basis.z = Vector3(pH[6],pH[7],pH[8])
	H.origin = Vector3(pH[9],0,0)
	
	return H
