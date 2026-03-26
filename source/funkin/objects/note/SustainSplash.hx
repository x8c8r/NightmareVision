package funkin.objects.note;

import funkin.data.*;
import funkin.objects.Bopper;
import funkin.game.shaders.RGBPalette.RGBShaderReference;

class SustainSplash extends FlxSprite implements funkin.game.modchart.IModNote
{
	public var rgbShader:RGBShaderReference;
	
	public var defScale:FlxPoint = FlxPoint.get(); // for modcharts to keep the scaling
	public var skinOrigin:FlxPoint = FlxPoint.get();
	
	public var animOffsets:Map<String, Array<Float>> = new Map();
	
	public var data(get, set):Int;
	public var noteData:Int = 0;
	
	public var player:Int = 0;
	
	private var _note:Note;
	private var _strum:StrumNote;
	
	// used for transferring color shit
	var tempColor:Array<FlxColor> = [];
	
	// internal thing to optimize loading frames
	@:noCompletion var _textureLoaded:Null<String> = null;
	
	public var skin:NoteSkin;
	
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
		animation.play(name, forced);
		
		centerOrigin();
		centerOffsets();
		
		if (animOffsets.exists(name))
		{
			final _offsets = animOffsets.get(name);
			offset.x += _offsets[0];
			offset.y += _offsets[1];
		}
		
		skin = NoteUtil.getSkinFromID(this.player);
		
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
		angle = 0;
		alpha = 1;
		
		this.player = field?.player ?? 0;
		
		final skin = NoteUtil.getSkinFromID(player);
		
		if (skin != null)
		{
			scale.set(skin.susSplashScale, skin.susSplashScale);
			defScale.copyFrom(scale);
			
			if (skin.susSplashOrigin != null) skinOrigin.set(skin.susSplashOrigin[0], skin.susSplashOrigin[1]);
		}
		
		updateHitbox();
		
		playAnim('start$data', true, colourInput);
		_position();
		
		FlxTimer.wait(time, () -> {
			if (isPlayer && ClientPrefs.noteSplashes) playAnim('end$data', true, colourInput);
			else kill();
		});
	}
	
	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
	
	inline function get_data():Int return noteData;
	inline function set_data(v:Int):Int return noteData = v;
	
	function _position()
	{
		if (_strum != null)
		{
			final _skin:NoteSkin = NoteUtil.getSkinFromID(player);
			
			final offsets = _skin.sustainSplashOffsets != null ? _skin.sustainSplashOffsets[data] : null;
			final _X = (_strum.x + (offsets?.x ?? 0) * scale.x / defScale.x);
			final _Y = (_strum.y + (offsets?.y ?? 0) * scale.y / defScale.y);
			
			setPosition(_X + (_strum.width - width) * .5, _Y + (_strum.height - height) * .5);
		}
	}
	
	public override function destroy():Void
	{
		defScale.put();
		skinOrigin.put();
		
		super.destroy();
	}
}
