package funkin.data;

import haxe.ds.Vector;

import flixel.math.FlxPoint;

import funkin.data.NoteSkinHelper.Animation;
import funkin.data.NoteSkinHelper.ColorList;

class NoteSkin implements IFlxDestroyable
{
	public var name:String = '';
	public var helper:NoteSkinHelper;
	public var keys:Int = 4;
	public var ID:Int = 0;
	
	// textures
	public var noteTexture:String = '';
	public var splashTexture:String = '';
	public var sustainSplashTexture:String = '';
	
	// anims
	public var noteAnims:Array<Array<Animation>> = [];
	public var receptorAnims:Array<Array<Animation>> = [];
	public var splashAnims:Array<Animation> = [];
	
	// offsets
	public var noteOffsets:Vector<FlxPoint>;
	public var sustainOffsets:Vector<FlxPoint>;
	public var susEndOffsets:Vector<FlxPoint>;
	public var splashOffsets:Vector<FlxPoint>;
	public var sustainSplashOffsets:Vector<FlxPoint>;
	public var receptorOffsets:Vector<FlxPoint>;
	
	// settings
	public var isPixel:Bool = false;
	public var quantsEnabled:Bool = true;
	public var splashesEnabled:Bool = true;
	public var antialiasing:Bool = true;
	public var scale:Float = 0.7;
	
	// coloring
	public var inEngineColoring:Bool = true;
	public var colors:Array<ColorList> = [];
	
	// sing anims
	public var singAnimations = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	
	public function new(path:String, _keys:Int = -1, id:Int = 0)
	{
		keys = _keys;
		name = path;
		this.ID = id;
		
		noteOffsets = new Vector<FlxPoint>(keys);
		sustainOffsets = new Vector<FlxPoint>(keys);
		susEndOffsets = new Vector<FlxPoint>(keys);
		receptorOffsets = new Vector<FlxPoint>(keys);
		splashOffsets = new Vector<FlxPoint>(keys);
		// sustainSplashOffsets = new Vector<FlxPoint>(keys);
		
		for (i in 0...keys)
		{
			noteOffsets[i] = new FlxPoint();
			receptorOffsets[i] = new FlxPoint();
			sustainOffsets[i] = new FlxPoint();
			susEndOffsets[i] = new FlxPoint();
			splashOffsets[i] = new FlxPoint();
			// sustainSplashOffsets[i] = new FlxPoint();
		}
		
		helper = new NoteSkinHelper(Paths.noteskin(path));
		
		noteAnims = helper.data.noteAnimations;
		receptorAnims = helper.data.receptorAnimations;
		splashAnims = helper.data.noteSplashAnimations;
		
		for (i in 0...keys)
		{
			var safeDir:Int = (i % helper.data.noteAnimations.length),
				safeSplashDir:Int = (i % helper.data.noteSplashAnimations.length);
				
			var noteAnims = helper.data.noteAnimations[safeDir],
				splashAnims = helper.data.noteSplashAnimations[safeSplashDir];
				
			noteOffsets[i].x = noteAnims[0].offsets[0];
			noteOffsets[i].y = noteAnims[0].offsets[1];
			
			sustainOffsets[i].x = noteAnims[1].offsets[0];
			sustainOffsets[i].y = noteAnims[1].offsets[1];
			
			susEndOffsets[i].x = noteAnims[2].offsets[0];
			susEndOffsets[i].y = noteAnims[2].offsets[1];
			susEndOffsets[i].y *= (ClientPrefs.downScroll ? -1 : 1);
			
			splashOffsets[i].x = splashAnims.offsets[0];
			splashOffsets[i].y = splashAnims.offsets[1];
		}
		
		noteTexture = helper.data.playerSkin;
		splashTexture = helper.data.noteSplashSkin;
		
		scale = helper.data.scale;
		antialiasing = helper.data.antialiasing;
		
		inEngineColoring = helper.data.inGameColoring;
		colors = helper.data.arrowRGB;
	}
	
	public function destroy()
	{
		// ill do this later
	}
}
