extends Node3D

@export var guindaste_virtual: Node3D
@export var target_aruco_id: int = 0

var xr_interface: OpenXRInterface
var active_anchor: XRAnchor3D = null

func _ready() -> void:
	print("[SISTEMA] Inicializando cena de XR Interface...")
	xr_interface = XRServer.find_interface("OpenXR") as OpenXRInterface
	
	if xr_interface and xr_interface.is_initialized():
		print("[SISTEMA] OpenXR inicializado. Ativando VR/XR na Viewport.")
		get_viewport().use_xr = true
		
		# Conecta ouvintes globais de trackers
		XRServer.tracker_added.connect(_on_tracker_added)
		XRServer.tracker_removed.connect(_on_tracker_removed)
		
		# Habilita o suporte a marcadores ArUco no OpenXR
		_enable_aruco_tracking()
	else:
		print("[ERRO CRITICO] OpenXR nao foi inicializado.")

func _enable_aruco_tracking() -> void:
	print("[CONFIG] Solicitando ativacao do rastreamento de ArUco (Tipo 3) no OpenXR...")
	
	if ClassDB.class_exists("OpenXRSpatialCapabilityExtension"):
		var ext = ClassDB.instantiate("OpenXRSpatialCapabilityExtension")
		if ext and ext.has_method("set_marker_type_enabled"):
			# Valor 3 = MARKER_TYPE_ARUCO na API oficial do Godot OpenXR
			ext.call("set_marker_type_enabled", 3, true)
			print("[CONFIG] Habilitado marcador tipo 3 (ArUco) via OpenXRSpatialCapabilityExtension.")

func _on_tracker_added(tracker_name: StringName, _type: int) -> void:
	print("[EVENTO] Novo tracker detectado: ", tracker_name)
	var tracker = XRServer.get_tracker(tracker_name)
	
	if tracker is OpenXRMarkerTracker:
		# Valida se o tipo do marcador retornado e ArUco (3)
		var m_type = tracker.marker_type if "marker_type" in tracker else 3
		if m_type != 3 and m_type != 0:
			print("[IGNORADO] Tracker nao e ArUco (Tipo lido: ", m_type, ")")
			return

		var raw_data = tracker.get_marker_data()
		var detected_id: int = -1
		
		# Decodifica o buffer binario do ID enviado pelo SO
		if raw_data is PackedByteArray:
			if raw_data.size() >= 8:
				detected_id = raw_data.decode_int64(0)
			elif raw_data.size() >= 4:
				detected_id = raw_data.decode_int32(0)
			else:
				var text_val = raw_data.get_string_from_utf8()
				if text_val.is_valid_int():
					detected_id = text_val.to_int()
		elif raw_data is int:
			detected_id = raw_data

		print("[DETECCAO] ArUco lido! ID parseado: ", detected_id)

		if detected_id == target_aruco_id and detected_id != -1:
			print("[SUCESSO] ID ArUco confere com o alvo (", target_aruco_id, ")! Ancorando guindaste...")
			_anchor_guindaste_to_aruco(tracker_name)
		else:
			print("[IGNORADO] ID ArUco (", detected_id, ") nao corresponde ao esperado: ", target_aruco_id)

func _anchor_guindaste_to_aruco(tracker_name: StringName) -> void:
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
		print("[SUCESSO] Guindaste ancorado no marcador ArUco com sucesso!")

func _on_tracker_removed(tracker_name: StringName, _type: int) -> void:
	if active_anchor and active_anchor.tracker == tracker_name:
		print("[AVISO] Tracker ArUco de ancoragem removido: ", tracker_name)