package funkin.objects.note;

import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.objects.Character;

typedef NoteSignal = FlxTypedSignal<(Note, PlayField) -> Void>;

// playfields should get a rework
// i feel more actual note handling should happen in here

class PlayField extends FlxTypedContainer<StrumNote>
{
	public var owner(default, set):Character;
	public var singers:Array<Null<Character>> = [];
	public var quants(default, set):Bool = ClientPrefs.quants;
	
	private function set_quants(value:Bool)
	{
		quants = value;
		
		for (i in members)
		{
			if (i != null)
			{
				i.isQuant = quants;
				i.reloadNote();
			}
		}
		
		return value;
	}
	
	private function set_owner(value:Character)
	{
		owner = value;
		
		singers.remove(owner);
		singers.unshift(owner);
		
		return value;
	}
	
	public var onNoteHit:NoteSignal = new NoteSignal();
	public var onNoteMiss:NoteSignal = new NoteSignal();
	public var onMissPress:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	
	public var playAnims:Bool = true;
	public var noteSplashes:Bool = false;
	public var autoPlayed:Bool = false;
	public var isPlayer:Bool = false;
	public var playerControls:Bool = false;
	public var inControl(default, set):Bool = true; // incase you want to lock up the playfield
	
	public var notes:Array<Note> = [];
	public var keyCount(default, set):Int = 0;
	
	public var swagWidth(get, never):Float;
	
	public var showRatings:Bool = false;
	
	public function get_swagWidth()
	{
		return Note.swagWidth * scale;
	}
	
	public var baseX:Float = 0;
	public var baseY:Float = 0;
	public var baseAlpha:Float = 1;
	public var offsetReceptors:Bool = false;
	public var player:Int = 0;
	public var scale(default, set):Float = 1;
	public var alpha(default, set):Float = 1;
	
	public function set_alpha(value:Float)
	{
		value = FlxMath.bound(value, 0, 1);
		for (strum in members)
		{
			strum.alphaMult = value;
		}
		return alpha = value;
	}
	
	public function set_scale(value:Float)
	{
		for (strum in members)
		{
			var anim:String = strum.animation.curAnim?.name ?? '';
			strum.playAnim("static", true);
			strum.setGraphicSize(strum.frameWidth * 0.7 * value);
			strum.updateHitbox();
			strum.playAnim(anim, true);
		}
		for (note in notes)
		{
			if (note.isSustainNote) note.scale.set(note.baseScaleX * value, note.baseScaleY);
			else note.scale.set(note.baseScaleX * value, note.baseScaleY * value);
			
			note.defScale.copyFrom(note.scale);
			note.updateHitbox();
		}
		return scale = value;
	}
	
	public function set_keyCount(value:Int)
	{
		keyCount = value;
		if (members.length > 0) generateReceptors();
		return keyCount;
	}
	
	public function set_inControl(value:Bool)
	{
		if (!value)
		{
			for (strum in members)
			{
				strum.playAnim("static");
				strum.resetAnim = 0;
			}
		}
		return inControl = value;
	}
	
	/**
	 * The container that all notesplashes are held in
	 */
	public var grpNoteSplashes:FlxTypedContainer<NoteSplash>;
	
	public function new(x:Float, y:Float, keyCount:Int = 4, ?who:Character, isPlayer:Bool = false, cpu:Bool = false, ?playerControls:Bool, player:Int = 0)
	{
		super();
		if (playerControls == null) playerControls = isPlayer;
		
		this.autoPlayed = cpu;
		
		this.owner = who;
		this.isPlayer = isPlayer;
		this.playerControls = playerControls;
		this.player = player;
		
		this.baseX = x;
		this.baseY = y;
		this.keyCount = keyCount;
		
		grpNoteSplashes = new FlxTypedContainer<NoteSplash>();
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		
		this.onNoteHit.add(noteHit);
		this.onNoteMiss.add(noteMiss);
		this.onMissPress.add(noteMissPress);
	}
	
	public function clearReceptors()
	{
		while (members.length > 0)
		{
			var note:StrumNote = members.pop();
			note.kill();
			note.destroy();
		}
	}
	
