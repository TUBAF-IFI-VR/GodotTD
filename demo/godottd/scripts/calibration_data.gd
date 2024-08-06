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

var center : Vector2
var size : float
var sizeV : float
var near : float
var offset : Vector2
var scale : Vector2
var camera_angle : Vector3

# Helper function to get Vector3 from JSON arrays
func to_vector3(array : Array) -> Vector3:
	return 	Vector3(array[0], array[1], array[2])
	
# Helper function to get Vector2 from JSON arrays
func to_vector2(array : Array) -> Vector2:
	return 	Vector2(array[0], array[1])
	
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
	# TODO: generalization of near plane for other tiled displays
	if projector_id < 12:
		wall_focus.x = (tl.z - eye.z) / wall["size"][0]
		camera_angle.y = PI/2
	elif projector_id < 18:
		wall_focus.x = (eye.z - tl.z) / wall["size"][0]
		camera_angle.y = -PI/2
	elif projector_id < 24:
		wall_focus.x = (eye.x - tl.x) / wall["size"][0]
	elif projector_id == 24:
		camera_angle.x = -PI/2
		wall_focus.x = (eye.x - tl.x) / wall["size"][0]
		wall_focus.y = (1.0 - (eye.z - tl.z) / wall["size"][1]) - 0.5
	
	var left = p1.x
	if p4.x < left: left = p4.x
	var right = p2.x
	if p3.x > right: right = p3.x
	var top = p1.y
	if p2.y < top: top = p2.y
	var bottom = p3.y
	if p4.y > bottom: bottom = p4.y
	
	offset = Vector2(left, top)
	scale = Vector2(right-left, bottom-top)
	
	
	center = Vector2(0.5*(right+left)-wall_focus.x, 0.5-0.5*(top+bottom)-wall_focus.y)
	#print(center, width, height)
	center = center * Vector2(width, height)
	size = 0.5*(right-left)*width
	sizeV = 0.5*(bottom-top)*height;
	
	# TODO: generalization of near plane for other tiled displays
	if projector_id < 12:
		near = -(wall["bounds"]["top_left"][0] - eye.x)
	elif projector_id < 18:
		near = wall["bounds"]["top_left"][0] - eye.x
	elif projector_id < 24:
		near = -(wall["bounds"]["top_left"][2] - eye.z)
	else:
		near = eye.y + 0.01
	near *= near_ratio

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
