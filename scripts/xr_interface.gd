extends Node3D

@export var guindaste_virtual: Node3D
@export var target_qr_content: String = "controleguindaste"

var xr_interface: OpenXRInterface
var active_anchor: XRAnchor3D = null

func _ready() -> void:
	print("[SISTEMA] Inicializando cena de XR Interface...")
	xr_interface = XRServer.find_interface("OpenXR") as OpenXRInterface
	
	if xr_interface and xr_interface.is_initialized():
		print("[SISTEMA] OpenXR inicializado com sucesso. Ativando VR/XR na Viewport.")
		get_viewport().use_xr = true
		
		print("[PASSO 1] Solicitando ativacao dos recursos de leitura de QR Code no OpenXR...")
		_enable_qr_code_capability()
		
		print("[PASSO 2] Conectando sinais do XRServer para ouvir novos Marcadores.")
		XRServer.tracker_added.connect(_on_tracker_added)
		XRServer.tracker_removed.connect(_on_tracker_removed)
	else:
		print("[ERRO CRITICO] OpenXR nao foi inicializado.")

func _enable_qr_code_capability() -> void:
	print("[CONFIG] Verificando subsistema de marcadores espaciais...")
	
	# Verifica e habilita o OpenXRMarkerExtension do plugin Godot OpenXR Vendors
	if ClassDB.class_exists("OpenXRMarkerExtension"):
		var marker_ext = ClassDB.instantiate("OpenXRMarkerExtension")
		if marker_ext and marker_ext.has_method("set_marker_type_enabled"):
			# 0 = QR_CODE na API OpenXR Marker Tracking
			marker_ext.call("set_marker_type_enabled", 0, true)
			print("[CONFIG] Extension OpenXRMarkerExtension ativada com sucesso para QR Code!")
		else:
			print("[AVISO] Classe OpenXRMarkerExtension encontrada, mas sem o metodo set_marker_type_enabled.")
	else:
		print("[AVISO] Classe OpenXRMarkerExtension nao registrada no Engine.")
func _on_tracker_added(tracker_name: StringName, _type: int) -> void:
	print("[EVENTO] Novo tracker detectado: ", tracker_name)
	var tracker = XRServer.get_tracker(tracker_name)
	
	if tracker is OpenXRMarkerTracker:
		var marker_str_id = str(tracker.marker_id)
		var raw_content = ""
		
		# Tenta extrair a propriedade content (pode vir como PackedByteArray ou String)
		var content_data = tracker.get("content")
		if content_data is PackedByteArray:
			raw_content = content_data.get_string_from_utf8()
		elif content_data != null:
			raw_content = str(content_data)
			
		print("[DETECCAO] ID: ", marker_str_id, " | Conteudo lido: ", raw_content)

		# Ancora se o texto for igual, se for ID 0, ou se a variavel de busca estiver vazia
		if raw_content == target_qr_content or raw_content.contains(target_qr_content) or target_qr_content.is_empty() or marker_str_id == "0":
			print("[SUCESSO] Marcador reconhecido! Ancorando guindaste...")
			_anchor_guindaste_to_qr(tracker_name)
		else:
			print("[IGNORADO] QR Code lido nao confere com: ", target_qr_content)
	else:
		print("[SISTEMA] Tracker ignorado por nao ser marcador visual.")
		

func _anchor_guindaste_to_qr(tracker_name: StringName) -> void:
	if active_anchor:
		print("[ANCORAGEM] Removendo ancora antiga...")
		active_anchor.queue_free()
		active_anchor = null

	print("[ANCORAGEM] Criando novo no XRAnchor3D para: ", tracker_name)
	active_anchor = XRAnchor3D.new()
	active_anchor.tracker = tracker_name

	var xr_origin = get_node_or_null("XROrigin3D")
	if not xr_origin:
		xr_origin = get_parent().get_node_or_null("XROrigin3D")

	if xr_origin:
		print("[ANCORAGEM] XROrigin3D encontrado! Adicionando ancora como filha.")
		xr_origin.add_child(active_anchor)
	else:
		print("[AVISO] XROrigin3D nao encontrado. Adicionando ancora na raiz.")
		add_child(active_anchor)

	if guindaste_virtual:
		if guindaste_virtual.get_parent():
			print("[ANCORAGEM] Desconectando guindaste do pai anterior...")
			guindaste_virtual.get_parent().remove_child(guindaste_virtual)
		
		print("[ANCORAGEM] Movendo guindaste para a XRAnchor3D e zerando transform...")
		active_anchor.add_child(guindaste_virtual)
		guindaste_virtual.transform = Transform3D.IDENTITY
		
		print("[SUCESSO] Guindaste atrelado ao QR Code com sucesso!")
	else:
		print("[ERRO] Variavel guindaste_virtual esta NULA no Inspetor.")

func _on_tracker_removed(tracker_name: StringName, _type: int) -> void:
	print("[EVENTO] Tracker saiu de vista: ", tracker_name)
	if active_anchor and active_anchor.tracker == tracker_name:
		print("[AVISO] O QR Code da ancora atual foi perdido.")