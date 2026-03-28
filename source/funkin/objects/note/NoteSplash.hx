package funkin.objects.note;

import flixel.FlxSprite;

import funkin.game.shaders.*;
import funkin.game.shaders.RGBPalette.RGBShaderReference;
import funkin.data.*;
import funkin.states.*;
import funkin.data.NoteSkin;

// @:nullSafety
class NoteSplash extends FlxSprite implements funkin.game.modchart.IModNote
{
	/**
	 * Shader applied to the notesplash to support custom colours
	 */
	public var rgbShader:RGBShaderReference;
	
	public var defScale:FlxPoint = FlxPoint.get(); // for modcharts to keep the scaling
	
	public var animOffsets:Map<String, Array<Float>> = new Map();
	
	/**
	 * The notedata of the splash
	 */
	public var data(get, set):Int;
	
	public var noteData:Int = 0;
	
	public var player:Int = 0;
	
	private var _note:Null<Note>;
	private var _strum:Null<StrumNote>;
	
	// internal thing to optimize loading frames
	@:noCompletion var _textureLoaded:Null<String> = null;
	
	public var skin:NoteSkin;
	
	public function new(x:Float = 0, y:Float = 0, noteData:Int = 0, player:Int = 0)
	{
		super(x, y);
		
		this._note = null;
		this._strum = null;
		
		this.data = noteData;
		this.player = player;
		
		rgbShader = NoteUtil.initRGBShader(this, noteData, 0, player);
		
		loadAnims(NoteUtil.getSkinFromID(player).splashTexture);
		
		final skin = NoteUtil.getSkinFromID(player);
		if (skin != null)
		{
			scale.set(skin.splashScale, skin.splashScale);
			defScale.copyFrom(scale);
		}
	}
	
	public function setupNoteSplash(strum:StrumNote, ?note:Note, ?texture:String, ?colourInput:Array<FlxColor>, ?field:PlayField)
	{
		_note = note ?? null;
		_strum = strum ?? null;
		
		data = note?.noteData ?? 0;
		
		player = field?.player ?? 0;
		
		skin = NoteUtil.getSkinFromID(player);
		
		final sanitzedColourArray = colourInput ?? NoteUtil.colorToArray(skin.colors[data]);
		
		texture ??= 'noteSplashes';
		
		if (_textureLoaded != texture) loadAnims(texture);
		
		updateHitbox();
		
		playAnim('note$data', true, colourInput);
		
		if (!field.trackNoteSplashes) _position();
	}
	
	public function playAnim(name:String, forced:Bool = false, ?colors:Array<FlxColor>):Void
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
		
		if (colors != null)
		{
			final sanitzedColourArray = colors ?? NoteUtil.colorToArray(skin.colors[data]);
			
			rgbShader.enabled = skin.inEngineColoring;
			rgbShader.setColors(sanitzedColourArray);
		}
	}
	
	function loadAnims(skin:String)
	{
		frames = Paths.getSparrowAtlas(skin);
		
		final _skin:NoteSkin = NoteUtil.getSkinFromID(player);
		
		switch (skin)
		{
			default:
				final data = _skin.splashAnims ?? NoteUtil.DEFAULT_NOTESPLASH_ANIMATIONS;
				
				for (noteData in 0..._skin.keys)
				{
					if (data[noteData] == null || data[noteData].anim == null || data[noteData].xmlName == null) continue;
					
					final animName = data[noteData].anim;
					final offsets = data[noteData].offsets;
					
					@:nullSafety(Off)
					animation.addByPrefix(animName, data[noteData].xmlName, 24, false);
					addOffset(animName, offsets[0], offsets[1]);
				}
		}
		
		_textureLoaded = skin;
	}
	
	public function addOffset(name:String, x:Float = 0, y:Float = 0):Void animOffsets.set(name, [x, y]);
	
	override function update(elapsed:Float)
	{
		if (animation.curAnim != null) if (animation.curAnim.finished) kill();
		
		super.update(elapsed);
	}
	
	// doing this so the splash tracks the location of the strumnote if ur moving the notes actively with modmanager
	function _position()
	{
		if (_strum != null)
		{
			final _skin:NoteSkin = NoteUtil.getSkinFromID(player);
			
			final offsets = _skin.splashOffsets != null ? _skin.splashOffsets[data] : null;
			final _X = (_strum.x + (offsets?.x ?? 0) * scale.x / defScale.x);
			final _Y = (_strum.y + (offsets?.y ?? 0) * scale.y / defScale.y);
			
			setPosition(_X + (_strum.width - width) * .5, _Y + (_strum.height - height) * .5);
		}
	}
	
	inline function get_data():Int return noteData;
	
	inline function set_data(v:Int):Int return noteData = v;
	
	public override function destroy():Void
	{
		defScale.put();
		
		super.destroy();
	}
}
