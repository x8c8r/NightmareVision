package funkin.objects.note;

import funkin.data.*;
import funkin.objects.Bopper;
import funkin.game.shaders.RGBPalette.RGBShaderReference;

class SustainSplash extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	
	public var animOffsets:Map<String, Array<Float>> = new Map();
	
	public var data:Int = 0;
	
	public var player:Int = 0;
	
	private var _note:Note;
	private var _strum:StrumNote;
	
	// used for transferring color shit
	var tempColor:Array<FlxColor> = [];
	
	// internal thing to optimize loading frames
	@:noCompletion var _textureLoaded:Null<String> = null;
	
	public function new(x:Float = 0, y:Float = 0, noteData:Int = 0, player:Int = 0)
	{
		super(x, y);
		
		rgbShader = NoteUtil.initRGBShader(this, noteData, 0, player);
		
		addAnims(NoteUtil.getSkinFromID(player));
	}
	
	function addAnims(_skin:NoteSkin)
	{
		frames = Paths.getSparrowAtlas(_skin.sustainSplashTexture);
		
		final animData = _skin.susSplashAnims;
		
		var noteData = -1;
		for (group in animData)
		{
			noteData += 1;
			for (anim in group)
			{
				final animName = '${anim.anim}$noteData';
				
				animation.addByPrefix(animName, anim.xmlName, anim.fps, anim.looping);
				addOffset(animName, anim.offsets[0], anim.offsets[1]);
			}
		}
		
		animation.onFinish.add((anim) -> {
			if (anim.contains('start')) playAnim('loop$data', false, tempColor);
			if (anim.contains('end')) kill();
		});
	}
	
	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
	
	public function playAnim(name:String, forced:Bool = false, ?colors:Array<FlxColor>)
	{
		centerOrigin();
		
		animation.play(name, forced);
		
		if (animOffsets.exists(name))
		{
			final _offsets = animOffsets.get(name);
			offset.set(_offsets[0], _offsets[1]);
		}
		
		final skin:NoteSkin = NoteUtil.getSkinFromID(this.player);
		
		final sanitzedColourArray = colors ?? NoteUtil.colorToArray(skin.colors[data]);
		tempColor = sanitzedColourArray;
		
		rgbShader.enabled = skin.inEngineColoring;
		rgbShader.setColors(sanitzedColourArray);
	}
	
	public function setupSplash(strum:StrumNote, ?note:Note, ?time:Float = 0.5, ?isPlayer:Bool = false, ?colourInput:Array<FlxColor>, ?field:PlayField)
	{
		this._note = note;
		this._strum = strum;
		
		data = note.noteData;
		
		visible = true;
		alpha = 1;
		
		this.player = field?.player ?? 0;
		
		final skin = NoteUtil.getSkinFromID(player);
		
		if (skin != null) scale.set(skin.susSplashScale, skin.susSplashScale);
		
		playAnim('start$data', true, colourInput);
		_position();
		
		FlxTimer.wait(time, () -> {
			if (isPlayer && ClientPrefs.noteSplashes) playAnim('end$data', true, colourInput);
			else kill();
		});
	}
	
	override public function update(elapsed:Float)
	{
		// alpha tracking
		if (rgbShader != null)
		{
			final _a = (_note?.rgbShader?.alphaMult ?? 1);
			rgbShader.alphaMult = _a;
		}
		_position();
		
		super.update(elapsed);
	}
	
	public function _position()
	{
		// doing this so the splash tracks the location of the strumnote if ur moving the notes actively with modmanager
		if (_strum != null)
		{
			// for some reason doing just .x and .y breaks. so. hooray for bandaid fixes!!!
			var pos = _strum.getMidpoint();
			setPosition(pos.x - (_strum.swagWidth / 2), pos.y - (_strum.swagWidth / 2));
		}
	}
}
