extends Node3D

## Base class for all tracking devices
class_name TrackingDevice

signal analog_changed(channels)
signal button_changed(button, pressed)
signal moved

# Identification in VRPN system
@export var id : int = -1

# Keep track of last updates
var analog_channels : Array = []
var buttons : Dictionary = {}

func update_analog(channels : Array):
	analog_channels = channels
	analog_changed.emit(channels)
	
func update_button(button : int, pressed : bool):
	buttons[button] = pressed
	button_changed.emit(button, pressed)

func update_transform(pos : Vector3, offset : Vector3, quat : Quaternion):
	position = pos
	quaternion = quat
	moved.emit()
