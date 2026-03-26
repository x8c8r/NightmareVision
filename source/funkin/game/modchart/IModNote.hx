package funkin.game.modchart;

interface IModNote
{
	public var animation:flixel.animation.FlxAnimationController;
	public var offset(default, null):FlxPoint;
	public var scale(default, null):FlxPoint;
	
	public var animOffsets:Map<String, Array<Float>>;
	
	public var defScale:FlxPoint;
	
	public var noteData:Int;
}
