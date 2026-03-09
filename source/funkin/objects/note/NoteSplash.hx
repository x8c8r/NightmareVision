package funkin.objects.note;

import flixel.FlxSprite;

import funkin.game.shaders.*;
import funkin.game.shaders.RGBPalette.RGBShaderReference;
import funkin.data.*;
import funkin.states.*;
import funkin.data.NoteSkin;

// @:nullSafety
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
	
	private var _note:Null<Note>;
	private var _strum:Null<StrumNote>;
	
	// internal thing to optimize loading frames
	@:noCompletion var _textureLoaded:Null<String> = null;
	
	public function new(x:Float = 0, y:Float = 0, noteData:Int = 0, player:Int = 0)
	{
		super(x, y);
		
		this._note = null;
		this._strum = null;
		
		this.data = noteData;
		this.player = player;
		
		rgbShader = NoteUtil.initRGBShader(this, noteData, 0, player);
		
		loadAnims(NoteUtil.getSkinFromID(player).splashTexture);
	}
	
	public function setupNoteSplash(strum:StrumNote, ?note:Note, ?texture:String, ?colourInput:Array<FlxColor>, ?field:PlayField)
	{
		_note = note ?? null;
		_strum = strum ?? null;
		
		data = note?.noteData ?? 0;
		
		player = field?.player ?? 0;
		final skin:NoteSkin = NoteUtil.getSkinFromID(player);
		
		final sanitzedColourArray = colourInput ?? NoteUtil.colorToArray(skin.colors[data]);
		
		texture ??= 'noteSplashes';
		
		if (_textureLoaded != texture) loadAnims(texture);
		
		if (skin != null)
		{
			scale.x *= skin.splashScale;
			scale.y *= skin.splashScale;
		}
		
		switch (texture)
		{
			default:
				alpha = 1;
				antialiasing = true;
				animation.play('note' + data, true);
				offset.set(-20, -20);
		}
		
		_position();
		
		rgbShader.enabled = skin.inEngineColoring;
		rgbShader.setColors(sanitzedColourArray);
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
					
					@:nullSafety(Off)
					animation.addByPrefix(data[noteData].anim, data[noteData].xmlName, 24, false);
				}
		}
		
		_textureLoaded = skin;
	}
	
	override function update(elapsed:Float)
	{
		if (animation.curAnim != null) if (animation.curAnim.finished) kill();
		
		// alpha tracking
		if (rgbShader != null)
		{
			final _a = (_note?.rgbShader?.alphaMult ?? 1);
			rgbShader.alphaMult = _a;
		}
		
		super.update(elapsed);
	}
	
	// doing this so the splash tracks the location of the strumnote if ur moving the notes actively with modmanager
	private function _position()
	{
		if (_strum != null)
		{
			final swagWidth = _strum.swagWidth ?? Note.swagWidth;
			final _skin:NoteSkin = NoteUtil.getSkinFromID(player);
			
			final offsets = _skin.splashOffsets != null ? _skin.splashOffsets[data] : null;
			final _X = (_strum.x + (offsets?.x ?? 0));
			final _Y = (_strum.y + (offsets?.y ?? 0));
			
			setPosition(_X - swagWidth * 0.95, _Y - swagWidth);
		}
	}
}
