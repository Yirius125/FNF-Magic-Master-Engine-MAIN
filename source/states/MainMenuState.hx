package states;

import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import states.editors.CharacterEditorState;
import flixel.addons.text.FlxTypeText;
import states.editors.XMLEditorState;
import flixel.addons.ui.FlxUIButton;
import flixel.input.mouse.FlxMouse;
import flixel.effects.FlxFlicker;
import flixel.util.FlxGradient;
import flixel.util.FlxGradient;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import lime.app.Application;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.FlxSubState;
import flixel.FlxObject;
import flixel.FlxSprite;
import io.newgrounds.NG;
import flixel.FlxCamera;
import flixel.FlxG;

import FlxCustom.FlxCustomButton;
import FlxCustom.FlxUICustomList;
import FlxCustom.FlxUICustomButton;
import FlxCustom.FlxUICustomNumericStepper;

import Song.SwagSong;

#if desktop
import Discord.DiscordClient;
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class MainMenuState extends MusicBeatState {
	public static var principal_options:Array<Dynamic> = [
		{option:"StoryMode", icon:"storymode", display:"menu_storymode", func:function(){MusicBeatState.switchState(new StoryMenuState(null, MainMenuState));}},
		{option:"Freeplay", icon:"freeplay", display:"menu_freeplay", func:function(){MusicBeatState.switchState(new FreeplayState(null, MainMenuState));}},
		//{option:"Multiplayer", icon:"multiplayer", display:"menu_multiplayer", func:function(){MusicBeatState.switchState(new states.multiplayer.LobbyState());}},
		{option:"Skins", icon:"skins", display:"menu_skins", func:function(){MusicBeatState.switchState(new SkinsMenuState(null, MainMenuState));}},
		{option:"Options", icon:"options", display:"menu_options", func:function(){MusicBeatState.state.canControlle = false; MusicBeatState.state.openSubState(new substates.OptionsSubState(function(){MusicBeatState.state.canControlle = true;}));}},
		{option:"Mods", icon:"mods", display:"menu_mods", func:function(){if(ModSupport.MODS.length > 0){MusicBeatState.switchState(new ModListState(MainMenuState, null));}}},
		{option:"Credits", icon:"credits", display:"menu_credits", func:function(){MusicBeatState.switchState(new CreditsState(null, MainMenuState));}}
	];
	public static var secondary_options:Array<Dynamic> = [
		{option:"Chart", icon:"chart_editor", display:"menu_chart_editor", func:function(){MusicBeatState.switchState(new states.editors.ChartEditorState(null, MainMenuState));}},
		{option:"Character", icon:"character_editor", display:"menu_character_editor", func:function(){states.editors.CharacterEditorState.editCharacter(null, MainMenuState);}},
		//{option:"Stages", icon:"stage_editor", display:"menu_stage_editor", func:function(){MusicBeatState.switchState(new states.editors.StageEditorState(null, MainMenuState));}},
		{option:"XML", icon:"xml_editor", display:"menu_xml_editor", func:function(){states.editors.XMLEditorState.editXML(null, MainMenuState);}}
	];

	public static var curSelected:Int = 0;

	var optionGroup:FlxTypedGroup<FlxSprite>;
	var curAlphabet:Alphabet;
    var grpArrows:FlxTypedGroup<FlxSprite>;

	override function create(){		
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;
		persistentUpdate = persistentDraw = true;

		FlxG.mouse.visible = true;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		MagicStuff.setWindowTitle('In the Menus');
		#end

		if(FlxG.sound.music == null || (FlxG.sound.music != null && !FlxG.sound.music.playing)){FlxG.sound.playMusic(Paths.music('freakyMenu'));}

		var bg = new FlxSprite().loadGraphic(Paths.image('menuBG'));
		bg.setGraphicSize(FlxG.width, FlxG.height);
        bg.color = 0xff7ddeff;
		bg.screenCenter();
		add(bg);

		optionGroup = new FlxTypedGroup<FlxSprite>();
		add(optionGroup);

		for(i in 0...principal_options.length){
			var o:Dynamic = principal_options[i];
			var _opt:FlxSprite = new FlxSprite();
						
			_opt.frames = Paths.getAtlas(Paths.image('main_menu/options/icon_${o.icon}', null, true));
			_opt.animation.addByPrefix('idle', 'Idle', 30, false);
			_opt.animation.addByPrefix('over', 'Over', 30, false);
			_opt.animation.addByPrefix('selected', 'Hit', 30, false);
			_opt.y = (FlxG.height / 2) - (_opt.height / 2);

			optionGroup.add(_opt);
		}
		
        //Adding Arrows
        grpArrows = new FlxTypedGroup<FlxSprite>();
        for(i in 0...2){
            var arrow_1:FlxSprite = new FlxSprite();
            arrow_1.frames = Paths.getAtlas(Paths.image('arrows', null, true));
            arrow_1.animation.addByPrefix('idle', 'Arrow Idle');
            arrow_1.animation.addByPrefix('over', 'Arrow Over', false);
            arrow_1.animation.addByPrefix('hit', 'Arrow Hit', false);
            arrow_1.scale.set(0.3, 0.3);
            arrow_1.updateHitbox();
            
            switch(i){
                case 1:{arrow_1.flipX = true;}
            }

            grpArrows.add(arrow_1);
            arrow_1.ID = i;
        }
        add(grpArrows);

		curAlphabet = new Alphabet(0, FlxG.height + 100, [{animated:true, bold:true, scale:0.5, text:"PlaceHolder"}]);
		curAlphabet.screenCenter(X);
		add(curAlphabet);
		
		var front_ui:FlxSprite = new FlxSprite().loadGraphic(Paths.image("main_menu/UI_Front"));
		front_ui.setGraphicSize(Std.int(FlxG.width*1.1), FlxG.height);
		front_ui.screenCenter();
		add(front_ui);

		var lastWidth:Float = 5;
		for(i in 0...secondary_options.length){
			var o:Dynamic = secondary_options[i];
			
			var _opt:FlxButton = new FlxCustomButton(lastWidth, FlxG.height - 75, 80, 70, "", [Paths.getAtlas(Paths.image('main_menu/options/icon_${o.icon}', null, true)), [["normal", "Idle"], ["highlight", "Over"], ["pressed", "Hit"]]], null, o.func);
			_opt.antialiasing = true;
			_opt.ID = i;
			add(_opt);

			lastWidth += _opt.width + 5;
		}

		changeSelection();
		
		super.create();
	}

	override function update(elapsed:Float){
		if(FlxG.sound.music.volume < 0.8){FlxG.sound.music.volume += 0.5 * FlxG.elapsed;}
		conductor.songPosition = FlxG.sound.music.time;

		MagicStuff.sortMembersByX(cast optionGroup, (FlxG.width / 2) - (optionGroup.members[curSelected].width / 2), curSelected, 200);
		curAlphabet.y = FlxMath.lerp(curAlphabet.y, 500, 0.1);

		for(a in grpArrows.members){MagicStuff.lerpY(cast a, FlxG.height / 2);}
		grpArrows.members[0].x = (FlxG.width / 2) - (optionGroup.members[curSelected].width / 2) - grpArrows.members[0].width - 50;
		grpArrows.members[1].x = (FlxG.width / 2) + (optionGroup.members[curSelected].width / 2) + 50;

		if(canControlle){
			if(FlxG.keys.justPressed.ONE){MusicBeatState.switchState(new states.editors.StageEditorState(null, MainMenuState));}

			if(principal_controls.checkAction("Menu_Left", JUST_PRESSED)){changeSelection(-1);}
			if(principal_controls.checkAction("Menu_Right", JUST_PRESSED)){changeSelection(1);}
			if(principal_controls.checkAction("Menu_Accept", JUST_PRESSED)){chooseSelection();}		
		}
		
		super.update(elapsed);		
	}

	function chooseSelection():Void {
		optionGroup.members[curSelected].animation.play("selected");

		if(principal_options[curSelected].func != null){principal_options[curSelected].func();}
	}

	function changeSelection(value:Int = 0, force:Bool = false):Void {
		if(value < 0){grpArrows.members[0].animation.play("hit");}
		if(value > 0){grpArrows.members[1].animation.play("hit");}

		curSelected += value; if(force){curSelected = value;}

		if(curSelected < 0){curSelected = optionGroup.members.length - 1;}
		if(curSelected >= optionGroup.members.length){curSelected = 0;}

		for(opt in optionGroup){opt.animation.play("idle");}
		optionGroup.members[curSelected].animation.play("over");
		
		curAlphabet.cur_data = LangSupport.getText(principal_options[curSelected].display);
		curAlphabet.loadText();

		curAlphabet.screenCenter(X);
		curAlphabet.y = FlxG.height + 100;
	}
}
