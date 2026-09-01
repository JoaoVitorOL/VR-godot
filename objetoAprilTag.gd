extends Node3D

# Referência ao nó do guindaste virtual que vai se mover/posicionar com base na tag
@export var guindaste_virtual: Node3D

# Exemplo de função que escuta o sinal de atualização do OpenXR / Tracker
func _on_marker_updated(marker_transform: Transform3D) -> void:
	if not guindaste_virtual:
		return
		
	# 1. Pega a matriz de transformação entregue pelo OpenXR (posição e rotação da AprilTag)
	var matriz_tag: Transform3D = marker_transform
	
	# 2. Aplica ao nó 3D do controle virtual do guindaste
	# (Opcional: aqui você pode somar um Offset caso queira que o guindaste 
	# apareça em cima da tag e não exatamente na origem dela)
	guindaste_virtual.global_transform = matriz_tag