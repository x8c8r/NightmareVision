package funkin.objects;

import flixel.graphics.frames.FlxAtlasFrames;

import animate.FlxAnimateFrames;
import animate.FlxAnimate;

import flixel.util.FlxSignal.FlxTypedSignal;

// highly based of base games bopper class
// i liked it alot
class Bopper extends FlxAnimate
{
	@:inheritDoc(flixel.animation.FlxAnimationController.onFinish)
	public final onAnimationFinish = new FlxTypedSignal<(animName:String) -> Void>();
	
	@:inheritDoc(flixel.animation.FlxAnimationController.onFrameChange)
	public final onAnimationFrameChange = new FlxTypedSignal<(animName:String, frameNumber:Int, frameIndex:Int) -> Void>();
	
	@:inheritDoc(flixel.animation.FlxAnimationController.onLoop)
	public final onAnimationLoop = new FlxTypedSignal<(animName:String) -> Void>();
	
	/**
	 * Texture atlas instance. Initiated through `loadAtlas`.
	 */
	@:deprecated("animateAtlas is deprecated. Use this Bopper directly instead.")
	public var animateAtlas(get, never):Null<FlxAnimate>;
	
	function get_animateAtlas():Null<FlxAnimate>
	{
		if (library != null) return this;
		return null;
	}
	
	/**
	 *	Animation offsets
	 * 
	 * applied through `playAnim`
	 */
	public var animOffsets:Map<String, Array<Float>> = [];
	
	/**
	 * However many beats between dances
	 */
	public var danceEveryNumBeats:Int = 2;
	
	/**
	 * Whether the bopper should dance left and right.
	 * - If true, alternate playing `danceLeft` and `danceRight`.
	 * - If false, play `idle` every time.
	 *
	 * You can manually set this value, or you can leave it as `null` to determine it automatically.
	 */
	public var alternatingDance:Null<Bool> = null;
	
	/**
	 * If `false`, playAnim will no longer function
	 * 
	 * used by `playAnimForDuration`'s `force` arguement.
	 */
	public var canPlayAnimations:Bool = true;
	
	/**
	 * internal tracker for alternating dance chars.
	 */
	var danced:Bool = false;
	
	/**
	 * Suffix added to the characters `dance` animation.
	 */
	public var idleSuffix:String = '';
	
	/**
	 * Used in conjunction with `playAnim`
	 * 
	 * If true, offsets will be scaled to match the current scale.
	 */
	public var scalableOffsets:Bool = false;
	
	//-----
	
	public function new(x:Float = 0, y:Float = 0, danceEveryNumBeats:Int = 2)
	{
		super(x, y);
		this.danceEveryNumBeats = danceEveryNumBeats;
		
		this.animation.onFinish.add((anim) -> onAnimationFinish.dispatch(anim));
		this.animation.onFrameChange.add((anim, num, idx) -> onAnimationFrameChange.dispatch(anim, num, idx));
		this.animation.onLoop.add((anim) -> onAnimationLoop.dispatch(anim));
	}
	
