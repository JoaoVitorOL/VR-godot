extends Node3D

@export var guindaste_virtual: Node3D

var active_anchor: XRAnchor3D


func _ready() -> void:
	get_viewport().use_xr = true
	XRServer.tracker_added.connect(_on_tracker_added)


func _on_tracker_added(tracker_name: StringName, _type: int) -> void:
	var tracker = XRServer.get_tracker(tracker_name)

	if tracker is OpenXRMarkerTracker:
		if tracker.marker_type == OpenXRSpatialComponentMarkerList.MARKER_TYPE_APRIL_TAG:
			print("AprilTag detectada! ID: ", tracker.marker_id)
			_anchor_guindaste(tracker_name)


func _anchor_guindaste(tracker_name: StringName) -> void:
	if active_anchor:
		active_anchor.queue_free()
		active_anchor = null

	active_anchor = XRAnchor3D.new()
	active_anchor.tracker = tracker_name

	var xr_origin = get_node_or_null("XROrigin3D")

	if not xr_origin:
		xr_origin = get_parent().get_node_or_null("XROrigin3D")

	if xr_origin:
		xr_origin.add_child(active_anchor)
	else:
		add_child(active_anchor)

	if guindaste_virtual:
		if guindaste_virtual.get_parent():
			guindaste_virtual.get_parent().remove_child(guindaste_virtual)

		active_anchor.add_child(guindaste_virtual)
		guindaste_virtual.transform = Transform3D.IDENTITY

		print("Guindaste ancorado na AprilTag!")