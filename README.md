# Godot Tiled Display Framework

This repository contains a sample application intended as a framework to implement Godot (https://godotengine.org/) applications for distributed tiled displays (such as CAVEs). It is capable of handling high resolution tiled displays which use multiple overlapping projectors per screen. The provided demo can be used either as a base for custom applications or as a main application that loads requested scenes at runtime.

Most of the code is written in GDScript. Key components include calibration loading, camera frustum updates, tracking device handling, network synchronization and a post processing shader for non-linear geometric calibration (warping). Only the VRPN integration requires a small C++ extension with GDScript bindings. There are no platform dependencies but VRPN has to be compiled for your target platform. This framework is currently in use for the X-SITE CAVE at Freiberg university (https://tu-freiberg.de/en/vr).

See the included calibration file for a sample display configuration. Currently one window is used per instance but a multi-window approach will be added in the next version. Windows will then be spawned automatically depending on the number of specified projectors per client machine. 

This project has been tested with Godot 4.6 on Linux. Compilation was tested on Windows 11 as well. Read the information below about build environment setup on Windows.

See also https://github.com/bnlrnz/xsite_ue for an Unreal implementation that preceded this Godot framework.

## Preparing the VRPN client lib
The VRPN source code is available on GitHub: https://github.com/vrpn/vrpn/releases
The GodotTD framework was tested with VRPN client/server version **07.34**.

### Linux
Building the Python bindings will fail for VRPN 07.34 and Python >=3.9. You can disable the Python bindings if you don't need them. 

1. Open a terminal in the VRPN source directory
2. Run `mkdir build` and `cd build`
3. VRPN was built/tested with the following parameters: `cmake .. -DCMAKE_POLICY_VERSION_MINIMUM="3.5" -DVRPN_USE_GPM_MOUSE=OFF -DVRPN_BUILD_PYTHON_HANDCODED_3X=OFF`
4. Run `make`
5. Copy vrpn.a and quat.a to GodotTD/godottd-extension/lib

### Windows (Visual Studio Compiler)
1. Install Visual Studio 2022 (Community) and activate C++ desktop development
2. Install CMake and make sure to add it to your PATH variable
3. Open a powershell in the VRPN source directory
4. Run `mkdir build` and `cd build`
5. Run CMake `cmake .. -DCMAKE_POLICY_VERSION_MINIMUM="3.5" -G "Visual Studio 17 2022" -A x64`
6. Open the resulting VRPN.sln with Visual Studio 2022
7. Switch to Release mode
8. Change the project configuration for quat lib and Core VRPN Client lib to static runtime libraries:
	- Project Properties > C/C++ > Code Generation
	- For runtime library setting select the Multi Threaded /MT option
9. Build the Core VRPN Client lib (quat lib will be build as dependency)
10. Copy vrpn.lib and quat.lib to GodotTD/godottd-extension/lib

## Building and testing the extension
1. Clone the repository and update the submodules to add the godot-cpp dependency 
```Bash
git submodule update --init --recursive
```
2. Prepare static VRPN libraries for your platform (see [Preparing the VRPN client lib](#preparing-the-vrpn-client-lib))
3. Run **scons** to build the C++ extension:
```Bash
# For a debug version:
scons target=template_debug
```
4. Create a display config (demo/godottd/config/display_config.json). See the contained example file for details.

Depending on the targeted Godot version it may be necessary to checkout the appropriate godot-cpp version. Currently godot-cpp is configured for Godot >=4.5.

## Usage
### Modification of the demo project
Modify the demo application according to your needs and add the necessary content. If calibration files are to be bundled with the executable, be sure to add *\*.json* to the list of files to include.

### Exporting scenes
You can export any project for use with a main application (for example, the provided demo). No modifications are required to the exported scene. If necessary, you can add the *TDInterface* script to your project if you have to make changes to the default environment settings.
