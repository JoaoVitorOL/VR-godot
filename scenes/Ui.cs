using Godot;
using System;

public partial class Ui : Control
{
public override void _Ready()
	{
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
		Node vk = GetNodeOrNull("/root/VirtualKeyboard");
		if (vk != null)
		{
			vk.Set("visible", true);
			if (vk.HasMethod("set_input_node"))
			{
				vk.Call("set_input_node", inputNode);
			}
		}
	}

	private void OnInputFocusExited(Node inputNode)
	{
		// Opcional: caso queira tratar a perda de foco
	}
}
