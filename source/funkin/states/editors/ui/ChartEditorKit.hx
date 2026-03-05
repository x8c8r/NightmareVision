package funkin.states.editors.ui;

import haxe.ui.containers.dialogs.Dialog;

import funkin.data.CharacterData;

using funkin.states.editors.ui.ToolKitUtils;

@:build(haxe.ui.ComponentBuilder.build("assets/excluded/ui/chartEditor/SongDialog.xml"))
class SongDialog extends Dialog {}

class ChartEditorUI extends flixel.group.FlxSpriteContainer
{
	public var songDialog:SongDialog;
	
	public var song = PlayState.SONG;
	public var charter:ChartEditorState;
	
	public function new(charter:ChartEditorState)
	{
		super();
		
		this.charter = charter;
		
		songDialog = new SongDialog();
		add(songDialog);
		songDialog.showDialog(false);
		
		songDialog.x = 15;
		songDialog.y = 50;
		
		songDialog.bindDialogToView();
		
		bind();
	}
	
	@:access(funkin.states.editors.ChartEditorState)
	public function bind():Void
	{
		if (charter == null) return;
		
		songDialog.songNameField.value = song.song;
		songDialog.songNameField.onChange = function(event) {
			trace(song.song);
			song.song = event.value;
		}
		
		songDialog.initialBpmStepper.value = song.bpm;
		songDialog.initialBpmStepper.onChange = function(event) {
			Conductor.bpm = song.bpm = event.value;
			Conductor.mapBPMChanges(song);
		}
		
		songDialog.songSpeedStepper.value = song.speed;
		songDialog.songSpeedStepper.onChange = function(event) song.speed = event.value;
		
		songDialog.strumsStepper.value = song.lanes;
		songDialog.strumsStepper.onChange = function(event) {
			song.lanes = ChartEditorState.lanes = event.value;
			
			charter.reloadStrumShit();
			charter.updateGrid();
			charter.reloadGridLayer();
			
			charter.gridZoom();
		}
		
		songDialog.keysStepper.value = song.keys;
		songDialog.keysStepper.onChange = function(event) {
			song.keys = event.value;
			
			charter.reloadStrumShit();
			charter.updateGrid();
			charter.reloadGridLayer();
			
			charter.gridZoom();
		}
		
		refreshCharacterDropdowns();
		refreshStageDropdown();
		refreshSkinDropdown();
		
		songDialog.bfDropdown.onChange = function(event) {
			if (!event.data.isDropDownItem()) return;
			
			charter.bfIcon = CharacterParser.fetchInfo(song.player1 = event.data.id).healthicon;
			charter.updateHeads();
		}
		songDialog.dadDropdown.onChange = function(event) {
			if (!event.data.isDropDownItem()) return;
			
			charter.dadIcon = CharacterParser.fetchInfo(song.player2 = event.data.id).healthicon;
			charter.updateHeads();
		}
		songDialog.gfDropdown.onChange = function(event) {
			if (!event.data.isDropDownItem()) return;
			
			charter.gfIcon = CharacterParser.fetchInfo(song.gfVersion = event.data.id).healthicon;
			charter.updateHeads();
		}
		
		songDialog.noteSkinDropdown.onChange = function(event) {
			if (!event.data.isDropDownItem()) return;
			
			song.arrowSkin = event.data.id;
			// todo
		}
	}
	
	function refreshCharacterDropdowns():Void
	{
		var characterList:Array<String> = [];
		
		#if MODS_ALLOWED
		var dir = Paths.listAllFilesInDirectory('data/characters/');
		for (i in Paths.listAllFilesInDirectory('characters/'))
			dir.push(i);
			
		for (file in dir)
		{
			if (file.endsWith('.json') || file.endsWith('.xml'))
			{
				var charToCheck:String = file.withoutDirectory().withoutExtension();
				
				if (!characterList.contains(charToCheck)) characterList.push(charToCheck);
			}
		}
		#else
		characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end
		
		for (dropdown in [songDialog.bfDropdown, songDialog.dadDropdown, songDialog.gfDropdown])
		{
			dropdown.populateList([for (char in characterList) ToolKitUtils.makeSimpleDropDownItem(char)]);
			dropdown.dataSource.sort(null, ASCENDING);
		}
		
		songDialog.bfDropdown.selectedItem = song.player1;
		songDialog.dadDropdown.selectedItem = song.player2;
		songDialog.gfDropdown.selectedItem = song.gfVersion;
	}
	
	function refreshStageDropdown():Void
	{
		#if MODS_ALLOWED
		var directories:Array<String> = [
			Paths.mods('data/stages/'),
			Paths.mods(Mods.currentModDirectory + '/data/stages/'),
			Paths.getCorePath('data/stages/'),
			
			Paths.mods('stages/'),
			Paths.mods(Mods.currentModDirectory + '/stages/'),
			Paths.getCorePath('stages/')
		];
		for (mod in Mods.globalMods)
		{
			directories.push(Paths.mods('$mod/data/stages/'));
			directories.push(Paths.mods('$mod/stages/'));
		}
		
		var stages:Array<String> = ['stage'];
		
		for (directory in directories)
		{
			if (!FunkinAssets.exists(directory)) continue;
			
			for (file in FunkinAssets.readDirectory(directory))
			{
				if (!file.endsWith('.json')) continue;
				
				var stage:String = file.substr(0, file.length - 5);
				
				if (!stages.contains(stage)) stages.push(stage);
			}
		}
		#else
		var directories:Array<String> = [Paths.getCorePath('data/stages/'), Paths.getCorePath('stages/')];
		
		var stages:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));
		#end
		
		songDialog.stageDropdown.populateList([for (stage in stages) ToolKitUtils.makeSimpleDropDownItem(stage)]);
		songDialog.stageDropdown.dataSource.sort(null, ASCENDING);
		songDialog.stageDropdown.selectedItem = song.stage;
	}

	function refreshSkinDropdown():Void
	{
		var directories:Array<String> = [
			#if MODS_ALLOWED
			Paths.mods('data/noteskins/'),
			Paths.mods(Mods.currentModDirectory + '/data/noteskins/'),
			#end
			Paths.getCorePath('data/noteskins/')
		];
		#if MODS_ALLOWED for (mod in Mods.globalMods) directories.push(Paths.mods('$mod/data/noteskins/')); #end
		
		var noteskins:Array<String> = ['default'];
		
		for (directory in directories)
		{
			if (!FunkinAssets.exists(directory)) continue;
			
			for (file in FunkinAssets.readDirectory(directory))
			{
				if (!file.endsWith('.json')) continue;
				
				var skin:String = file.substr(0, file.length - 5);
				
				if (!noteskins.contains(skin)) noteskins.push(skin);
			}
		}
		
		for (dropdown in [songDialog.noteSkinDropdown])
		{
			dropdown.populateList([for (skin in noteskins) ToolKitUtils.makeSimpleDropDownItem(skin)]);
			dropdown.dataSource.sort(null, ASCENDING);
		}
		
		songDialog.noteSkinDropdown.selectedItem = song.arrowSkin;
		// songDialog.splashSkinDropdown.selectedItem = song.splashSkin;
	}
}