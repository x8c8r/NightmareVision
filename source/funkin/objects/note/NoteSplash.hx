package funkin.objects.note;

import flixel.FlxSprite;

import funkin.game.shaders.*;
import funkin.game.shaders.RGBPalette.RGBShaderReference;
import funkin.data.*;
import funkin.states.*;
import funkin.data.NoteSkin;

@:nullSafety
class NoteSplash extends FlxSprite
{
	/**
	 * Shader applied to the notesplash to support custom colours
	 */
	public var rgbShader:RGBShaderReference;
	
	/**
	 * The notedata of the splash
	 */
	public var data:Int = 0;
	
	public var player:Int = 0;
	
	// internal thing to optimize loading frames
	@:noCompletion var _textureLoaded:Null<String> = null;
	
	public function new(x:Float = 0, y:Float = 0, noteData:Int = 0, player:Int = 0)
	{
		super(x, y);
		
		this.player = player;
		rgbShader = NoteSkinHelper.initRGBShader(this, noteData, player);
		
		loadAnims(NoteSkinHelper.getSkinFromID(player).splashTexture);
		setupNoteSplash(x, y, noteData);
	}
	
	public function setupNoteSplash(x:Float = 0, y:Float = 0, note:Int = 0, ?texture:String, ?colourInput:Array<FlxColor>, ?field:PlayField)
	{
		final swagWidth = field?.members[note].swagWidth ?? Note.swagWidth;
		setPosition(x - swagWidth * 0.95, y - swagWidth);
		
		this.player = field?.player ?? 0;
		final skin:NoteSkin = NoteSkinHelper.getSkinFromID(this.player);
		
		final defColour = skin.colors[note];
		
		final sanitzedColourArray = NoteSkinHelper.colorToArray(defColour);
		// var sanitzedColourArray:Array<FlxColor> = colourInput ?? [defColour.r ?? FlxColor.WHITE, defColour.g ?? FlxColor.WHITE, defColour.b ?? FlxColor.WHITE];
		
		texture ??= 'noteSplashes';
		
		if (_textureLoaded != texture) loadAnims(texture);
		
		if (field != null)
		{
			scale.x *= field.scale;
			scale.y *= field.scale;
		}
		
		data = note;
		
		switch (texture)
		{
			default:
				alpha = 1;
				antialiasing = true;
				animation.play('note' + note, true);
				offset.set(-20, -20);
		}
		
		rgbShader.enabled = skin.inEngineColoring;
		rgbShader.setColors(sanitzedColourArray);
	}
	
	public function playAnim()
	{
		animation.play('note' + data, true);
	}
	
	function loadAnims(skin:String)
	{
		frames = Paths.getSparrowAtlas(skin);
		
		final _skin:NoteSkin = NoteSkinHelper.getSkinFromID(player);
		
		switch (skin)
		{
			default:
				final data = _skin.splashAnims ?? NoteSkinHelper.DEFAULT_NOTESPLASH_ANIMATIONS;
				
				for (noteData in 0..._skin.keys)
				{
					if (data[noteData] == null || data[noteData].anim == null || data[noteData].xmlName == null) continue;
					
					@:nullSafety(Off)
					animation.addByPrefix(data[noteData].anim, data[noteData].xmlName, 24, false);
				}
		}
		
		_textureLoaded = skin;
	}
	
	override function update(elapsed:Float)
	{
		if (animation.curAnim != null) if (animation.curAnim.finished) kill();
		
		super.update(elapsed);
	}
}
