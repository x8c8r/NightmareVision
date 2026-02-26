package funkin.backend;

import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.input.actions.FlxActionInputDigital;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;

@:nullSafety
class InputSystem
{
	public var justPressed:FlxActionDigital;
	public var pressed:FlxActionDigital;
	public var released:FlxActionDigital;
	
	public final justPressedCallback = new FlxTypedSignal<(FlxKey) -> Void>();
	public final pressedCallback = new FlxTypedSignal<(FlxKey) -> Void>();
	public final releasedCallback = new FlxTypedSignal<(FlxKey) -> Void>();
	
	public function new()
	{
		trace("created input system");
		
		justPressed = new FlxActionDigital("key_just_pressed");
		pressed = new FlxActionDigital("key_pressed");
		released = new FlxActionDigital("key_released");
		
		for (group in ClientPrefs.keyBinds)
		{
			if (group == null) continue;
			
			for (key in group)
			{
				justPressed.addKey(key, FlxInputState.JUST_PRESSED);
				pressed.addKey(key, FlxInputState.PRESSED);
				released.addKey(key, FlxInputState.JUST_RELEASED);
			}
		}
	}
	
	public function update(elapsed:Float):Void
	{
		checkAction(justPressed, justPressedCallback);
		checkAction(pressed, pressedCallback);
		checkAction(released, releasedCallback);
	}
	
	function checkAction(action:FlxActionDigital, signal:FlxTypedSignal<(FlxKey) -> Void>):Void
	{
		for (input in action.inputs)
		{
			var digital:FlxActionInputDigital = cast input;
			
			if (digital.check(action))
			{
				var key:FlxKey = cast digital.inputID;
				signal.dispatch(key);
			}
		}
	}
}
