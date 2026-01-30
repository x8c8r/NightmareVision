package funkin.backend;

import flixel.math.FlxRandom;

import funkin.backend.MusicBeatState;
import funkin.scripting.ScriptedState;
import funkin.states.TitleState;
import funkin.states.MainMenuState;
import funkin.states.CreditsState;

class FunkinGame extends flixel.FlxGame
{
	override function switchState():Void
	{
		// Basic reset stuff
		FlxG.cameras.reset();
		FlxG.inputs.onStateSwitch();
		#if FLX_SOUND_SYSTEM
		FlxG.sound.destroy();
		#end
		
		FlxG.signals.preStateSwitch.dispatch();
		
		#if FLX_RECORD
		FlxRandom.updateStateSeed();
		#end
		
		// Destroy the old state (if there is an old state)
		if (_state != null) _state.destroy();
		
		// we need to clear bitmap cache only after previous state is destroyed, which will reset useCount for FlxGraphic objects
		FlxG.bitmap.clearCache();
		
		// Finally assign and create the new state
		_state = _nextState.createInstance();
		
		#if MODS_ALLOWED
		if (Mods.currentMod != null && Mods.currentMod.stateRedirects != null)
		{
			// before we progress the intended behavior we need to check if the mod has a custom one
			var stateName = Type.getClassName(Type.getClass(_state)).split('.').pop();
			
			for (key in Mods.currentMod.stateRedirects.keys())
			{
				if (key == stateName)
				{
					_state = FlxDestroyUtil.destroy(_state);
					
					_nextState = () -> new ScriptedState(Mods.currentMod.stateRedirects.get(stateName));
					
					_state = _nextState.createInstance();
					
					break;
				}
			}
		}
		#end
		
		_state._constructor = _nextState.getConstructor();
		_nextState = null;
		
		if (_gameJustStarted) FlxG.signals.preGameStart.dispatch();
		
		FlxG.signals.preStateCreate.dispatch(_state);
		
		_state.create();
		
		if (_gameJustStarted) gameStart();
		
		#if FLX_DEBUG
		debugger.console.registerObject("state", _state);
		#end
		
		FlxG.signals.postStateSwitch.dispatch();
	}
}
