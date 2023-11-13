package states;

import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets as LimeAssets;
import flixel.addons.util.FlxAsyncLoop;
import lime.utils.AssetManifest;
import flixel.util.FlxGradient;
import lime.utils.AssetLibrary;
import openfl.utils.AssetType;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import sys.thread.Thread;
import flixel.FlxSprite;
import lime.app.Promise;
import flixel.ui.FlxBar;
import flixel.FlxState;
import lime.app.Future;
import haxe.io.Path;
import flixel.FlxG;
import haxe.Json;

import Stage;
import Song.SwagSong;
import Note.NoteData;
import Note.EventData;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using SavedFiles;
using StringTools;

class LoadingState extends MusicBeatState {
	public static var globalStuff:Array<Dynamic> = [];
	public var toLoadStuff:Array<Dynamic> = [];

	public static var textLoad:String = "";
	public var background:FlxSprite;
	public var loadingText:Alphabet;

	private var tempLoadingStuff:Array<Dynamic> = [];
	private var totalCount:Int = 0;
	
	private var WithMusic:Bool = false;
	
	private var thdLoading:Thread;
	private var loadedAll:Bool = false;

	public var TARGET:MusicBeatState;

	public function new(_target:MusicBeatState, _toLoadStuff:Array<Dynamic>, withMusic:Bool = false):Void {
		if(_toLoadStuff == null){_toLoadStuff = [];}
		this.toLoadStuff = _toLoadStuff;
		this.WithMusic = withMusic;
		this.TARGET = _target;

		for(i in globalStuff){toLoadStuff.push(i);}

		super();
	}

	override function create():Void {
		FlxG.mouse.visible = false;
		textLoad = "Starting";

		if(!WithMusic && FlxG.sound.music != null){FlxG.sound.music.stop();}
		
		preLoadStuff();
		
		totalCount = tempLoadingStuff.length;
		
		background = new FlxSprite().loadGraphic(Paths.image('menuBG').getGraphic());
		background.setGraphicSize(FlxG.width, FlxG.height);
        background.color = 0xffff8cf7;
		background.screenCenter();
		add(background);

		var shape_1:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, 100, FlxColor.BLACK); add(shape_1);
        var shape_2:FlxSprite = new FlxSprite(0, 105).makeGraphic(FlxG.width, 5, FlxColor.BLACK); add(shape_2);
        var shape_3:FlxSprite = new FlxSprite(0, FlxG.height - 110).makeGraphic(FlxG.width, 5, FlxColor.BLACK); add(shape_3);
        var shape_4:FlxSprite = new FlxSprite(0, FlxG.height - 100).makeGraphic(FlxG.width, 100, FlxColor.BLACK); add(shape_4);

		loadingText = new Alphabet(20, 525, [{text:'${LangSupport.getText("loading_info_1")} 0%'}]); add(loadingText);

		loadStuff();
				
