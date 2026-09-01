extends Node3D

@export var guindaste_virtual: Node3D

var xr_interface: XRInterface
var tag_tracker_name: StringName = ""


func _ready() -> void:
    xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.is_initialized():
        print("OpenXR initialized successfully")
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
        get_viewport().use_xr = true
        
        XRServer.tracker_added.connect(_on_tracker_added)
        XRServer.tracker_removed.connect(_on_tracker_removed)
    else:
        print("OpenXR not initialized, please check if your headset is connected")


func _process(_delta: float) -> void:
    if tag_tracker_name == "" or not guindaste_virtual:
        return
        
    var tracker: XRPositionalTracker = XRServer.get_tracker(tag_tracker_name)
    if tracker:
        var pose: XRPose = tracker.get_pose("default")
        if pose:
            var matriz_tag: Transform3D = pose.get_adjusted_transform()
            guindaste_virtual.global_transform = matriz_tag


func _on_tracker_added(tracker_name: StringName, type: int) -> void:
    print("Tracker adicionado: ", tracker_name, " Tipo: ", type)
    if "marker" in tracker_name.to_lower() or "apriltag" in tracker_name.to_lower():
        tag_tracker_name = tracker_name
        print("AprilTag identificada com sucesso: ", tag_tracker_name)


func _on_tracker_removed(tracker_name: StringName, _type: int) -> void:
    if tracker_name == tag_tracker_name:
        print("AprilTag perdida/removida")
        tag_tracker_name = ""