	/**
	 * Loads frames onto the sprite
	 * 
	 * It can load multiple sparrow, packer, and texture atlases simultaneously.
	 * 
	 * This is the recommended way to load frames for a bopper
	 * @param path the image path to the frames. For multiple, split the path with `,` For texture atlas, Provide the path to the folder.
	 * 
	 * @return this `Bopper` instance. Useful for chaining
	 */
	public function loadAtlas(path:String):Bopper
	{
		final splitPath = path.split(',');
		
		var framesFound:Array<FlxAtlasFrames> = [];
		
		var containsFlxAnimate:Bool = false;
		
		for (path in splitPath)
		{
			final isAtlasSprite = FunkinAssets.exists(Paths.getPath('images/$path/Animation.json', null, true));
			if (isAtlasSprite)
			{
				var atlas = FlxAnimateFrames.fromAnimate(Paths.getPath('images/$path', null, true), null, null, null, false, {cacheOnLoad: true});
				if (atlas != null)
				{
					// unsure if flxanimate messes with the buffer or not but if it does then drop this
					if (ClientPrefs.gpuCaching)
					{
						if (atlas.parent.bitmap != null) atlas.parent.bitmap.disposeImage();
					}
					
					containsFlxAnimate = true;
					
					framesFound.push(atlas);
				}
			}
			else
			{
				var atlas = Paths.getAtlasFrames(path);
				
				if (atlas != null)
				{
					framesFound.push(atlas);
				}
			}
		}
		
		if (framesFound.length != 0)
		{
			if (containsFlxAnimate) // a bit hacky workaround.. we cant keep use cached bitmaps in multi collection // look into this later
			{
				for (collection in framesFound)
				{
					@:privateAccess
					{
						var path = collection.parent.key.withoutExtension();
						if (Paths.tempAtlasFramesCache.exists(path))
						{
							Paths.tempAtlasFramesCache.remove(path);
						}
					}
					
					if (FunkinAssets.cache.currentTrackedGraphics.exists(collection.parent.key))
					{
						FunkinAssets.cache.currentTrackedGraphics.remove(collection.parent.key);
					}
					
					collection.parent.persist = false;
				}
			}
			this.frames = FlxAnimateFrames.combineAtlas(framesFound);
		}
		
		return this;
	}
	
	/**
	 * Helper function to quickly set an anim offset
	 */
	public function addOffset(anim:String, x:Float = 0, y:Float = 0):Void
	{
		animOffsets[anim] = [x, y];
	}
	
	/**
	 * Ensures a anim exists before playing
	 * 
	 * If there is no anim but there is a suffix, it will strip the suffix and try again
	 * 
	 * If still fails, `Null` is returned.
	 */
	public function correctAnimationName(animName:String):Null<String> // from base game !
	{
		if (hasAnim(animName)) return animName;
		
		// strip any post fix
		if (animName.lastIndexOf('-') != -1)
		{
			final correctedName = animName.substring(0, animName.lastIndexOf('-'));
			return correctAnimationName(correctedName);
		}
		else
		{
			// trace('missing anim ' + animName);
			return null;
		}
	}
	
	/**
	 * Use over `animation.play`
	 */
	@:inheritDoc(flixel.animation.FlxAnimationController.play)
	public function playAnim(animToPlay:String, isForced:Bool = false, isReversed:Bool = false, frame:Int = 0):Void
	{
		if (!canPlayAnimations) return;
		
		final correctedAnim = correctAnimationName(animToPlay);
		
		if (correctedAnim == null) return;
		
		animation.play(correctedAnim, isForced, isReversed, frame);
		
		final animationOffsets = animOffsets.get(correctedAnim);
		
		if (animationOffsets != null)
		{
			offset.set(animationOffsets[0], animationOffsets[1]);
			
			if (scalableOffsets)
			{
				offset.x *= scale.x;
				offset.y *= scale.y;
			}
		}
	}
	
	final forcedAnimationTimer:FlxTimer = new FlxTimer();
	
	/**
	 * Plays a animation for a given amount of time and will `dance` when it is done
	 * @param forced If true, the character will not play any other animation until the duration is complete
	 */
	public function playAnimForDuration(animToPlay:String, duration:Float = 0.6, forced:Bool = false)
	{
		if (forced) canPlayAnimations = true;
		playAnim(animToPlay, true);
		
		if (forced) canPlayAnimations = false;
		forcedAnimationTimer.start(duration, tmr -> {
			if (forced) canPlayAnimations = true;
			dance();
		});
	}
	
	/**
	 * If false, This `Bopper` will be unable to dance
	 */
	public var canDance:Bool = true;
	
	/**
	 * Makes the sprite "dance".
	 */
	public function dance(forced:Bool = false):Void
	{
		if (alternatingDance == null)
		{
			recalculateDanceIdle();
		}
		
		if (!canDance) return;
		
		if (alternatingDance)
		{
			danced = !danced;
			if (danced) playAnim('danceRight$idleSuffix', forced);
			else playAnim('danceLeft$idleSuffix', forced);
		}
		else
		{
			playAnim('idle$idleSuffix', forced);
		}
	}
	
