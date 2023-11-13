package;

import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import haxe.format.JsonParser;
import openfl.events.Event;
import haxe.DynamicAccess;
import lime.utils.Assets;
import haxe.Exception;
import flixel.FlxG;
import haxe.Json;

import Note;

#if desktop
import sys.FileSystem;
import sys.io.File;
#end

using SavedFiles;
using StringTools;

typedef SwagEvent = {
	var events:Array<Dynamic>;
}
typedef SwagSong = {
	var song:String;
	var category:String;
	var difficulty:String;

	var bpm:Float;
	var speed:Float;

	var hasVoices:Bool;

	var validScore:Bool;

	var single_player:Int;

	var uiStyle:String;

	var stage:String;	
	var characters:Array<Dynamic>;

	var generalSection:Array<SwagGeneralSection>;
	var sectionStrums:Array<SwagStrum>;
	var events:Array<Dynamic>;
}

typedef SwagStrum = {
	var isPlayable:Bool;
	var noteStyle:String;
	var keys:Int;
	var charToSing:Array<Int>;
	var notes:Array<SwagSection>;
}

typedef SwagSection = {
	var charToSing:Array<Int>;
	var changeSing:Bool;

	var altAnim:Bool;
	var sectionNotes:Array<Dynamic>;
}

typedef SwagGeneralSection = {
	var bpm:Float;
	var changeBPM:Bool;
	
	var lengthInSteps:Int;

	var strumToFocus:Int;
	var charToFocus:Int;
}

//
typedef SongsData = {
	var weekData:Array<ItemWeek>;
	var freeplayData:Array<ItemSong>;
	var showArchiveSongs:Bool;
}

typedef ItemWeek = {
	var name:String;
	var image:String;
	var display:String;
	var title:String;
	var categories:Array<SongCategoryData>;
	var songs:Array<String>;
	var keyLock:String;
	var hiddenOnWeeks:Bool;
	var hiddenOnFreeplay:Bool;
	var colorFreeplay:String;
}
typedef ItemSong = {
	var song:String;
	var categories:Array<SongCategoryData>;
	var keyLock:String;
	var hidden:Bool;
	var color:String;
}

typedef SongCategoryData = {
	var category:String;
	var difficults:Array<String>;
}

typedef SongPlayer = {
	var alive:Bool;
	var strum:Int;
}

class Song {
	public static function setPlayersByChart(song:SwagSong):Void {
		states.PlayState.strum_players = [{alive: true, strum: song.single_player}];
	}

	public static function fileSong(song:String, cat:String, diff:String):String {
		var daSong:String = Paths.getFileName(song, true);

		daSong += '-' + Paths.getFileName(cat, true);
		daSong += '-' + Paths.getFileName(diff, true);

		return daSong;
	}

	public static function loadFromJson(songFormat:String):SwagSong {
		if(songFormat == null){songFormat = "Test-Normal-Normal";}

		var rawJson:String = Paths.chart(songFormat).getText().trim();
		var rawEvents:String = Paths.chart_events(songFormat).getText().trim();

		while(!rawJson.endsWith("}")){rawJson = rawJson.substr(0, rawJson.length - 1);}
		while(!rawEvents.endsWith("}")){rawEvents = rawEvents.substr(0, rawEvents.length - 1);}
		
		var toReturn:SwagSong = convert_song(songFormat, rawJson);
		var toEvents:SwagEvent = convert_events(rawEvents);

		parseJSONshit(toReturn, toEvents);
		return toReturn;
	}

