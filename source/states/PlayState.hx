package states;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.editors.tiled.TiledMap;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.atlas.FlxAtlas;
import hxcodec.flixel.FlxVideoSprite;
import substates.MusicBeatSubstate;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import flixel.sound.FlxSoundGroup;
import flixel.util.FlxStringUtil;
import flixel.util.FlxCollision;
import openfl.display.BlendMode;
import hxcodec.flixel.FlxVideo;
import substates.PauseSubState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.sound.FlxSound;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import states.GitarooPause;
import flixel.math.FlxRect;
import flixel.util.FlxSort;
import flixel.text.FlxText;
import flixel.FlxSubState;
import lime.utils.Assets;
import sys.thread.Thread;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.ui.FlxBar;
import flixel.FlxState;
import flixel.FlxBasic;
import flixel.FlxGame;
import flixel.FlxG;
import haxe.Timer;
import haxe.Json;

import StrumLine;
import Note.Note;
import DialogueBox;
import Song.SwagSong;
import Song.ItemWeek;
import Song.ItemSong;
import Note.StrumNote;
import Note.EventData;
import Song.SongPlayer;
import Song.SwagSection;
import Script.Script_Calls;
import Song.SongStuffManager;

#if desktop
import Discord.DiscordClient;
#end

using SavedFiles;
using StringTools;

class PlayState extends MusicBeatState {
	public static var SONG:SwagSong = null;
	public static var isDuel:Bool = false;
	public static var total_plays:Int = 0;
	public static var isStoryMode:Bool = false;
	public static var strum_players:Array<SongPlayer> = null;

    public var curSection(get, never):Int;
	inline function get_curSection():Int{return Std.int(conductor.getCurStep() / 16);}

	//Audio
	public var inst:FlxSound;
	public var voices:FlxSoundGroup;

	//Strumlines
	public var strumsGroup:FlxTypedGroup<StrumLine>;
	public var strumLeftPos:Float = 100;
	public var strumMiddlePos:Float = FlxG.width / 2;
	public var strumRightPos:Float = FlxG.width - 100;

	//Song Stats
	public var song_Length:Float = 0;
	public var song_Time:Float = 0;
	
	//PreSettings Variables
	public var pre_DefaultNonPos:String = PreSettings.getPreSetting("Default Strum Position", "Visual Settings");
	public var pre_TypeMiddle:String = PreSettings.getPreSetting("Type Middle Scroll", "Visual Settings");
	public var pre_BumpingCamera:Bool = PreSettings.getPreSetting("Bumping Camera", "Visual Settings");
	public var pre_TypeScroll:String = PreSettings.getPreSetting("Type Scroll", "Visual Settings");
	public var pre_OnlyNotes:Bool = PreSettings.getPreSetting("Only Notes", "Graphic Settings");

	//Gameplay Style
	public var uiStyleCheck:String = 'Default';

	private static var prevCamFollow:FlxObject;
	
	// Gameplay Bools
	public var default_bumps:Bool = true;
	public var followChar:Bool = true;
	public var moveStrums:Bool = true;
	public var defaultZoom:Float = 1;
	public var zoomMult:Float = 1;
	public var iconMult:Float = 1;

	//Other
	public var songGenerated:Bool = false;
	public var songStarted:Bool = false;
	public var songPlaying:Bool = false;
	public var onGameOver:Bool = false;
	public var canPause:Bool = false;
	public var isPaused:Bool = false;
	public var canReset:Bool = true;

	public function goToStart(){
		conductor.songPosition = -(conductor.crochet * (introAssets.length + 1));
		songPlaying = true;
		changeStrumPositions();

		startCountdown(startSong);
	}
	public function goToEnd(){
		if(SongListData.songPlaylist.length <= 0){
			FlxG.sound.playMusic(Paths.music('freakyMenu').getSound());

			if(states.PlayState.isDuel){states.MusicBeatState.switchState("states.FreeplayState", [null, "states.MainMenuState", function(_song){MusicBeatState.switchState("states.PlayerSelectorState", [_song, null, "states.MainMenuState"]);}]);}
			else if(states.PlayState.isStoryMode){states.MusicBeatState.switchState("states.StoryMenuState", [null, "states.MainMenuState"]);}
			else{states.MusicBeatState.switchState("states.FreeplayState", [null, "states.MainMenuState"]);}
		}else{	
			SongListData.playSong();
		}
	};
	
