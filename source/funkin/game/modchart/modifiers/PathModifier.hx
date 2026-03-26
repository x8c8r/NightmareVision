package funkin.game.modchart.modifiers;

@:structInit
class PathInfo
{
	public var position:Vector3;
	public var dist:Float;
	public var start:Float;
	public var end:Float;
}

class PathModifier extends NoteModifier
{
	var moveSpeed:Float;
	var pathData:Array<Array<PathInfo>> = [];
	var totalDists:Array<Float> = [];
	
	override function getName() return 'basePath';
	
	public function getMoveSpeed()
	{
		return 5000;
	}
	
	public function getPath():Array<Array<Vector3>>
	{
		return [];
	}
	
	public function new(modMgr:ModManager, ?parent:Modifier)
	{
		super(modMgr, parent);
		moveSpeed = getMoveSpeed();
		
		final path:Array<Array<Vector3>> = getPath();
		
		for (dir in 0 ... path.length)
		{
			totalDists[dir] = 0;
			pathData[dir] = [];
			
			for (idx in 0 ... path[dir].length)
			{
				final pos = path[dir][idx];
				
				if (idx > 0)
				{
					final last = pathData[dir][idx - 1];
					final totalDist = (totalDists[dir] += Vector3.distance(last.position, pos));
					
					last.end = totalDist;
					last.dist = last.start - totalDist; // used for interpolation
				}
				
				pathData[dir].push(
					{
						position: pos,
						start: totalDists[dir],
						end: totalDists[dir],
						dist: 0
					});
			}
		}
		
		for (dir in 0...totalDists.length)
		{
			// trace(dir, totalDists[dir]);
		}
	}
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		if (getValue(player) == 0) return pos;
		
		// tried to use visualDiff but didnt work :(
		// will get it working later
		final progress = (visualDiff / moveSpeed * totalDists[data]);
		final clampProgress = FlxMath.bound(progress, 0, totalDists[data]);
		
		final daPath = pathData[data];
		
		for (idx in 0 ... daPath.length - 1)
		{
			final cData = daPath[idx], nData = daPath[idx + 1];
			
			if (clampProgress >= cData.start && clampProgress <= cData.end)
			{
				final alpha = ((cData.start - progress) / cData.dist);
				final interpPos:Vector3 = cData.position.lerp(nData.position, alpha);
				
				return pos.lerp(interpPos, getValue(player));
			}
		}
		
		return pos.lerp(daPath[0].position, getValue(player));
	}
	
	override function getSubmods()
	{
		return [];
	}
}
