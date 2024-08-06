# Godot Tiled Display Framework

This repository contains a sample application intended as a framework to implement Godot (https://godotengine.org/) applications for distributed tiled displays (such as CAVEs). It is capable of handling high resolution tiled displays which use multiple overlapping projectors per screen. The provided demo can be used either as a base for custom applications or as a main application that loads requested scenes at runtime.

Most of the code is written in GDScript. Key components include calibration loading, camera frustum updates, tracking device handling, network synchronization and a post processing shader for non-linear geometric calibration (warping). Only the VRPN integration requires a small C++ extension with GDScript bindings. There are no platform dependencies but VRPN has to be compiled for your target platform. This framework is currently in use for the X-SITE CAVE at Freiberg university (https://tu-freiberg.de/en/vr).

See the included calibration file for a sample display configuration. Currently one window is used per instance but a multi-window approach will be added in the next version. Windows will then be spawned automatically depending on the number of specified projectors per client machine. 

This project has been tested with Godot 4.1.4 on Linux. It will be updated to Godot 4.3 as soon as a stable 4.3 release is available. See also https://github.com/bnlrnz/xsite_ue for an Unreal implementation that preceded this Godot framework.

## Building
1. Clone the repository, update submodules to add the godot-cpp dependency and run **scons** to build the C++ extension:
```Bash
git submodule update --init --recursive

# For a debug version:
scons target=template_debug
```

Depending on the targeted Godot version it may be necessary to checkout the appropriate godot-cpp version.

2. Create a display config (demo/godottd/config/display_config.json). See the contained example file for details.

## Usage
### Modification of the demo project
Modify the demo application according to your needs and add the necessary content. If calibration files are to be bundled with the executable, be sure to add *\*.json* to the list of files to include.

### Exporting scenes
You can export any project for use with a main application (for example, the provided demo). No modifications are required to the exported scene. If necessary, you can add the *TDInterface* script to your project if you have to make changes to the default environment settings.