	public static var introAssets:Array<{asset:String, sound:String}> = [{asset:null, sound: 'intro3'}, {asset:'ready', sound: 'intro2'}, {asset:'set', sound: 'intro1'}, {asset:'go', sound: 'introGo'}];
	public function startCountdown(onComplete:Void->Void = null):Void {
		var swagCounter:Int = 0;
		timers.push(new FlxTimer().start(conductor.crochet / 1000, function(tmr:FlxTimer){
			if(introAssets[swagCounter] != null){
				if(introAssets[swagCounter].sound != null){FlxG.sound.play(Paths.styleSound(introAssets[swagCounter].sound, uiStyleCheck).getSound(), 0.6);}
			
				if(introAssets[swagCounter].asset != null){
					var iAssets:FlxSprite = new FlxSprite().loadGraphic(Paths.styleImage(introAssets[swagCounter].asset, uiStyleCheck).getGraphic());
					iAssets.scrollFactor.set();
					iAssets.updateHitbox();
					iAssets.screenCenter();
					add(iAssets);

					FlxTween.tween(iAssets, {y: iAssets.y += 100, alpha: 0}, conductor.crochet / 1000, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween){iAssets.kill();}});
				}
			}

			if(swagCounter == introAssets.length){if(onComplete != null){onComplete();}}

			swagCounter++;
		}, introAssets.length + 1));
	}

	public var timers:Array<FlxTimer> = [];
	public var tweens:Array<FlxTween> = [];
	
	public var stage:Stage;

    public var camFollow:FlxObject;

	override public function create(){
		super.create();
		total_plays++;
		
		FlxG.mouse.visible = false;
		
		persistentUpdate = true;
		persistentDraw = true;

		StrumLine.GLOBAL_VARIABLES = {};

		if(SongListData.songPlaylist.length > 0){
			SONG = SongListData.songPlaylist[0];
		}else{
			SONG = Song.loadFromJson('Tutorial-Normal-Normal');
		}
		
		uiStyleCheck = SONG.uiStyle;

		if(!pre_OnlyNotes){
			stage = new Stage(SONG.stage, SONG.characters);
			add(stage);
		
			defaultZoom = stage.zoom;
			FlxG.camera.zoom = stage.zoom;
		}

		conductor.songPosition = -5000;

		strumsGroup = new FlxTypedGroup<StrumLine>();
		strumsGroup.cameras = [camHUD];
		add(strumsGroup);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;
			
        camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.screenCenter();
		if (prevCamFollow != null){
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		add(camFollow);

		if(strum_players == null){Song.setPlayersByChart(SONG);}
		for(s in strum_players){s.alive = true;}

		generateSong();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Playing " + SONG.song, null);
		MagicStuff.setWindowTitle("Playing " + SONG.song);
		#end
	}

	private var loadedStrums:Int = 0;
	private function generateSong():Void {
		var songData = SONG;

		conductor.changeBPM(songData.bpm);
		conductor.mapBPMChanges(songData);

		//Loading Instrumental
		inst = new FlxSound().loadEmbedded(Paths.inst(songData.song, songData.category).getSound(), false, false, endSong);
		inst.looped = false;
		inst.onComplete = endSong.bind();
		FlxG.sound.list.add(inst);
		
		song_Length = inst.length;

		//Loading Voices
		voices = new FlxSoundGroup();		
		voices.sounds = [];

		if(songData.hasVoices){
            for(i in 0...songData.sectionStrums.length){
				if(songData.sectionStrums[i].charToSing.length <= 0){continue;}
				if(songData.characters.length <= songData.sectionStrums[i].charToSing[0]){continue;}
				var voice_path:String = Paths.voice(i, songData.characters[songData.sectionStrums[i].charToSing[0]][0], songData.song, songData.category);
				if(!Paths.exists(voice_path)){continue;}
				var voice = new FlxSound().loadEmbedded(voice_path.getSound());
				FlxG.sound.list.add(voice);
				voices.add(voice);
            }
        }
		
		if(voices.sounds.length <= 0){
			var voice = new FlxSound();
			FlxG.sound.list.add(voice);
			voices.add(voice);
		}

		//Loading Strumlines
		for(i in 0...songData.sectionStrums.length){
			var strumLine = new StrumLine(0, 0, songData.sectionStrums[i].keys, Std.int(FlxG.width / 3) - 40, principal_controls, null, songData.sectionStrums[i].noteStyle);
			
			strumLine.onHIT = function(note:Note){
				if(songData.sectionStrums[i].isPlayable){
					if(PreSettings.getPreSetting("Mute on Miss", "Game Settings")){
						if(SONG.hasVoices){
							if(voices.sounds[i] != null){
								voices.sounds[i].volume = 1;
							}else{
								voices.sounds[0].volume = 1;
							}
						}
					}
				}

				if(stage == null){return;}
				var focus:Bool = false;
				
				var song_animation:String = note.singAnimation;
				if(strumLine.swagStrum.notes[strumLine.curSection] != null && strumLine.swagStrum.notes[strumLine.curSection].altAnim){song_animation += '-alt';}

				for(ii in strumLine.getToSing(note)){
					var new_character:Character = stage.getCharacterById(ii);
					if(new_character == null){continue;}
					if(new_character.curAnim == song_animation && note.typeHit == "Hold" || note.typeHit != "Hold"){new_character.singAnim(song_animation, true);}

					if(!focus){
						if(songData.sectionStrums[i].isPlayable){
							if(strumLine.typeStrum == "Playing"){StrumLine.GLOBAL_VARIABLES.Player = new_character;}
							else{StrumLine.GLOBAL_VARIABLES.Enemy = new_character;}
						}
						strumLine.LOCAL_VARIABLES.Player = new_character;
						focus = true;
					}
				}
			};

			strumLine.onMISS = function(note:Note){
				if(songData.sectionStrums[i].isPlayable){
					if(PreSettings.getPreSetting("Mute on Miss", "Game Settings")){
						if(SONG.hasVoices){
							if(voices.sounds[i] != null){
								voices.sounds[i].volume = 0;
							}else{
								voices.sounds[0].volume = 0;
							}
						}
					}
				}

				if(stage == null){return;}
				var focus:Bool = false;
				
				var song_animation:String = '${note.singAnimation}miss';
				if(strumLine.swagStrum.notes[strumLine.curSection] != null && strumLine.swagStrum.notes[strumLine.curSection].altAnim){song_animation += '-alt';}

				for(ii in strumLine.getToSing(note)){
					var new_character:Character = stage.getCharacterById(ii);
					if(new_character == null){continue;}
					new_character.playAnim(song_animation, true);

					if(!focus){
						if(songData.sectionStrums[i].isPlayable){
							if(strumLine.typeStrum == "Playing"){StrumLine.GLOBAL_VARIABLES.Player = new_character;}
							else{StrumLine.GLOBAL_VARIABLES.Enemy = new_character;}
						}
						strumLine.LOCAL_VARIABLES.Player = new_character;
						focus = true;
					}
				}

				for(i in 0...stage.character_Length){
					var cur_character:Character = stage.getCharacterById(i);
					if(cur_character.curType != "Girlfriend"){continue;}
					cur_character.playAnim('sad', true);
				}
			};

			strumLine.ui_style = uiStyleCheck;

			strumLine.scrollSpeed = songData.speed;
			strumLine.strumConductor = conductor;
			strumLine.bpm = songData.bpm;
			
			strumLine.alpha = 0;
			strumLine.x = (FlxG.width / 2) - (strumLine.genWidth / 2);
			strumLine.y = pre_TypeScroll == "DownScroll" ? FlxG.height - strumLine.genHeight - 30 : 30;

			strumLine.alpha = 0;

			strumLine.loadStrumNotes(songData.sectionStrums[i]);
			strumLine.ID = i;

			strumsGroup.add(strumLine);
		}

		for(i in 0...strum_players.length){
			var player_strum:Int = strum_players[i].strum;
			var cur_strum:StrumLine = strumsGroup.members[player_strum];

			if(cur_strum == null){continue;}

			if(strum_players.length > 1){
				cur_strum.controls = PlayerSettings.getPlayer(i).controls;
				cur_strum.load_solo_ui();
				cur_strum.onGAME_OVER = function(){
					cur_strum.LOCAL_VARIABLES.set("GameOver", true);
					strum_players[i].alive = false;
					cur_strum.changeTypeStrum("BotPlay");

					var canGAMEOVER:Bool = true;
					for(sp in strum_players){if(sp.alive){canGAMEOVER = false;}}
					if(canGAMEOVER){doGameOver(player_strum);}
				}
			}else{
				cur_strum.load_global_ui();
				cur_strum.onGAME_OVER = function(){doGameOver(player_strum);}
			}
		}

		for(s in scripts){s.exFunction('preload');}

		songGenerated = true;

		var contEnd:Bool = false;
		for(s in scripts){
			if(s.getFunction("startSong") == null){continue;}

			switch(cast(s.exFunction("startSong", []), Script.Script_Calls)){
				case Stop_And_Break: { contEnd = true; break; }
				case Stop: { contEnd = true; }
				case Break: { break; }
				case null: {}
				default: {}
			}
		}
		if(!contEnd){goToStart();}
	}
	
	var previousFrameTime:Int = 0;
	function startSong():Void{	
		previousFrameTime = FlxG.game.ticks;
		
		conductor.songPosition = 0;

		inst.play(true);
		for(sound in voices.sounds){sound.play(true);}
		
		for(s_player in strum_players){strumsGroup.members[s_player.strum].changeTypeStrum("Playing");}
				
		canPause = true;
		resyncVocals();

		songStarted = true;
	}

	public var last_conductor:Float = -10000;
	function resyncVocals():Void{
		if(!songPlaying){return;}

		for(sound in voices.sounds){sound.pause();}
	
		inst.play();
		conductor.songPosition = inst.time;
		for(sound in voices.sounds){
			sound.time = conductor.songPosition;
			sound.play();
		}

		if(conductor.songPosition < last_conductor){endSong();}
		last_conductor = conductor.songPosition;
	}

	override public function update(elapsed:Float){
		super.update(elapsed);

		if(FlxG.keys.justPressed.T){trace('${conductor.songPosition} [${inst.time}] / ${inst.length}');}

		checkEvents();

		if(canControlle && songPlaying){
			if(principal_controls.checkAction("Pause_Game", JUST_PRESSED) && canPause){
				for(s_player in strum_players){if(!s_player.alive){continue;} strumsGroup.members[s_player.strum].changeTypeStrum("Nothing");}
				pauseAndOpen(
					"substates.PauseSubState",
					[
						function(){
							if(!songGenerated){isPaused = false; pauseSong(false); return;}
							startCountdown(function(){
								for(s_player in strum_players){if(!s_player.alive){continue;} strumsGroup.members[s_player.strum].changeTypeStrum("Playing");}
								persistentUpdate = false;
								persistentDraw = true;
								canControlle = true;
								isPaused = false;
								pauseSong(false);
							});
						}
					],
					true
				);
			}

			if(FlxG.keys.justPressed.SEVEN){
				persistentUpdate = false;
				inst.destroy();
				for(s in voices.sounds){s.destroy();}
				VoidState.clearAssets = false;
				states.editors.ChartEditorState._song = SONG;
				MusicBeatState.switchState("states.editors.ChartEditorState", []);
			}
			
			if(FlxG.keys.justPressed.R && canReset){doGameOver(strum_players[0].strum);}
		}

		if(songPlaying){			
			// conductor.songPosition = inst.time;
			conductor.songPosition += FlxG.elapsed * 1000;
	
			if(!isPaused){
				song_Time += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;
	
				// Interpolation type beat
				if(conductor.lastSongPos != conductor.songPosition){
					song_Time = (song_Time + conductor.songPosition) / 2;
					conductor.lastSongPos = conductor.songPosition;
					// conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}	
			// conductor.lastSongPos = inst.time;
		}						
		
		if(!pre_OnlyNotes){		
			if(followChar){Character.setCameraToCharacter(stage.getCharacterById(Character.getFocusCharID(SONG, curSection)), camFollow, stage);}
		}

		if(pre_BumpingCamera && default_bumps){
			for(s in strumsGroup){
				if(s.leftIcon != null){
					s.leftIcon.scale.x = FlxMath.lerp(s.leftIcon.scale.x, s.leftIcon.default_scale.x, FlxG.elapsed * 3.125);
					s.leftIcon.scale.y = FlxMath.lerp(s.leftIcon.scale.y, s.leftIcon.default_scale.y, FlxG.elapsed * 3.125);
				}
				if(s.rightIcon != null){
					s.rightIcon.scale.x = FlxMath.lerp(s.rightIcon.scale.x, s.rightIcon.default_scale.x, FlxG.elapsed * 3.125);
					s.rightIcon.scale.y = FlxMath.lerp(s.rightIcon.scale.y, s.rightIcon.default_scale.x, FlxG.elapsed * 3.125);
				}
			}

			FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, defaultZoom, FlxG.elapsed * 3.125);
			camHUD.zoom = FlxMath.lerp(camHUD.zoom, 1, FlxG.elapsed * 3.125);
		}
	}

	public var exEvents:Array<Dynamic> = [];
	function checkEvents(){
		if(!songGenerated || PlayState.SONG.events == null || PlayState.SONG.events.length <= 0){return;}
		var sEvents:Array<Dynamic> = SONG.events;
		for(event in sEvents.copy()){
			var cur_Event:EventData = Note.getEventData(event);
			if(conductor.songPosition > cur_Event.strumTime && !cur_Event.isBroken && !exEvents.contains(event)){
				exEvents.push(event);
				for(e in cur_Event.eventData.copy()){
					if(e.length < 2){continue;}
					var _args = cast(e[1],Array<Dynamic>).copy();
					var _srp = Script.getScript(e[0]);
					if(_srp == null){trace('Null Event [${e[0]}]'); continue;}
					_srp.exFunction("execute", cast _args);
				}
			}
		}
	}

	var songEnded:Bool = false;
	function endSong():Void {
		if(songEnded){return;}
		songEnded = true;

		trace("End Song");

		canPause = false;
		isPaused = true;
		songPlaying = false;
		moveStrums = false;

		inst.stop();
		for(sound in voices.sounds){sound.stop();}

		var song_score:Int = 0;
		for(s_player in strum_players){song_score += strumsGroup.members[s_player.strum].STATS.Score;}

		if(SONG.validScore){Highscore.saveSongScore(Paths.getFileName(SONG.song, true), song_score, SONG.difficulty, SONG.category);}

		SongListData.nextSong(song_score);

		if(SONG.validScore && SongListData.songPlaylist.length <= 0){
			NGio.unlockMedal(60961);
			Highscore.saveWeekScore(SongListData.weekName, SongListData.campScore, SONG.difficulty, SONG.category);
		}
		
		if(SongListData.songPlaylist.length <= 0){
			inst.destroy();
			for(s in voices.sounds){s.destroy();}
			
			SongListData.resetVariables();
		}else{
			prevCamFollow = camFollow;
		}

		var contEnd:Bool = false;
		for(s in scripts){
			if(s.getFunction("endSong") == null){continue;}
			switch(cast(s.exFunction("endSong", []), Script.Script_Calls)){
				case Stop_And_Break:{ contEnd = true; break; }
				case Stop: { contEnd = true; }
				case Break: { break; }
				case null: {}
				default: {}
			}
		}
		if(!contEnd){goToEnd();}
	}

	public function pauseSong(pause:Bool = true){
		songPlaying = !pause;

		if(!songPlaying){
			if(inst != null){
				inst.pause();
				for(sound in voices.sounds){sound.pause();}
			}
			for(timer in timers){if(timer != null){timer.active = false;}}
			for(tween in tweens){if(tween != null){tween.active = false;}}
		}else{
			if(songGenerated && inst != null){resyncVocals();}	
			for(timer in timers){if(timer != null){timer.active = true;}}
			for(tween in tweens){if(tween != null){tween.active = true;}}
		}
		
		for(s in scripts){s.exFunction('song_paused', [pause]);}
	}

	public function pauseAndOpen(substate:String, args:Array<Dynamic>, hasEasterEgg:Bool = false, per_update:Bool = false, per_draw:Bool = true){
		if(isPaused){return;}
		persistentUpdate = per_update;
		persistentDraw = per_draw;
		isPaused = true;

		pauseSong();

		// 1 / 1000 chance for Gitaroo Man easter egg
		if(hasEasterEgg && FlxG.random.bool(0.1)){
			trace('GITAROO MAN EASTER EGG');
			MusicBeatState.switchState("states.GitarooPause", []);
		}else{
			canControlle = false;
			loadSubState(substate, args);
		}
	}

	function doGameOver(_player:Int):Void {
		onGameOver = true;
		camHUD.visible = false;
		camFHUD.visible = false;
		
		var chars:Array<Character> = [];
		var char:Array<Int> = SONG.sectionStrums[_player].charToSing;
		if(SONG.sectionStrums[_player].notes[curSection].changeSing){char = SONG.sectionStrums[_player].notes[curSection].charToSing;}
		for(i in char){chars.push(stage.getCharacterById(i)); stage.getCharacterById(i).visible = false;}

		pauseAndOpen("substates.GameOverSubstate", [chars, uiStyleCheck], false, false);
	}

	override public function onFocusLost():Void {
		super.onFocusLost();

		if(!songStarted || !canPause){return;}

		pauseAndOpen(
			"substates.PauseSubState",
			[
				function(){
					startCountdown(function(){
						persistentUpdate = false;
						persistentDraw = true;
						canControlle = true;
						isPaused = false;
						pauseSong(false);
					});
				}
			],
			true
		);
	}

	override function stepHit(){
		super.stepHit();
		
		if(songPlaying && inst.time > conductor.songPosition + 20 || inst.time < conductor.songPosition - 20){resyncVocals();}
		
		//trace('${inst.time} / ${inst.length}');
	}

	override function beatHit(){
		super.beatHit();

		if(pre_BumpingCamera && default_bumps){
			if(curBeat % 2 == 0){
				// Beat Icons
				for(s in strumsGroup){
					if(s.leftIcon != null){
						s.leftIcon.scale.x += 0.1 * iconMult;
						s.leftIcon.scale.y += 0.1 * iconMult;
					}
					if(s.rightIcon != null){
						s.rightIcon.scale.x += 0.1 * iconMult;
						s.rightIcon.scale.y += 0.1 * iconMult;
					}
				}
			}

			if(curBeat % 4 == 0){
				// Beat Cameras
				FlxG.camera.zoom += 0.015 * zoomMult;
				camHUD.zoom += 0.03 * zoomMult;
			}
		}

		if(SONG.generalSection[curSection] != null){
			if(SONG.generalSection[curSection].changeBPM){
				conductor.changeBPM(SONG.generalSection[curSection].bpm);
				FlxG.log.add('CHANGED BPM!');
				trace('Changed BPM');
			}
		}
	}

	var current_strums:Array<StrumLine> = [];
	function changeStrumPositions():Void {
		if(!moveStrums){return;}

		var startLeft:Float = strumLeftPos;
		var startRight:Float = strumRightPos;

		var cur_strums:Array<StrumLine> = [null, null, null];

		var id_strums:Array<Int> = [];
		for(s_player in strum_players){id_strums.push(s_player.strum);}
		for(i in 0...strumsGroup.length){if(id_strums.contains(i)){continue;} if(!SONG.sectionStrums[i].isPlayable){continue;} id_strums.push(i);}

		var set_side = function(id:Int, strum:StrumLine, force:Bool = false){
			if(cur_strums[id] == null || force){cur_strums[id] = strum;}
			else if(cur_strums[0] == null){cur_strums[0] = strum;}
			else if(cur_strums[1] == null){cur_strums[1] = strum;}
			else if(cur_strums[2] == null){cur_strums[2] = strum;}
		};

		for(i in id_strums){
			var isPlayer:Bool = false; for(s in strum_players){if(i == s.strum){isPlayer = true;}}

			var cur_strum:StrumLine = strumsGroup.members[i];
			if(cur_strum == null){continue;}
			var strum_character:Character = pre_OnlyNotes ? null : stage.getCharacterById(Character.getFocusCharID(SONG, curSection, i));
			
			if(isPlayer && pre_TypeMiddle != "None"){
				set_side(1, cur_strum);
				continue;
			}
			if(strum_character == null){
				var def_strum:Int = 0;
				switch(pre_DefaultNonPos){
					case "Middle":{def_strum = 1;}
					case "Right":{def_strum = 2;}
					case "Left":{def_strum = 0;}
				}

				set_side(def_strum, cur_strum);
				continue;
			}
			set_side(strum_character.onRight ? 0 : 2, cur_strum);
		}

		if(pre_TypeMiddle == "None"){
			cur_strums.sort(function(a,b){
				if(a == null || b == null){return 0;}
				var a_char:Character = pre_OnlyNotes ? null : stage.getCharacterById(Character.getFocusCharID(SONG, curSection, a.ID));
				var b_char:Character = pre_OnlyNotes ? null : stage.getCharacterById(Character.getFocusCharID(SONG, curSection, b.ID));
				if(a_char == null || b_char == null){return 0;}
				else if(a_char.x < b_char.x){return -1;}
				else if(a_char.x > b_char.x){return 1;}
				else{return 0;}
			});
		}
		
		if(current_strums == cur_strums){return;}

		if(cur_strums[1] != null){
			startLeft -= 50;
			startRight += 50;
		}

		for(s in strumsGroup){
			var isPlayer:Bool = false; for(ss in strum_players){if(s.ID == ss.strum){isPlayer = true;}}
			var new_alpha:Float = 1;
			var new_x:Float = 0;

			if(!isPlayer){
				switch(pre_TypeMiddle){
					case "OnlyPlayer":{new_alpha = 0;}
					case "FadeOthers":{new_alpha = 0.5;}
				}
			}
			
			if(!cur_strums.contains(s)){
				new_alpha = 0;
			}else{
				var cur_index:Int = cur_strums.indexOf(s);
				if(current_strums[cur_index] == cur_strums[cur_index]){continue;}
				switch(cur_index){
					case 0:{new_x = startLeft;}
					case 1:{new_x = strumMiddlePos - (s.genWidth / 2);}
					case 2:{new_x = startRight - s.genWidth;}
				}
			}

			FlxTween.tween(s, {alpha: new_alpha}, (conductor.crochet / 1000), {ease: FlxEase.quadInOut});
			FlxTween.tween(s, {x: new_x}, (conductor.crochet / 1000), {ease: FlxEase.quadInOut});
		}

		current_strums = cur_strums;
	}
}

class SongListData {
	public static var onNext:Void->Void;
	public static var onFinish:Void->Void;

	public static var weekName:String = "PlaceHolderWeek";
	public static var weekDisplay:String = "PlaceHolderWeek";

	public static var songPlaylist:Array<SwagSong> = [];

	public static var campScore:Int = 0;

	public static function loadSong(song:ItemSong, category:String = "Normal", difficulty:String = "Normal"):Void {
		if(!SongStuffManager.hasCatAndDiff(song, category, difficulty)){return;}
		
		weekName = "Freeplay";
		weekDisplay = "Freeplay";

		trace(Song.fileSong(song.song, category, difficulty));
		var songToPlay:SwagSong = Song.loadFromJson(Song.fileSong(song.song, category, difficulty));
		songPlaylist.push(songToPlay);
	}
	public static function loadWeek(week:ItemWeek, category:String = "Normal", difficulty:String = "Normal"):Void {
		if(!SongStuffManager.hasCatAndDiff(week, category, difficulty)){return;}
		
		weekName = week.name;
		weekDisplay = week.display;

		for(song in week.songs){
			trace(Song.fileSong(song, category, difficulty));
			var songToPlay:SwagSong = Song.loadFromJson(Song.fileSong(song, category, difficulty));
			songPlaylist.push(songToPlay);
		}
	}

	public static function addSongs(songList:Array<SwagSong>){for(song in songList){songPlaylist.push(song);}}
	public static function addSong(song:SwagSong){songPlaylist.push(song);}

	public static function playSong(_isStoryMode:Bool = true):Void {
		PlayState.isStoryMode = _isStoryMode;
		MusicBeatState.loadState("states.PlayState", [], [[{type:"SONG", instance:songPlaylist[0]}], false]);
	}

	public static function loadAndPlaySong(SONG:SwagSong, _isStoryMode:Bool = false):Void {
		PlayState.isStoryMode = _isStoryMode;

		resetVariables();
		songPlaylist.push(SONG);

		MusicBeatState.loadState("states.PlayState", [], [[{type:"SONG", instance:SONG}], false]);
	}
	
	public static function nextSong(score){
		PlayState.strum_players = null;
		PlayState.total_plays = 0;

		campScore += score;
		songPlaylist.shift();
	}

	public static function resetVariables(){
		PlayState.strum_players = null;
		PlayState.total_plays = 0;

		songPlaylist = [];
		campScore = 0;
	}
}