extends PanelContainer

enum DebugDraw {DEBUG_DRAW_DISABLED = 0, \
DEBUG_DRAW_UNSHADED = 1,\
DEBUG_DRAW_LIGHTING = 2,\
DEBUG_DRAW_OVERDRAW = 3,\
DEBUG_DRAW_WIREFRAME = 4,\
DEBUG_DRAW_NORMAL_BUFFER = 5,\
DEBUG_DRAW_VOXEL_GI_ALBEDO = 6,\
DEBUG_DRAW_VOXEL_GI_LIGHTING = 7,\
DEBUG_DRAW_VOXEL_GI_EMISSION = 8,\
DEBUG_DRAW_SHADOW_ATLAS = 9,\
DEBUG_DRAW_DIRECTIONAL_SHADOW_ATLAS = 10,\
DEBUG_DRAW_SCENE_LUMINANCE = 11,\
DEBUG_DRAW_SSAO = 12,\
DEBUG_DRAW_SSIL = 13,\
DEBUG_DRAW_PSSM_SPLITS = 14,\
DEBUG_DRAW_DECAL_ATLAS = 15,\
DEBUG_DRAW_SDFGI = 16,\
DEBUG_DRAW_SDFGI_PROBES = 17,\
DEBUG_DRAW_GI_BUFFER = 18,\
DEBUG_DRAW_DISABLE_LOD = 19,\
DEBUG_DRAW_CLUSTER_OMNI_LIGHTS = 20,\
DEBUG_DRAW_CLUSTER_SPOT_LIGHTS = 21,\
DEBUG_DRAW_CLUSTER_DECALS = 22,\
DEBUG_DRAW_CLUSTER_REFLECTION_PROBES = 23,\
DEBUG_DRAW_OCCLUDERS = 24,\
DEBUG_DRAW_MOTION_VECTORS = 25,\
DEBUG_DRAW_INTERNAL_BUFFER}

# Fill debug menu with entries and connect to the tiled display events
func _ready():
	for k in DebugDraw.keys():
		$MenuLayout/DebugDraw.add_item(k)
	$MenuLayout/DebugDraw.selected = 0
	
	if GodotTD.tiled_display:
		$MenuLayout/Warping.connect("toggled", GodotTD.tiled_display.set_calibration)
		$MenuLayout/Alphamasks.connect("toggled", GodotTD.tiled_display.set_alphamask)
		$MenuLayout/Headtracking.connect("toggled", GodotTD.tiled_display.set_headtracking)
		$MenuLayout/Audio.connect("toggled", GodotTD.tiled_display.set_audio)
		$MenuLayout/Sky.connect("toggled", GodotTD.tiled_display.set_sky)
		$MenuLayout/SSAO.connect("toggled", GodotTD.tiled_display._on_ssao_toggled)
		$MenuLayout/GlobalIlumination.connect("toggled", GodotTD.tiled_display._on_global_ilumination_toggled)
		$MenuLayout/Glow.connect("toggled", GodotTD.tiled_display._on_glow_toggled)
		$"MenuLayout/Volumetric Fog".connect("toggled", GodotTD.tiled_display._on_volumetric_fog_toggled)
		$MenuLayout/AmbientLight.connect("toggled", GodotTD.tiled_display._on_ambient_light_toggled)
		$MenuLayout/DebugDraw.connect("item_selected", GodotTD.tiled_display._on_debug_draw_item_selected)