	/**
	 * Updates if the current character has a alternating `left/right` dance
	 */
	public function recalculateDanceIdle():Void
	{
		alternatingDance = hasAnim('danceLeft' + idleSuffix) && hasAnim('danceRight' + idleSuffix);
	}
	
	public function onBeatHit(beat:Int)
	{
		if (!isAnimNull() && beat % danceEveryNumBeats == 0) dance();
	}
	
	override function destroy()
	{
		onAnimationFinish.removeAll();
		onAnimationFrameChange.removeAll();
		onAnimationFinish.removeAll();
		
		super.destroy();
	}
	
	public inline function getAnimName():String return isAnimNull() ? '' : animation.curAnim.name;
	
	public inline function hasAnim(anim:String):Bool
	{
		return animation.exists(anim);
	}
	
	public inline function isAnimNull():Bool
	{
		return animation.curAnim == null;
	}
	
	public inline function isAnimFinished():Bool
	{
		return isAnimNull() ? false : animation.curAnim.finished;
	}
	
	public inline function pauseAnim():Void
	{
		animation.pause();
	}
	
	public inline function resumeAnim():Void
	{
		animation.resume();
	}
	
	public inline function getAnimNumFrames():Int
	{
		if (isAnimNull()) return 0;
		
		return animation.curAnim.numFrames;
	}
	
	public var animCurFrame(get, set):Int;
	
	inline function get_animCurFrame():Int
	{
		return isAnimNull() ? 0 : animation.curAnim.curFrame;
	}
	
	inline function set_animCurFrame(value:Int):Int
	{
		if (isAnimNull()) return 0;
		
		return animation.curAnim.curFrame = value;
	}
	
	public function addAnimByPrefix(anim:String, prefix:String, fps:Int = 24, looping:Bool = true, flipX:Bool = false, flipY:Bool = false)
	{
		if (library != null && this.anim.findFrameLabelIndices(prefix).length > 0)
		{
			this.anim.addByFrameLabel(anim, prefix, fps, looping, flipX, flipY);
		}
		else if (checkLibraryForSymbol(library, prefix))
		{
			this.anim.addBySymbol(anim, prefix, fps, looping, flipX, flipY);
		}
		else
		{
			animation.addByPrefix(anim, prefix, fps, looping, flipX, flipY);
		}
	}
	
	public function addAnimByIndices(anim:String, prefix:String, indices:Array<Int>, fps:Int = 24, looping:Bool = true, flipX:Bool = false, flipY:Bool = false)
	{
		if (library != null && this.anim.findFrameLabelIndices(prefix).length > 0)
		{
			this.anim.addByFrameLabelIndices(anim, prefix, indices, fps, looping, flipX, flipY);
		}
		else if (checkLibraryForSymbol(library, prefix))
		{
			this.anim.addBySymbolIndices(anim, prefix, indices, fps, looping, flipX, flipY);
		}
		else
		{
			animation.addByIndices(anim, prefix, indices, '', fps, looping, flipX, flipY);
		}
	}
	
	public inline function removeAnim(anim:String)
	{
		animation.remove(anim);
	}
	
	public inline function finishAnim()
	{
		if (isAnimNull()) return;
		
		animation.finish();
	}
	
	public inline function stopAnim()
	{
		if (isAnimNull()) return;
		
		animation.stop();
	}
	
	@:access(animate.FlxAnimateFrames)
	static function checkLibraryForSymbol(atlasLibrary:FlxAnimateFrames, symbolName:String) // exists symbol doesnt check additional collections so heres my workaround.
	{
		if (atlasLibrary == null) return false;
		
		if (atlasLibrary.existsSymbol(symbolName)) return true;
		
		for (collection in atlasLibrary.addedCollections)
		{
			if (collection.dictionary.exists(symbolName)) return true;
		}
		
		return false;
	}
}
