using Godot;
using System;

public partial class XrControllerScript : Node3D
{
    [Export]
    public Node3D GuindasteVirtual { get; set; }

    [Export]
    public string TargetQrContent { get; set; } = "controleguindaste";

    private OpenXRInterface _xrInterface;
    private XRAnchor3D _activeAnchor = null;

    public override void _Ready()
    {
        GD.Print("[SISTEMA] Inicializando cena de XR Interface...");
        _xrInterface = XRServer.FindInterface("OpenXR") as OpenXRInterface;

        if (_xrInterface != null && _xrInterface.IsInitialized())
        {
            GD.Print("[SISTEMA] OpenXR inicializado com sucesso. Ativando VR/XR na Viewport.");
            GetViewport().UseXR = true;

            GD.Print("[PASSO 1] Solicitando ativacao dos recursos de leitura de QR Code no OpenXR...");
            EnableQrCodeCapability();

            GD.Print("[PASSO 2] Conectando sinais do XRServer para ouvir novos Marcadores.");
            XRServer.TrackerAdded += OnTrackerAdded;
            XRServer.TrackerRemoved += OnTrackerRemoved;
        }
        else
        {
            GD.Print("[ERRO CRITICO] OpenXR nao foi inicializado.");
        }
    }

    private void EnableQrCodeCapability()
    {
        GD.Print("[CONFIG] Verificando subsistema de marcadores espaciais...");

        if (ClassDB.ClassExists("OpenXRMarkerExtension"))
        {
            GodotObject markerExt = ClassDB.Instantiate("OpenXRMarkerExtension").AsGodotObject();
            if (markerExt != null && markerExt.HasMethod("set_marker_type_enabled"))
            {
                // 0 = QR_CODE na API OpenXR Marker Tracking
                markerExt.Call("set_marker_type_enabled", 0, true);
                GD.Print("[CONFIG] Extension OpenXRMarkerExtension ativada com sucesso para QR Code!");
            }
            else
            {
                GD.Print("[AVISO] Classe OpenXRMarkerExtension encontrada, mas sem o metodo set_marker_type_enabled.");
            }
        }
        else
        {
            GD.Print("[AVISO] Classe OpenXRMarkerExtension nao registrada no Engine.");
        }
    }

    private void OnTrackerAdded(StringName trackerName, long type)
    {
        GD.Print("[EVENTO] Novo tracker detectado: ", trackerName);
        XRTracker tracker = XRServer.GetTracker(trackerName);

        // Caso a extensão traga uma classe customizada estendida de XRPositionalTracker
        if (tracker != null && tracker.GetClass() == "OpenXRMarkerTracker")
        {
            string markerStrId = tracker.Get("marker_id").AsString();
            string rawContent = "";

            // Tenta extrair a propriedade content (pode vir como byte[] ou string)
            Variant contentData = tracker.Get("content");
            
            if (contentData.VariantType == Variant.Type.PackedByteArray)
            {
                byte[] bytes = contentData.AsByteArray();
                rawContent = System.Text.Encoding.UTF8.GetString(bytes);
            }
            else if (contentData.VariantType != Variant.Type.Nil)
            {
                rawContent = contentData.AsString();
            }

            GD.Print($"[DETECCAO] ID: {markerStrId} | Conteudo lido: {rawContent}");

            // Ancora se o texto for igual, se contiver a busca, se a busca estiver vazia ou ID 0
            if (rawContent == TargetQrContent || 
                rawContent.Contains(TargetQrContent) || 
                string.IsNullOrEmpty(TargetQrContent) || 
                markerStrId == "0")
            {
                GD.Print("[SUCESSO] Marcador reconhecido! Ancorando guindaste...");
                GD.Print("[DETECCAO] Conteudo lido: ", rawContent);
                AnchorGuindasteToQr(trackerName);
            }
            else
            {
                GD.Print("[IGNORADO] QR Code lido nao confere com: ", TargetQrContent);
            }
        }
        else
        {
            GD.Print("[SISTEMA] Tracker ignorado por nao ser marcador visual.");
        }
    }

    private void AnchorGuindasteToQr(StringName trackerName)
    {
        if (IsInstanceValid(_activeAnchor))
        {
            GD.Print("[ANCORAGEM] Removendo ancora antiga...");
            _activeAnchor.QueueFree();
            _activeAnchor = null;
        }

        GD.Print("[ANCORAGEM] Criando novo no XRAnchor3D para: ", trackerName);
        _activeAnchor = new XRAnchor3D();
        _activeAnchor.Tracker = trackerName;

        Node3D xrOrigin = GetNodeOrNull<Node3D>("XROrigin3D");
        if (xrOrigin == null)
        {
            xrOrigin = GetParent()?.GetNodeOrNull<Node3D>("XROrigin3D");
        }

        if (xrOrigin != null)
        {
            GD.Print("[ANCORAGEM] XROrigin3D encontrado! Adicionando ancora como filha.");
            xrOrigin.AddChild(_activeAnchor);
        }
        else
        {
            GD.Print("[AVISO] XROrigin3D nao encontrado. Adicionando ancora na raiz.");
            AddChild(_activeAnchor);
        }

        if (GuindasteVirtual != null)
        {
            Node guindasteParent = GuindasteVirtual.GetParent();
            if (guindasteParent != null)
            {
                GD.Print("[ANCORAGEM] Desconectando guindaste do pai anterior...");
                guindasteParent.RemoveChild(GuindasteVirtual);
            }

            GD.Print("[ANCORAGEM] Movendo guindaste para a XRAnchor3D e zerando transform...");
            _activeAnchor.AddChild(GuindasteVirtual);
            GuindasteVirtual.Transform = Transform3D.Identity;

            GD.Print("[SUCESSO] Guindaste atrelado ao QR Code com sucesso!");
        }
        else
        {
            GD.Print("[ERRO] Variavel GuindasteVirtual esta NULA no Inspetor.");
        }
    }

    private void OnTrackerRemoved(StringName trackerName, long type)
    {
        GD.Print("[EVENTO] Tracker saiu de vista: ", trackerName);
        if (IsInstanceValid(_activeAnchor) && _activeAnchor.Tracker == trackerName)
        {
            GD.Print("[AVISO] O QR Code da ancora atual foi perdido.");
        }
    }
}