		super.create();
	}

	override function update(elapsed:Float){
		super.update(elapsed);
	}

	function updateText():Void {
		var percent:Int = Std.int((totalCount - tempLoadingStuff.length) * 100 / totalCount);
		if(loadingText.text == '${LangSupport.getText("loading_info_1")} ${percent} ${textLoad}'){return;}
		loadingText.cur_data = [{text:'${LangSupport.getText("loading_info_1")} ${percent}% ${textLoad}'}];
		loadingText.loadText();
	}

	private function preLoadStuff():Void {
		tempLoadingStuff.push({type:MUSIC,instance:Paths.music("breakfast", "shared")});
		tempLoadingStuff.push({type:IMAGE,instance:Paths.image("icons/icon-face")});
		tempLoadingStuff.push({type:SOUND,instance:Paths.sound("confirmMenu")});
		tempLoadingStuff.push({type:MUSIC,instance:Paths.music("break_song")});
		tempLoadingStuff.push({type:MUSIC,instance:Paths.music("freakyMenu")});
		tempLoadingStuff.push({type:SOUND,instance:Paths.sound("cancelMenu")});
		tempLoadingStuff.push({type:SOUND,instance:Paths.sound("scrollMenu")});
		tempLoadingStuff.push({type:IMAGE,instance:Paths.image("alphabet")});
		
		for(stuff in toLoadStuff){
			if(stuff.type == IMAGE || stuff.type == SOUND || stuff.type == MUSIC || stuff.type == TEXT){ continue; }
			
			switch(stuff.type){
				case "SONG":{
					var _song:SwagSong = cast stuff.instance;
					
					tempLoadingStuff.push({ type: SOUND, instance:Paths.inst(_song.song, _song.category)});
					
					if(_song.hasVoices){
						for(i in 0..._song.sectionStrums.length){
							if(_song.sectionStrums[i].charToSing.length <= 0){continue;}
							if(_song.characters.length <= _song.sectionStrums[i].charToSing[0]){continue;}
							var voice_path:String = Paths.voice(i, _song.characters[_song.sectionStrums[i].charToSing[0]][0], _song.song, _song.category);
							if(!Paths.exists(voice_path)){continue;}
							tempLoadingStuff.push({type:SOUND,instance:voice_path});
						}
					}

					for(p in StrumLine.P_STAT){
						tempLoadingStuff.push({ type:IMAGE, instance: Paths.styleImage(p.popup, _song.uiStyle, 'shared') });
					}

					for(p in PlayState.introAssets){
						if(p.asset != null){tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage(p.asset, _song.uiStyle, 'shared') });}
						if(p.sound != null){tempLoadingStuff.push({ type: SOUND, instance: Paths.styleSound(p.sound, _song.uiStyle, 'shared') });}
					}

					tempLoadingStuff.push({type:SOUND,instance:Paths.styleSound('fnf_loss_sfx', _song.uiStyle, 'shared')});
					tempLoadingStuff.push({type:MUSIC,instance:Paths.styleMusic('gameOverEnd', _song.uiStyle, 'shared')});
					tempLoadingStuff.push({type:SOUND,instance:Paths.styleSound('missnote1', _song.uiStyle, 'shared')});
					tempLoadingStuff.push({type:SOUND,instance:Paths.styleSound('missnote2', _song.uiStyle, 'shared')});
					tempLoadingStuff.push({type:SOUND,instance:Paths.styleSound('missnote3', _song.uiStyle, 'shared')});
					tempLoadingStuff.push({type:MUSIC,instance:Paths.styleMusic('gameOver', _song.uiStyle, 'shared')});
					
					Stage.getStageScript(_song.stage).exFunction("addToLoad", [tempLoadingStuff]);

					var song_path:String = Paths.song_script(_song.song);
					if(Paths.exists(song_path)){
						var song_script:Script = new Script();
						song_script.Name = "ScriptSong";
						song_script.exScript(song_path.getText());
						TARGET.tempScripts.set("ScriptSong", song_script);
					}

					for(char in _song.characters){
						Character.addToLoad(tempLoadingStuff, char[0], char[4]);
					}

					for(ev in _song.events){
						var cur_Event:EventData = Note.getEventData(ev);
						if(cur_Event == null || cur_Event.isBroken){continue;}
						for(dat in cur_Event.eventData){
							if(!Paths.exists(Paths.event(dat[0]))){continue;}
							tempLoadingStuff.push({type:"FUNCTION",instance:function(){
								textLoad = "[Events]";
								TARGET.pushTempScript(dat[0]);
								TARGET.tempScripts.get(dat[0]).exFunction("preload_event", cast(dat[1],Array<Dynamic>));
							}});
						}
					}

					for(strum in _song.sectionStrums){
						for(s in strum.notes){
							for(ss in s.sectionNotes){
								var cur_Note:NoteData = Note.getNoteData(ss);
								var events_data:Array<Dynamic> = [];
								if(cur_Note.eventData != null){events_data = cur_Note.eventData.copy();}
								if(cur_Note.preset != null && cur_Note.preset != "Default"){
									var json_path:String = Paths.getPath('${cur_Note.preset}.json', TEXT, 'notes');
									if(Paths.exists(json_path)){
										var event_list:Array<Dynamic> = json_path.getJson().Events;
										for(e in event_list){events_data.push(e);}
									}
								}
								for(dat in events_data){
									if(!Paths.exists(Paths.event(dat[0]))){continue;}
									tempLoadingStuff.push({type:"FUNCTION",instance:function(){
										textLoad = "[Events]";
										TARGET.pushTempScript(dat[0]);
										TARGET.tempScripts.get(dat[0]).exFunction("preload_event", cast(dat[1],Array<Dynamic>));
									}});
								}
							}
						}
					}

					continue;
				}
				case "PRELOAD":{
					if(stuff.instance != null){stuff.instance(this);}
					continue;
				}
			}

			tempLoadingStuff.push(stuff);
		}
		
		for(s in TARGET.scripts){s.exFunction("addToLoad", [tempLoadingStuff]);}
	}

	private function loadStuff():Void {
		thdLoading = Thread.create(() -> {
			while(true){
				if(tempLoadingStuff.length <= 0){onLoad(); return;}
				var _stuff:Dynamic = tempLoadingStuff.shift(); //trace(tempLoadingStuff.length);
				if(_stuff.type == null || _stuff.instance == null){ trace("Error | " + _stuff); return;}

				switch(_stuff.type){
					default: { trace(_stuff); }
					case IMAGE: {textLoad = "[Graphics]"; updateText(); SavedFiles.getGraphic(_stuff.instance);}
					case SOUND, MUSIC: {textLoad = "[Sounds and Music]"; updateText(); SavedFiles.getSound(_stuff.instance);}
					case TEXT: {textLoad = "[Texts]"; updateText(); SavedFiles.getText(_stuff.instance);}
					case "FUNCTION":{_stuff.instance();}
				}
			}
		});
	}

	private function onLoad():Void {
		if(loadedAll){return;} loadedAll = true;
		trace('Loaded All -> $TARGET');
		VoidState.clearAssets = false;
		MusicBeatState._switchState(TARGET);
	}
}