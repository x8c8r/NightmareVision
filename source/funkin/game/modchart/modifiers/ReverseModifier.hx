package funkin.game.modchart.modifiers;

import funkin.backend.math.Vector3;

import flixel.math.FlxRect;
import flixel.FlxSprite;
import flixel.FlxG;

import funkin.game.modchart.*;
import funkin.states.*;
import funkin.objects.note.*;
import funkin.game.modchart.Modifier.ModifierOrder;

class ReverseModifier extends NoteModifier
{
	inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}
	
	override function getOrder() return REVERSE;
	
	override function getName() return 'reverse';
	
	public function getReverseValue(dir:Int, player:Int, ?scrolling = false)
	{
		var suffix = '';
		if (scrolling == true) suffix = 'Scroll';
		var receptors = modMgr.receptors[player];
		var kNum = receptors.length;
		var val:Float = 0;
		if (dir >= kNum / 2) val += getSubmodValue("split" + suffix, player);
		
		if ((dir % 2) == 1) val += getSubmodValue("alternate" + suffix, player);
		
		var first = kNum / 4;
		var last = kNum - 1 - first;
		
		if (dir >= first && dir <= last) val += getSubmodValue("cross" + suffix, player);
		
		if (suffix == '') val += getValue(player) + getSubmodValue("reverse" + Std.string(dir), player);
		else val += getSubmodValue("reverse" + suffix, player);
		
		if (getSubmodValue("unboundedReverse", player) == 0)
		{
			val %= 2;
			if (val > 1) val = 2 - val;
		}
		
		if (ClientPrefs.downScroll) val = 1 - val;
		
		return val;
	}
	
	public function getScrollReversePerc(dir:Int, player:Int) return getReverseValue(dir, player) * 100;
	
	override function shouldExecute(player:Int, val:Float) return true;
	
	override function ignoreUpdateNote() return false;
	
	override function updateNote(beat:Float, daNote:Note, pos:Vector3, player:Int)
	{
		if (!daNote.isSustainNote) return;
		
		final strum = modMgr.receptors[player][daNote.noteData];
		
		if (strum.sustainReduce && daNote.wasGoodHit && Conductor.songPosition >= daNote.strumTime)
		{
			final x:Float = (pos.x - (strum.x + strum.width * .5)), y:Float = (pos.y - (strum.y + strum.height * .5));
			
			final mag:Float = Math.sqrt(x * x + y * y);
			
			var swagRect = getNoteRect(daNote);
			swagRect.y = (mag / daNote.scale.y);
			swagRect.height -= swagRect.y;
			
			daNote.clipRect = swagRect;
		}
	}
	
	inline function getNoteRect(note:Note)
	{
		final rect = note.clipRect ?? new FlxRect();
		rect.x = 0;
		rect.y = 0;
		rect.width = note.frameWidth;
		rect.height = note.frameHeight;
		return rect;
	}
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		var perc = getReverseValue(data, player);
		var shift = MathUtil.scale(perc, 0, 1, 50, FlxG.height - 50 - Note.swagWidth);
		var mult = MathUtil.scale(perc, 0, 1, 1, -1);
		shift = MathUtil.scale(getSubmodValue("centered", player), 0, 1, shift, FlxG.height / 2);
		
		pos.y = (shift + (visualDiff * mult) + Note.swagWidth * .5);
		
		if (obj is Note && cast(obj, Note).isSustainNote)
			pos.y -= obj.height * perc;
		
		return pos;
	}
	
	override function getSubmods()
	{
		var subMods:Array<String> = [
			"cross",
			"split",
			"alternate",
			"reverseScroll",
			"crossScroll",
			"splitScroll",
			"alternateScroll",
			"centered",
			"unboundedReverse"
		];
		
		var receptors = modMgr.receptors[0];
		for (i in 0...PlayState.SONG.keys)
		{
			subMods.push('reverse${i}');
		}
		return subMods;
	}
}
