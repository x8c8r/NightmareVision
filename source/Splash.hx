package;

import flixel.FlxState;

import funkin.FunkinAssets;
import funkin.states.TitleState;
import funkin.video.FunkinVideoSprite;

import flixel.addons.display.FlxPieDial;

using StringTools;

@:access(flixel.FlxGame)
class Splash extends FlxState
{
	var _cachedAutoPause:Bool;
	
	var spriteEvents:FlxTimer;
	var logo:FlxSprite;

	#if VIDEOS_ALLOWED
	var skipTime:Float = 0;
	var skipLoad:FlxPieDial;
	var video:FunkinVideoSprite;
	#end
	
	override function create()
	{
		_cachedAutoPause = FlxG.autoPause;
		FlxG.autoPause = false;
		
		FlxTimer.wait(1, () -> {
			#if VIDEOS_ALLOWED
			video = new FunkinVideoSprite();
			add(video);
			video.onFormat(() -> {
				video.setGraphicSize(0, FlxG.height);
				video.updateHitbox();
				video.screenCenter();
			});
			video.onEnd(finish);
			//FOR ONLY VIDEO
			skipLoad = new FlxPieDial(0, 0, 30, FlxColor.WHITE, 60, FlxPieDialShape.SQUARE, true, 16);
			skipLoad.setPosition(FlxG.width - (skipLoad.width + 30), FlxG.height - (skipLoad.height + 22));
			add(skipLoad);
			//
			if (video.load(Paths.video('intro'))) video.delayAndStart();
			else
			#end
			
			logoFunc();
		});
	}
	
	override function update(elapsed:Float)
	{
		if (logo != null)
		{
			logo.updateHitbox();
			logo.screenCenter();
			
			if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER)
			{
				finish();
			}
		}
		#if VIDEOS_ALLOWED
				if (video != null)
			{
				if (FlxG.keys.pressed.SPACE || FlxG.keys.pressed.ENTER)
				{
					skipTime = Math.max(0, Math.min(1, skipTime + elapsed));
				}
				else if (skipTime > 0)
					{
						skipTime = Math.max(0, FlxMath.lerp(skipTime, -0.1, FlxMath.bound(elapsed * 3, 0, 1)));
					}
					skipLoad.amount = Math.min(1, Math.max(0, (skipTime / 1) * 1.025));
					if(skipTime >= 1)
						{
							finish();
						}
			}
		#end
		super.update(elapsed);
	}
	
	function logoFunc()
	{
		var folder:Array<String> = [];
		if (!FileSystem.isDirectory('assets/images/branding') || (folder = FileSystem.readDirectory('assets/images/branding')).length == 0)
		{
			finish();
			return;
		}
		
		folder = folder.filter(str -> !FileSystem.isDirectory('assets/images/branding/$str'));
		
		var img = FlxG.random.getObject(folder);
		trace(folder);
		
		logo = new FlxSprite().loadGraphic(Paths.image('branding/${Path.withoutExtension(img)}'));
		logo.screenCenter();
		logo.visible = false;
		add(logo);
		
		spriteEvents = new FlxTimer().start(1, (stupidFuckingTimer:FlxTimer) -> {
			var step = 0;
			new FlxTimer().start(0.25, (t:FlxTimer) -> {
				switch (step++)
				{
					case 0:
						FlxG.sound.volume = 1;
						FlxG.sound.play(Paths.sound('intro'));
						logo.visible = true;
						logo.scale.set(0.2, 1.25);
						t.reset(0.06125);
					case 1:
						logo.scale.set(1.25, 0.5);
						t.reset(0.06125);
					case 2:
						logo.scale.set(1.125, 1.125);
						FlxTween.tween(logo.scale, {x: 1, y: 1}, 0.25, {ease: FlxEase.elasticOut});
						t.reset(1.25);
					case 3:
						FlxTween.tween(logo.scale, {x: 0.2, y: 0.2}, 1.5, {ease: FlxEase.quadIn});
						FlxTween.tween(logo, {alpha: 0}, 1.5,
							{
								ease: FlxEase.quadIn,
								onComplete: (t:FlxTween) -> {
									FlxTimer.wait(0.8, finish);
								}
							});
				}
			});
		});
	}
	
	function finish()
	{
		if (spriteEvents != null)
		{
			spriteEvents.cancel();
			spriteEvents.destroy();
		}
		#if VIDEOS_ALLOWED
		video.stop();
		video.destroy();
		skipLoad.destroy();
		#end
		complete();
	}
	
	function complete()
	{
		FlxG.autoPause = _cachedAutoPause;
		FlxG.switchState(() -> Type.createInstance(Main.startMeta.initialState, []));
	}
}
