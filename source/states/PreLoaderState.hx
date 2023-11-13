package states;

import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.display.FlxGridOverlay;
import flixel.input.gamepad.FlxGamepad;
import flixel.system.ui.FlxSoundTray;
import flixel.addons.ui.FlxUIState;
import flixel.graphics.FlxGraphic;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import io.newgrounds.NG;
import flixel.FlxSprite;
import flixel.FlxState;
import openfl.Assets;
import flixel.FlxG;
import haxe.Timer;

#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
import sys.FileSystem;
import sys.io.File;
#end

import substates.CustomScriptSubState;
import substates.InformationSubState;
import substates.MusicBeatSubstate;
import substates.GameOverSubstate;
import substates.OptionsSubState;
import substates.PauseSubState;
import substates.FadeSubState;

import states.editors.CharacterEditorState;
import states.editors.PackerEditorState;
import states.editors.StageEditorState;
import states.editors.StageTesterState;
import states.editors.ChartEditorState;
import states.editors.SpriteTestState;
import states.editors.XMLEditorState;
import states.PlayerSelectorState;
import states.CustomScriptState;
import states.MusicBeatState;
import states.SkinsMenuState;
import states.StoryMenuState;
import states.FreeplayState;
import states.MainMenuState;
import states.GitarooPause;
import states.LoadingState;
import states.ModListState;
import states.PopLangState;
import states.CreditsState;
import states.PopModState;
import states.TitleState;
import states.PlayState;
import states.VoidState;

import Note.NoteSplash;
import Character.Skins;

using StringTools;

class PreLoaderState extends FlxUIState {
	override public function create():Void {
		SavedFiles.clearMemoryAssets();
		SavedFiles.clearUnusedAssets();
		
		FlxG.autoPause = false;

		NGio.noLogin(APIStuff.API);

		#if ng
		var ng:NGio = new NGio(APIStuff.API, APIStuff.EncKey);
		trace('NEWGROUNDS LOL');
		#end

		super.create();

		FlxG.save.bind('funkin', 'Yirius125');

		Controls.init();
		PreSettings.init();
		
        PreSettings.loadSettings();
		
		PlayerSettings.init();

		Highscore.load();	
		LangSupport.init();
		ModSupport.init();
		Skins.init();
		
		#if desktop
		DiscordClient.initialize();
		Application.current.onExit.add(function(exitCode){DiscordClient.shutdown();});

            #if !switch
                NGio.unlockMedal(60960);

                // If it's Friday according to da clock
                if(Date.now().getDay() == 5){NGio.unlockMedal(61034);}
			#end
		#end

		if(!FlxG.save.data.inLang){
			MusicBeatState.switchState("states.PopLangState", [ModSupport.is_same() ? "states.TitleState" : "states.PopModState"]);
			return;
		}
		if(!ModSupport.is_same()){
			MusicBeatState.switchState("states.PopModState", ["states.TitleState"]);
			return;
		}
		
		MagicStuff.reload_data();
		MusicBeatState.loadState("states.TitleState", [], []);
	}
}