	public static function parseJSONshit(swagShit:SwagSong, ?swagEvents:SwagEvent):Void {
		if(swagShit.song == null){swagShit.song = "PlaceHolder";}
		if(swagShit.category == null){swagShit.category = "Default";}
		if(swagShit.difficulty == null){swagShit.difficulty = "Normal";}

		if(swagShit.bpm <= 0){swagShit.bpm = 100;}
		if(swagShit.speed <= 0){swagShit.speed = 3.0;}
		
		if(swagShit.uiStyle == null){swagShit.uiStyle = "Default";}
		if(swagShit.stage == null){swagShit.stage = "Stage";}
		
		if(swagShit.characters == null){
			swagShit.characters = [
				["Girlfriend", [540,50], 1, false, "Default", "GF", 0],
				["Daddy_Dearest", [100, 100], 1, true, "Default", "OPP", 0],
				["Boyfriend", [770, 100], 1, false, "Default", "BF", 0]
			];
		}

		if(swagShit.sectionStrums == null){swagShit.sectionStrums = [];}
		if(swagShit.sectionStrums.length <= 0){swagShit.sectionStrums.push({isPlayable: true,noteStyle:"Default", keys:4, charToSing:[], notes:[]});}
		if(swagShit.generalSection == null){swagShit.generalSection = [];}

		while(swagShit.generalSection.length < swagShit.sectionStrums[0].notes.length){swagShit.generalSection.push({bpm: swagShit.bpm, changeBPM: false, lengthInSteps: 16, strumToFocus: 0, charToFocus: 0});}
		
		if(swagShit.sectionStrums == null){
			swagShit.sectionStrums = [{isPlayable:true, noteStyle:swagShit.uiStyle, keys:4, charToSing:[], notes:[]}];
		}else{
			for(strum in swagShit.sectionStrums){
				if(strum.charToSing == null){strum.charToSing = [];}
				if(strum.keys <= 0){strum.keys = 4;}
				if(strum.noteStyle == null){strum.noteStyle = "Default";}
				if(strum.notes == null){
					strum.notes = [];
				}else{
					for(sec in strum.notes){
						if(sec.charToSing == null){sec.charToSing = [];}
						if(sec.sectionNotes == null){
							sec.sectionNotes = [];
						}else{
							for(n in sec.sectionNotes){
								Note.set_note(n, Note.convNoteData(Note.getNoteData(n)));
							}
						}
					}
				}
			}
		}

		for(gen in swagShit.generalSection){
			if(gen.lengthInSteps <= 0){gen.lengthInSteps = 16;}
		}

		if(swagShit.events == null){swagShit.events = [];}
		if(swagEvents != null){
			for(e in swagEvents.events){
				var event_data = Note.getEventData(e);
				event_data.isExternal = true;

				Note.set_note(e, Note.convEventData(event_data));

				var has_note:Bool = false;
				for(ee in swagShit.events){
					if(Note.compNotes(event_data, Note.getEventData(ee), false)){
						has_note = true;
						break;
					}
				}
				if(has_note){continue;}
				swagShit.events.push(e);
			}
		}
		
		swagShit.validScore = true;
	}

	public static function convert_events(rawEvents:String):SwagEvent {
		var _global_events:Dynamic = cast Json.parse(rawEvents);

		if(_global_events.song == null){_global_events.song = { events: [] };}

		var song_events:SwagEvent = _global_events.song;

		if(song_events.events == null){song_events.events = [];}

		return song_events;
	}
	public static function convert_song(json_name:String, rawSong:String):SwagSong {
		var _global_song:Dynamic = cast Json.parse(rawSong);
		if(_global_song.song == null){_global_song.song = {};}

		var s_name:String = json_name.split("-")[0] != null ? json_name.split("-")[0] : "Test";
		var s_category:String = json_name.split("-")[1] != null ? json_name.split("-")[1] : "Normal";
		var s_difficulty:String = json_name.split("-")[2] != null ? json_name.split("-")[2] : "Normal";

		var song_data:Dynamic = _global_song.song;

		//Adding General Values
		if(song_data.validScore == null){song_data.validScore = false;}

		if(song_data.song == null){song_data.song = s_name;}
		if(song_data.category == null){song_data.category = s_category;}
		if(song_data.difficulty == null){song_data.difficulty = s_difficulty;}
		
		if(song_data.single_player == null){song_data.single_player = 1;}

		if(song_data.bpm == null){song_data.bpm = 100;}
		if(song_data.speed == null){song_data.speed = 1;}
		if(song_data.stage == null){song_data.stage = "Stage";}
		
		if(song_data.uiStyle == null){song_data.uiStyle = "Default";}
		
		if(song_data.hasVoices == null){song_data.hasVoices = song_data.needsVoices != null ? song_data.needsVoices : true;}
		
		if(song_data.characters == null){
			song_data.characters = [
				["Girlfriend", [540,50], 1, false, "Default", "GF", 0],
				["Daddy_Dearest", [100, 100], 1, true, "Default", "OPP", 0],
				["Boyfriend", [770, 100], 1, false, "Default", "BF", 0]
			];

			if(song_data.gfVersion != null){song_data.characters[0][0] = song_data.gfVersion; song_data.gfVersion = null;}
			else if(song_data.player3 != null){song_data.characters[0][0] = song_data.player3; song_data.player3 = null;}
			else if(song_data.gf != null){song_data.characters[0][0] = song_data.gf; song_data.gf = null;}

			if(song_data.player2 != null){song_data.characters[1][0] = song_data.player2; song_data.player2 = null;}
			if(song_data.player1 != null){song_data.characters[2][0] = song_data.player1; song_data.player1 = null;}
		}

		if(song_data.sectionStrums == null){
			song_data.sectionStrums = [
				{isPlayable: true, noteStyle: "Default", keys: 4, charToSing: [1], notes: []},
				{isPlayable: true, noteStyle: "Default", keys: 4, charToSing: [2], notes: []}
			];

			if(song_data.notes != null){
				for(sec in cast(song_data.notes,Array<Dynamic>)){
					var opp_section:SwagSection = {charToSing: [], changeSing: false, altAnim: sec.altAnim, sectionNotes: []};
					var bf_section:SwagSection = {charToSing: [], changeSing: false, altAnim: sec.altAnim, sectionNotes: []};

					for(n in cast(sec.sectionNotes,Array<Dynamic>)){
						if(sec.mustHitSection){
							if(n[1] < 4){
								bf_section.sectionNotes.push(n);
							}else if(n[1] > 3){
								n[1] = n[1] % 4;
								opp_section.sectionNotes.push(n);
							}
						}else{
							if(n[1] < 4){
								opp_section.sectionNotes.push(n);
							}else if(n[1] > 3){
								n[1] = n[1] % 4;
								bf_section.sectionNotes.push(n);
							}
						}
					}

					song_data.sectionStrums[0].notes.push(opp_section);
					song_data.sectionStrums[1].notes.push(bf_section);
				}
			}
		}

		if(song_data.generalSection == null){
			song_data.generalSection = [];

			if(song_data.notes != null){
				for(sec in cast(song_data.notes,Array<Dynamic>)){
					song_data.generalSection.push({
						bpm: sec.bpm != null ? sec.bpm : song_data.bpm,
						changeBPM: sec.changeBPM != null ? sec.changeBPM : false,
						lengthInSteps: 16,
						strumToFocus: sec.mustHitSection ? 1 : 0,
						charToFocus: 0
					});
				}
			}
		}

		if(song_data.notes != null){song_data.notes = null;}
		
		if(song_data.events == null){song_data.events = [];}

		return song_data;
	}

