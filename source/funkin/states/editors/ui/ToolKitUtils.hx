package funkin.states.editors.ui;

import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.containers.ListView;
import haxe.ui.core.Screen;

import flixel.util.typeLimit.OneOfTwo;
import flixel.FlxG;

import haxe.ui.core.*;
import haxe.ui.components.DropDown;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.notifications.NotificationData;

class ToolKitUtils
{
	/**
	 * Clears a dropdown and refills with new items.
	 * @param dropDown 
	 * @param items 
	 */
	public static function populateList(container:Null<OneOfTwo<DropDown, ListView>>, items:Array<DropDownItem>)
	{
		if (container == null) return;
		
		if (container is DropDown)
		{
			var dropDown:DropDown = cast container;
			dropDown.dataSource.removeAll();
			
			for (i in items)
			{
				dropDown.dataSource.add(i);
			}
		}
		else if (container is ListView)
		{
			var list:ListView = cast container;
			list.dataSource.removeAll();
			
			for (i in items)
			{
				list.dataSource.add(i);
			}
		}
	}
	
	public static function addToList(container:Null<OneOfTwo<DropDown, ListView>>, ...items:DropDownItem)
	{
		if (container == null || items.length == 0) return;
		
		if (container is DropDown)
		{
			var dropDown:DropDown = cast container;
			
			for (i in items.toArray())
			{
				dropDown.dataSource.add(i);
			}
		}
		else if (container is ListView)
		{
			var list:ListView = cast container;
			for (i in items.toArray())
			{
				list.dataSource.add(i);
			}
		}
	}
	
	/**
	 * Binds the dialog to the screen size. prevents stupid people doing stupid things
	 * @param dialog 
	 */
	public static function bindDialogToView(dialog:Dialog)
	{
		if (dialog == null) return;
		dialog.onDragEnd = (ui) -> {
			var repositioned = false;
			if (dialog.top < 50)
			{
				dialog.y = 50;
				repositioned = true;
			}
			if ((dialog.top + dialog.dialogTitle.height) > FlxG.height)
			{
				dialog.y = FlxG.height - dialog.dialogTitle.height - 10;
				repositioned = true;
			}
			
			if (dialog.screenLeft < (-dialog.width * 0.5))
			{
				dialog.x = 10;
				repositioned = true;
			}
			
			if (dialog.screenRight > (FlxG.width + (dialog.width * 0.5)))
			{
				dialog.x = FlxG.width - dialog.dialogTitle.width - 10;
				repositioned = true;
			}
			
			if (repositioned) FlxG.sound.play(Paths.sound('ui/bong'));
		}
	}
	
	public static function makeSimpleDropDownItem(id:String):DropDownItem return {id: id, text: id};
	
	public static function isDropDownItem(data:Dynamic):Bool return (data != null && data.id != null && data.text != null); // is this even necessary tbh ?
	
	public static function makeNotification(title:String, body:String, type:NotificationType = Default)
	{
		var data:NotificationData = switch (type)
		{
			case Success:
				{title: title, body: body, icon: 'assets/images/editors/notification_success.png'};
			case Warning:
				{title: title, body: body, icon: 'assets/images/editors/notification_warn.png'};
			case Info:
				{title: title, body: body, icon: 'assets/images/editors/notification_neutral.png'};
				
			default: {title: title, body: body, type: type};
		}
		final noti = NotificationManager.instance.addNotification(data);
		
		switch (type)
		{
			case Success:
				noti.addClass('green-notification');
			case Warning:
				noti.addClass('yellow-notification');
			case Info:
				noti.addClass("blue-notification");
			default:
		}
	}
	
	static var _hitTest:flixel.math.FlxPoint = null;
	
	public static function isHaxeUIHovered(camera:FlxCamera)
	{
		// ok just dont fucking work sure
		// trace(FocusManager.instance.focus);
		_hitTest = FlxG.mouse.getViewPosition(camera, _hitTest);
		return Screen.instance.hasSolidComponentUnderPoint(_hitTest.x, _hitTest.y);
	}
	
	public static var currentFocus:InteractiveComponent = null;
	
	static var iterated:Array<Component> = [];
	
	public static function update():Void
	{
		// some duct tape
		// to make using haxe ui more stable
		
		if (FlxG.mouse.justMoved || FlxG.mouse.justPressed || FlxG.mouse.justReleased)
		{
			iterated.resize(0);
			currentFocus = null;
			
			if (FlxG.mouse.justPressed) for (component in Screen.instance.rootComponents) unfocusIter(component);
			
			iterated.resize(0);
			
			for (component in Screen.instance.rootComponents) focusIter(component);
		}
	}
	
	static function unfocusIter(component:Component):Void
	{
		if (iterated.contains(component)) return;
		
		if (component is InteractiveComponent && cast(component, InteractiveComponent).focus)
		{
			_hitTest = FlxG.mouse.getViewPosition(funkin.utils.CameraUtil.lastCamera, _hitTest);
			
			if (!component.hasComponentUnderPoint(_hitTest.x, _hitTest.y))
			{
				cast(component, InteractiveComponent).focus = false;
				return;
			}
		}
		
		@:privateAccess if (component._children != null) for (child in component._children) unfocusIter(child);
	}
	
	static function focusIter(component:Component):Void
	{
		if (iterated.contains(component) || currentFocus != null) return;
		
		var focusable:Bool = (
			component is InteractiveComponent &&
			(!(component is haxe.ui.components.CheckBox)) &&
			(!(component is haxe.ui.components.Button) || component is haxe.ui.components.DropDown) // fuck you TabButton
		);
		
		if (focusable && cast(component, InteractiveComponent).focus)
		{
			currentFocus = cast component;
			return;
		}
		
		@:privateAccess if (component._children != null) for (child in component._children) focusIter(child);
	}
}

typedef DropDownItem =
{
	id:String,
	text:String
}
