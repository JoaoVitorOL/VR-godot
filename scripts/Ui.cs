using Godot;

public partial class Ui : Control
{
	private Node3D _virtualKeyboard;

	public override void _Ready()
	{
		// Tenta encontrar o teclado virtual na árvore do jogo automaticamente
		_virtualKeyboard = GetTree().Root.FindChild("VirtualKeyboard", true, false) as Node3D;

		if (_virtualKeyboard != null)
		{
			// Deixa o teclado invisível inicialmente
			_virtualKeyboard.Visible = false;
		}

		ConnectInputs(this);
	}

	private void ConnectInputs(Node node)
	{
		foreach (Node child in node.GetChildren())
		{
			if (child is LineEdit lineEdit)
			{
				lineEdit.FocusEntered += () => OnInputFocusEntered(lineEdit);
				lineEdit.FocusExited += () => OnInputFocusExited(lineEdit);
			}
			else if (child is TextEdit textEdit)
			{
				textEdit.FocusEntered += () => OnInputFocusEntered(textEdit);
				textEdit.FocusExited += () => OnInputFocusExited(textEdit);
			}

			if (child.GetChildCount() > 0)
			{
				ConnectInputs(child);
			}
		}
	}

	private void OnInputFocusEntered(Node inputNode)
	{
		if (_virtualKeyboard != null)
		{
			// Torna o teclado 3D visível no mundo VR
			_virtualKeyboard.Visible = true;

			// Diz ao XR Tools qual campo de texto deve receber os cliques do teclado
			if (_virtualKeyboard.HasMethod("set_input_node"))
			{
				_virtualKeyboard.Call("set_input_node", inputNode);
			}
		}
	}

	private void OnInputFocusExited(Node inputNode)
	{
		// Opcional: Se quiser esconder o teclado ao perder o foco, 
		// remova o comentário da linha abaixo:
		 if (_virtualKeyboard != null) _virtualKeyboard.Visible = false;
	}
}