	public static var song_file:SaverMaster = null;
	public static function save_song(fileName:String, songData:SwagSong, options:{?onComplete:Void->Void, ?throwFunc:Exception->Void, ?returnOnThrow:Bool, ?path:String, ?saveAs:Bool}):Void {
		if(song_file != null || songData == null){return;}

		var _song:SwagSong = songData;

		parseJSONshit(_song);
		var _global_events:SwagEvent = {events: []};
		var init_events:Array<Dynamic> = _song.events.copy();

		var cur_ev:Int = 0;
		while(cur_ev < _song.events.length){
			var ev = _song.events[cur_ev];
			var ev_data:EventData = Note.getEventData(ev);
			if(!ev_data.isExternal){cur_ev++; continue;}
			_global_events.events.push(ev);
			if(!ev_data.isBroken){_song.events.remove(ev); cur_ev--;}
			cur_ev++;
		}

		var song_data:String = "";
		var events_data:String = "";

		try{song_data = Json.stringify({song: _song},"\t");}catch(e){trace(e); if(options.throwFunc != null){options.throwFunc(e);} if(options.returnOnThrow){return;}}
		try{events_data = Json.stringify({song: _global_events},"\t");}catch(e){trace(e); if(options.throwFunc != null){options.throwFunc(e);} if(options.returnOnThrow){return;}}

		if(options.saveAs){
			var files_to_save:Array<{name:String, data:Dynamic}> = [{name: '$fileName.json', data: song_data}];
			if(events_data.length > 0){files_to_save.push({name: 'global_events.json', data: events_data});}
			song_file = new SaverMaster(files_to_save, {destroyOnComplete: true, onComplete: function(){if(options.onComplete != null){options.onComplete();} song_file = null;}});
			song_file.saveFile();
		}else{
			#if sys
				if((song_data != null) && (song_data.length > 0)){File.saveContent(options.path, song_data);}
				if((events_data != null) && (events_data.length > 0)){File.saveContent(options.path.replace('$fileName','global_events'), events_data);}
				if(options.onComplete != null){options.onComplete();}
			#end
		}

		_song.events = init_events;
	}
}

class SongStuffManager {
	public static function hasCatAndDiff(song:Dynamic, category:String, dificulty:String):Bool {
		var cats:Array<SongCategoryData> = song.categories;
		for(c in cats){
			if(c.category != category){continue;}
			for(d in c.difficults){
				if(d != dificulty){continue;}
				return true;
			}
		}
		return false;
	}

	public static function addCategoryToItemSong(category:SongCategoryData, itemSong:ItemSong):Void {
		for(cat in itemSong.categories){
			if(cat.category == category.category){
				for(diff in category.difficults){
					if(cat.difficults.contains(diff)){continue;}
					cat.difficults.push(diff);
				}
			}
			return;
		}
		itemSong.categories.push(category);
	}
	public static function addSongToSongList(itemSong:ItemSong, SongList:Array<ItemSong>):Void {
		for(item in SongList){if(item.song == itemSong.song){for(cat in itemSong.categories){addCategoryToItemSong(cat, item);} return;}}
		SongList.push(itemSong);
	}

