using Godot;
using System;

public partial class RightHand : XRController3D
{
    private bool _isArMode = false;
    private XRInterface _xrInterface;

    // Variáveis para controle do Cooldown / Delay
    private float _cooldownTimer = 0.0f;
    [Export] private float _cooldownTime = 1.0f; // Tempo de espera em segundos entre um clique e outro
    
    // Variável para garantir que o botão precisa ser solto antes de apertar de novo
    private bool _buttonWasReleased = true;

    public override void _Ready()
    {
        _xrInterface = XRServer.PrimaryInterface;
    }

    public override void _Process(double delta)
    {
        // 1. Atualiza o timer do cooldown quadro a quadro
        if (_cooldownTimer > 0)
        {
            _cooldownTimer -= (float)delta;
        }

        bool isPressed = IsButtonPressed("by_button");

        // 2. Verifica se o botão está pressionado, se o cooldown acabou e se o botão foi solto anteriormente
        if (isPressed && _cooldownTimer <= 0 && _buttonWasReleased)
        {
            ToggleVrArState();
            
            // Reinicia o cooldown e bloqueia novas ativações até soltar o botão
            _cooldownTimer = _cooldownTime;
            _buttonWasReleased = false; 
        }

        // 3. Detecta quando o usuário soltou o dedo do botão
        if (!isPressed)
        {
            _buttonWasReleased = true;
        }
    }

    private void ToggleVrArState()
    {
        if (_xrInterface == null) return;

        _isArMode = !_isArMode;
        
        var newMode = _isArMode 
            ? XRInterface.EnvironmentBlendModeEnum.AlphaBlend 
            : XRInterface.EnvironmentBlendModeEnum.Opaque;

        _xrInterface.SetEnvironmentBlendMode(newMode);
        GD.Print(_isArMode ? "Modo AR (Passthrough) ativado" : "Modo VR ativado");
    }
}