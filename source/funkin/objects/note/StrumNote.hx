package funkin.objects.note;

import funkin.backend.math.Vector3;

import flixel.FlxSprite;
import flixel.math.FlxPoint;

import funkin.objects.*;
import funkin.game.shaders.RGBPalette;
import funkin.game.shaders.RGBPalette.RGBShaderReference;
import funkin.states.*;
import funkin.data.*;

class StrumNote extends FlxSprite
{
	public var intThing:Int = 0;
	
	public var defScale:FlxPoint = FlxPoint.get(); // for modcharts to keep the scaling
	
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	public var isQuant:Bool = false;
	public var player:Int;
	public var targetAlpha:Float = 1;
	public var alphaMult:Float = 1;
	public var parent:PlayField;
	@:isVar
	public var swagWidth(get, null):Float;
	
	public var animOffsets:Map<String, Array<Float>> = new Map();
	
	// stupid editor crashes
	public function getAnimName()
	{
		return animation?.curAnim?.name ?? 'static';
	}
	
	public function get_swagWidth()
	{
		return parent == null ? Note.swagWidth : parent.swagWidth;
	}
	
	// public var zIndex:Float = 0;
	// public var desiredZIndex:Float = 0;
	public var z:Float = 0;
	
	override function set_alpha(val:Float)
	{
		return targetAlpha = val;
	}
	
	public var texture(default, set):String = null;
	
	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}
	
	public var rgbShader:RGBShaderReference;
	public var useRGBShader:Bool = true;
	
	public var skin:NoteSkin;
	
	public function new(player:Int, x:Float, y:Float, leData:Int, ?parent:PlayField)
	{
		noteData = leData;
		this.noteData = leData;
		this.parent = parent;
		this.player = player;
		super(x, y);
		
		skin = NoteSkinHelper.getSkinFromID(parent?.player ?? 0);
		
		texture = skin.noteTexture; // Load texture and anims
		
		scrollFactor.set();
		
		useRGBShader = skin.inEngineColoring;
		
		rgbShader = NoteSkinHelper.initRGBShader(this, noteData, player);
		rgbShader.enabled = useRGBShader;
		isQuant = parent?.quants ?? ClientPrefs.quants;
		
		handleColors();
	}
	
	public function handleColors(anim:String = '', ?note:Note)
	{
		if (!useRGBShader) return;
		
		var arr:Array<FlxColor> = note?.rgbShader?.colorArray ?? [];
		if (arr == null || arr.length <= 0) arr = NoteSkinHelper.getCurColors(noteData, (isQuant && note != null) ? note.quant : 4, player);
		
		if (isQuant && anim == 'pressed') arr = ClientPrefs.arrowRGBquant[0];
		
		if (rgbShader != null)
		{
			rgbShader.setColors(arr);
			
			rgbShader.enabled = (anim != 'static');
		}
	}
	
	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null) lastAnim = animation.curAnim.name;
		var br:String = texture;
		
		frames = Paths.getAtlasFrames(br);
		
		setGraphicSize(Std.int(width * skin.scale));
		
		loadAnimations();
		
		defScale.copyFrom(scale);
		updateHitbox();
		
		antialiasing = skin.antialiasing;
		
		if (lastAnim != null) playAnim(lastAnim, true);
		
		handleColors();
	}
	
	function loadAnimations()
	{
		var noteAnims = skin.receptorAnims;
		var directionAnims = noteAnims[noteData % noteAnims.length];
		
		for (anim in directionAnims)
			addAnim(anim);
	}
	
	public function hasAnim(anim:String)
	{
		return animation.exists(anim) && animOffsets.exists(anim);
	}
	
	function addAnim(_anim:funkin.data.NoteSkinHelper.Animation)
	{
		final anim = _anim ?? NoteSkinHelper.fallbackReceptorAnims[0];
		
		if (!hasAnim(anim.anim))
		{
			animation.addByPrefix(anim.anim, anim.xmlName, anim.fps, anim.looping);
			addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
		}
	}
	
	function removeAnim(anim:String)
	{
		if (hasAnim(anim))
		{
			animation.remove(anim);
			animOffsets.remove(anim);
		}
	}
	
	public function postAddedToGroup()
	{
		playAnim('static');
		x -= swagWidth / 2;
		x = x - (swagWidth * 2) + (swagWidth * noteData) + 54;
		
		ID = noteData;
	}
	
	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		@:bypassAccessor
		super.set_alpha(targetAlpha * alphaMult);
		
		if (animation.curAnim?.name == 'confirm') centerOrigin();
		
		super.update(elapsed);
	}
	
	public function playAnim(anim:String, ?force:Bool = false, ?note:Note)
	{
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		
		if (animOffsets.exists(anim)) offset.set(offset.x + animOffsets.get(anim)[0], offset.y + animOffsets.get(anim)[1]);
		
		handleColors(anim, note);
	}
	
	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
	
	override function destroy()
	{
		defScale.put();
		super.destroy();
	}
}