	public static function getSongList():Array<ItemSong> {
		var SongList:Array<ItemSong> = [];

		var modlist:Array<String> = Paths.readFile('assets/data/weeks.json');
		if(ModSupport.hideVanillaSongs){modlist.shift();}

		for(_mod in modlist){
			var modData:SongsData = cast _mod.getJson();

			for(week in modData.weekData){
				var cats:Array<SongCategoryData> = week.categories;
				var lock:String = week.keyLock;
				var color:String = week.colorFreeplay;

				for(song in week.songs){
					var songItem:ItemSong = {
						song: song,
						categories: cats,
						keyLock: lock,
						color: color,
						hidden: week.hiddenOnFreeplay
					};
					addSongToSongList(songItem, SongList);
				}
			}

			for(song in modData.freeplayData){
				var cats:Array<SongCategoryData> = song.categories;
				var lock:String = song.keyLock;
				var color:String = song.color;
					
				var songItem:ItemSong = {
					song: song.song,
					categories: cats,
					keyLock: lock,
					color: color,
					hidden: song.hidden
				};
				addSongToSongList(songItem, SongList);
			}

			#if sys
			if(modData.showArchiveSongs){
				var songsDirectory:String = _mod;
				songsDirectory = songsDirectory.replace('weeks.json', 'songs');

				for(song in FileSystem.readDirectory(songsDirectory)){
					if(!FileSystem.isDirectory('${songsDirectory}/${song}') || FileSystem.readDirectory('${songsDirectory}/${song}').length <= 0){continue;}

					var data:Array<SongCategoryData> = [];
					for(chart in FileSystem.readDirectory('${songsDirectory}/${song}')){
						if(chart == "global_events.json"){continue;}
						if(chart.contains("_dialog.json")){continue;}
						if(!chart.contains(".json")){continue;}

						var cStats:Array<String> = chart.replace(".json", "").split("-");
						if(cStats.length < 3){continue;}

						if(cStats[1] == null){cStats[1] = "Normal";}
						if(cStats[2] == null){cStats[2] = "Normal";}
						
						var has_cat:Bool = false;
						for(d in data){
							if(d.category != cStats[1]){continue;}
							d.difficults.push(cStats[2]);
							has_cat = true; break;
						}
						if(!has_cat){data.push({category:cStats[1], difficults:[cStats[2]]});}
					}
					
					if(data.length <= 0){continue;}
					
					var songItem:ItemSong = {
						song: song,
						categories: data,
						keyLock: null,
						color: "#fffd75",
						hidden: false
					};
					addSongToSongList(songItem, SongList);
				}
			}
			#end
		}

		return SongList;
	}

	public static function getWeekList(showLocked:Bool = false):Array<ItemWeek> {
		var WeekList:Array<ItemWeek> = [];

		var modlist:Array<String> = Paths.readFile('assets/data/weeks.json');
		if(ModSupport.hideVanillaWeeks){modlist.shift();}

		for(_mod in modlist){
			var modData:SongsData = cast _mod.getJson();
			for(week in modData.weekData){
				if(showLocked && Highscore.checkLock(week.keyLock, true)){continue;}
				WeekList.push(week);
			}
		}

		return WeekList;
	}

	public static function getWeek(name:String):ItemWeek {
		var week_list:Array<ItemWeek> = getWeekList();
		for(w in week_list){
			if(w.name != name){continue;}
			return w;
		}
		return null;
	}
}

class SaverMaster extends FileReference {
	public var stuff_to_save:Array<{name:String, data:Dynamic}> = [];
	public var current_calls:Array<{event:Dynamic,func:Dynamic}> = [];
	public var options:Dynamic = {};

	public function new(?_stuff_to_save:Array<{name:String, data:Dynamic}>, ?options:Dynamic):Void {
		if(_stuff_to_save != null){this.stuff_to_save = _stuff_to_save;}
		if(options != null){this.options = cast options;}
		super();
	}

	public function saveFile(?_):Void {
		if(_ == null){
			this.addEventListener(Event.SELECT, saveFile);
			this.addEventListener(Event.COMPLETE, completedFiles);
			this.addEventListener(Event.CANCEL, saveFile);
			this.addEventListener(IOErrorEvent.IO_ERROR, saveFile);
		}

		if(stuff_to_save.length <= 0){completedFiles(); return;}
		var current_file:{name:String, data:Dynamic} = stuff_to_save.shift();
		this.save(current_file.data, current_file.name);
	}

	public function completedFiles(?_){
		if(options.onComplete != null){options.onComplete();}
		if(options.destroyOnComplete){removeListeners();}
	}

	private function removeListeners(){
		this.removeEventListener(Event.SELECT, saveFile);
		this.removeEventListener(Event.COMPLETE, completedFiles);
		this.removeEventListener(Event.CANCEL, saveFile);
		this.removeEventListener(IOErrorEvent.IO_ERROR, saveFile);
	}
}