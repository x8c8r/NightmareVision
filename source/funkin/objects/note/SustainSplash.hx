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
	
	// used for transferring color shit
	var tempColor:Array<FlxColor> = [];
	
	// internal thing to optimize loading frames
	@:noCompletion var _textureLoaded:Null<String> = null;
	
	public function new(x:Float = 0, y:Float = 0, noteData:Int = 0, player:Int = 0)
	{
		super(x, y);
		
		rgbShader = NoteUtil.initRGBShader(this, noteData, 0, player);
		
		frames = Paths.getSparrowAtlas('noteHoldCovers');
		
		final animData = NoteUtil.getSkinFromID(player).susSplashAnims;
		addAnims(animData);
	}
	
	function addAnims(animData:Array<Array<funkin.data.NoteSkin.Animation>>)
	{
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
		
		// animation.addByPrefix('start', 'start', 24, false);
		// animation.addByPrefix('loop', 'loop', 24, true);
		// animation.addByPrefix('end', 'end', 24, false);
		
		// animation.onFrameChange.add((anim, frame, idx) -> {
		// 	offset.set(0, 0);
		
		// 	switch (anim)
		// 	{
		// 		case 'end':
		// 			offset.set(38, 20);
		// 		case 'start':
		// 			offset.set(-29, -18);
		// 	}
		// });
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
	
	public function setupSplash(x:Float = 0, y:Float = 0, ?note:Note, ?time:Float = 0.5, ?isPlayer:Bool = false, ?colourInput:Array<FlxColor>, ?field:PlayField)
	{
		data = note.noteData;
		
		visible = true;
		alpha = 1;
		
		setPosition(x, y);
		
		this.player = field?.player ?? 0;
		
		if (field != null)
		{
			scale.x *= field.scale;
			scale.y *= field.scale;
		}
		
		playAnim('start$data', true, colourInput);
		
		FlxTimer.wait(time, () -> {
			if (isPlayer) playAnim('end$data', true, colourInput);
			else kill();
		});
	}
}