	public function generateReceptors()
	{
		clearReceptors();
		for (data in 0...keyCount)
		{
			var babyArrow:StrumNote = new StrumNote(player, baseX, baseY, data, this);
			babyArrow.setGraphicSize(Std.int(babyArrow.width * scale));
			babyArrow.updateHitbox();
			babyArrow.downScroll = ClientPrefs.downScroll;
			babyArrow.alphaMult = alpha;
			add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}
	
	public function fadeIn(skip:Bool = false)
	{
		for (data in 0...members.length)
		{
			var babyArrow:StrumNote = members[data];
			if (skip) babyArrow.alpha = baseAlpha;
			else
			{
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: baseAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * data)});
			}
		}
	}
	
	public function getNotes(dir:Int, ?get:Note->Bool):Array<Note>
	{
		var collected:Array<Note> = [];
		for (note in notes)
		{
			if (note.alive && note.noteData == dir && !note.wasGoodHit && !note.tooLate && note.canBeHit)
			{
				if (get == null || get(note)) collected.push(note);
			}
		}
		return collected;
	}
	
	public function getTapNotes(dir:Int):Array<Note> return getNotes(dir, (note:Note) -> !note.isSustainNote);
	
	public function getHoldNotes(dir:Int):Array<Note> return getNotes(dir, (note:Note) -> note.isSustainNote);
	
	/**
	 * Removes a note from this
	 * @param note 
	 */
	public inline function removeNote(note:Note)
	{
		notes.remove(note);
		note.scale.set(note.baseScaleX, note.baseScaleY);
		note.defScale.copyFrom(note.scale);
		note.updateHitbox();
		
		if (note.playField == this) note.playField = null;
		
		if (PlayState.instance != null) PlayState.instance.notes.remove(note, true);
	}
	
	public inline function addNote(note:Note)
	{
		notes.push(note);
		if (note.isSustainNote) note.scale.set(note.baseScaleX * scale, note.baseScaleY);
		else note.scale.set(note.baseScaleX * scale, note.baseScaleY * scale);
		
		note.defScale.copyFrom(note.scale);
		note.updateHitbox();
		if (note.playField != this) note.playField = this;
	}
	
	public function forEachAliveNote(func:Note->Void)
	{
		for (note in notes)
			if (note != null && note.exists && note.alive) func(note);
	}
	
	inline function disposeNote(note:Note):Void
	{
		removeNote(note);
		
		note.kill();
		note.destroy();
	}
	
	public function noteHit(note:Note, field:PlayField):Void
	{
		var scriptFunc:String = '';
		if (field.playerControls) scriptFunc = 'goodNoteHit';
		else scriptFunc = field.ID == 1 ? 'opponentNoteHit' : 'extraNotHit';
		
		final scriptArgs:Array<Dynamic> = [note, field.ID];
		
		PlayState.instance.scripts.call('${scriptFunc}Pre', scriptArgs);
		
		if (field.autoPlayed)
		{
			var time:Float = 0.15;
			if (note.isSustainNote && !note.isSustainEnd) time += 0.15;
			time /= PlayState.instance.playbackRate;
			
			if (field.playAnims) strumPlayAnim(field, Std.int(Math.abs(note.noteData)) % keyCount, time, note);
		}
		else if (field.playAnims)
		{
			members[note.noteData]?.playAnim('confirm', true, note);
		}
		
		if (ClientPrefs.guitarHeroSustains && !note.isSustainNote)
		{
			for (sustain in note.tail) sustain.blockHit = false; // makes the hold note active when you press the base note
		}
		
		if (field.playerControls)
		{
			if (note.wasGoodHit || field.autoPlayed && (note.ignoreNote || note.hitCausesMiss)) return;
			
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled) FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			
			if (note.hitCausesMiss)
			{
				field.onNoteMiss.dispatch(note, field);
				
				note.wasGoodHit = true;
				
				if (!note.isSustainNote) disposeNote(note);
				
				return;
			}
			
			PlayState.instance.health += note.hitHealth * PlayState.instance.healthGain;
		}
		
		var chars:Array<Null<Character>> = note.gfNote ? [PlayState.instance.gf] : field.singers;
		if (note.owner != null) chars = [note.owner];
		
		final noteRows = PlayState.instance.noteRows;
		final noteSkin = PlayState.noteSkin;
		
		for (char in chars)
		{
			if (note.noAnimation || char == null) continue;
			
			if (!note.hitCausesMiss)
			{
				var daAlt = '';
				if (note.noteType == 'Alt Animation') daAlt = '-alt';

				final animToPlay = noteSkin.data.singAnimations[Std.int(Math.abs(note.noteData))] + daAlt;
				
				char.holdTimer = 0;
				
				// ghost stuff
				final chord = noteRows[field.ID][note.row];
				
				if (!(char.vSliceSustains && note.isSustainNote))
				{
					if (ClientPrefs.jumpGhosts && char.ghostsEnabled && chord != null && chord.length > 1 && note.noteType != "Ghost Note")
					{
						daAlt = animNote.noteType == 'Alt Animation' ? '-alt' : '';
						final animNote = chord[0];
						final realAnim = noteSkin.data.singAnimations[Std.int(Math.abs(animNote.noteData))] + daAlt;
						
						if (char.mostRecentRow != note.row) char.playAnim(realAnim, true);
						
						if (note.nextNote != null && note.prevNote != null)
						{
							if (note != animNote && !note.nextNote.isSustainNote) char.playGhostAnim(chord.indexOf(note), animToPlay, true);
							else if (note.nextNote.isSustainNote)
							{
								char.playAnim(realAnim, true);
								char.playGhostAnim(chord.indexOf(note), animToPlay, true);
							}
						}
						char.mostRecentRow = note.row;
					}
					else
					{
						if (note.noteType != "Ghost Note") char.playAnim(animToPlay, true);
						else char.playGhostAnim(note.noteData, animToPlay, true);
					}
				}
				
				switch (note.noteType)
				{
					case 'Hey!' if (char.animation.exists('hey')):
						char.playAnimForDuration('hey', 0.6);
						char.specialAnim = true;
				}
			}
			else
			{
				switch (note.noteType)
				{
					case 'Hurt Note' if (char.animation.exists('hurt')):
						char.playAnim('hurt', true);
						char.specialAnim = true;
				}
			}
		}
		
		note.wasGoodHit = true;
		
		if (field.noteSplashes) spawnSplash(note);
		
		final globalScript = PlayState.instance.callNoteTypeScript(note.noteType, 'hit', scriptArgs);
		
		final noteScriptRet = PlayState.instance.callNoteTypeScript(note.noteType, scriptFunc, scriptArgs);
		if (noteScriptRet != ScriptConstants.STOP_FUNC) PlayState.instance.scripts.call(scriptFunc, scriptArgs, false, [note.noteType]);
		
		if (!note.isSustainNote) disposeNote(note);
	}
	
	function noteMiss(note:Note, field:PlayField):Void
	{
		PlayState.instance.health -= note.missHealth * PlayState.instance.healthLoss;
		
		for (owner in field.singers)
		{
			var char:Character = owner;
			if (note.gfNote) char = PlayState.instance.gf;
			
			if (char != null && !note.noMissAnimation)
			{
				if (char.animTimer <= 0)
				{
					var daAlt = '';
					if (note.noteType == 'Alt Animation') daAlt = '-alt';
					
					var animToPlay:String = PlayState.noteSkin.data.singAnimations[Std.int(Math.abs(note.noteData))] + 'miss' + daAlt;
					char.playAnim(animToPlay, true);
				}
			}
		}
		
		final scriptArgs:Array<Dynamic> = [note, field.ID];
		
		final noteScriptRet = PlayState.instance.callNoteTypeScript(note.noteType, 'noteMiss', scriptArgs);
		if (noteScriptRet != ScriptConstants.STOP_FUNC) PlayState.instance.scripts.call('noteMiss', scriptArgs, false, [note.noteType]);
		
		// hold note missing stuff, makes the hold unhittable (and kills it, might make it just transparent if i can fix some stuff)
		if (ClientPrefs.guitarHeroSustains && !note.hitCausesMiss)
		{
			final tail = (note.isSustainNote ? note.parent.tail : note.tail);
			for (sustain in tail)
			{
				note.blockHit = true;
				note.ignoreNote = true;
				note.alpha = 0.3;
				note.copyAlpha = false;
			}
		}
	}
	
	function noteMissPress(key:Int):Void
	{
		if (ClientPrefs.ghostTapping) return;
		
		final char = PlayState.instance.playerStrums?.owner ?? PlayState.instance.boyfriend;
		var gf = PlayState.instance.gf;
		
		if (!char.stunned)
		{
			PlayState.instance.health -= 0.05 * PlayState.instance.healthLoss;
			
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			
			if (char.animTimer <= 0) char.playAnim(PlayState.noteSkin.data.singAnimations[Std.int(Math.abs(key))] + 'miss', true);
		}
	}
	
	function strumPlayAnim(field:PlayField, id:Int, time:Float, ?note:Note)
	{
		var spr:StrumNote = field.members[id];
		
		if (spr != null)
		{
			spr.playAnim('confirm', true, note);
			spr.resetAnim = time;
		}
	}
	
	public function spawnSplash(note:Note)
	{
		if (ClientPrefs.noteSplashes
			&& note != null
			&& !note.hitCausesMiss
			&& !note.isSustainNote
			&& !note.noteSplashDisabled
			&& noteSplashes
			&& PlayState.noteSkin?.data?.splashesEnabled ?? true)
		{
			final strum:Null<StrumNote> = note.playField.members[note.noteData];
			if (strum != null)
			{
				final data = note.noteData;
				final skin:String = PlayState.noteSplashSkin;
				final colors = [note.rgbShader.r, note.rgbShader.g, note.rgbShader.b];
				
				final offsets = PlayState.instance.script_SPLASHOffsets != null ? PlayState.instance.script_SPLASHOffsets[data] : null;
				final _X = (strum.x + (offsets?.x ?? 0));
				final _Y = (strum.y + (offsets?.y ?? 0));
				
				var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
				splash.setupNoteSplash(_X, _Y, data, skin, colors, note.playField);
				grpNoteSplashes.add(splash);
				
				PlayState.instance.scripts.call('onSpawnNoteSplash', [splash, note]);
			}
		}
	}
	
	public inline function canInput():Bool
	{
		return (playerControls && inControl && !autoPlayed && (owner == null || !owner.stunned));
	}
	
	override function destroy()
	{
		onNoteHit.removeAll();
		onNoteHit.destroy();
		
		onNoteMiss.removeAll();
		onNoteMiss.destroy();
		
		onMissPress.removeAll();
		onMissPress.destroy();
		
		super.destroy();
	}
}
