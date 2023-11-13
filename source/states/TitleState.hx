package states;

import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.display.FlxGridOverlay;
import flixel.input.gamepad.FlxGamepad;
import flixel.system.ui.FlxSoundTray;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxGradient;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.math.FlxRandom;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import lime.app.Application;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import io.newgrounds.NG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxState;
import openfl.Assets;
import flixel.FlxG;
import haxe.Timer;

#if (desktop && sys)
import Discord.DiscordClient;
import sys.thread.Thread;
import sys.FileSystem;
import sys.io.File;
#end

using SavedFiles;
using StringTools;

class TitleState extends MusicBeatState {
	var otherStuff:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	var inIntro:Bool = true;
	var toStart:Bool = true;

	var logo:FlxSprite;
	var gradient:FlxSprite;
	var current_text:Alphabet;

	var cur_text:Int = 0;
	var intro_list:Array<Dynamic> = [];

	var press_title:Alphabet;

	public function new(started:Bool = true){
		super();

		this.toStart = started;
	}

	override public function create():Void {
		FlxG.mouse.visible = false;

		intro_list = LangSupport.getText('intro_list');
		otherStuff.add(new FlxSprite());

		gradient = FlxGradient.createGradientFlxSprite(FlxG.width, Std.int(FlxG.height / 2), [0x00000000, 0xFF23FFB6]);
		gradient.color = FlxColor.fromRGB(0, 255, 195);
		gradient.setPosition(0,FlxG.height + 10);
		gradient.screenCenter(X);
		add(gradient);
		
		current_text = new Alphabet(0, 0, []);
		add(current_text);

		logo = new FlxSprite().loadGraphic(Paths.image('LOGO').getGraphic());
		logo.y = (FlxG.height / 2) - (logo.height / 2);
		logo.cameras = [camFGame];
		logo.screenCenter(X);
		logo.visible = false;
		add(logo);

		press_title = new Alphabet(0,0, LangSupport.getText('intro_start'));
		press_title.y = FlxG.height + 10; press_title.screenCenter(X);
		press_title.cameras = [camFGame];
		add(press_title);

		super.create();

		if(toStart){new FlxTimer().start(1, function(tmr:FlxTimer){if(inIntro){startIntro();}});}
	}

	override function update(elapsed:Float){
		if(FlxG.sound.music != null){conductor.songPosition = FlxG.sound.music.time;}

		super.update(elapsed);

		if(logo != null){logo.scale.set(FlxMath.lerp(logo.scale.x, 1, 0.1), FlxMath.lerp(logo.scale.y, 1, 0.1));}

		if(canControlle){
			if(FlxG.keys.justPressed.T){cur_text--;}
			if(FlxG.keys.justPressed.G){cur_text++;}

			if(principal_controls.checkAction("Menu_Accept", JUST_PRESSED)){
				if(inIntro){
					skipIntro(true);
				}else{
					canControlle = false;
					FlxG.sound.play(Paths.sound("confirmMenu").getSound());
					camHUD.flash(FlxColor.WHITE, conductor.crochet / 4000, null, true);
					FlxTween.tween(gradient, {y: FlxG.height}, 1, {ease: FlxEase.quadIn});
					FlxTween.tween(press_title, {y: FlxG.height + 20}, 2, {ease: FlxEase.elasticOut});
					FlxTween.tween(logo, {y: FlxG.height}, 1, {ease: FlxEase.quadIn, onComplete: function(twn){MusicBeatState.switchState("states.MainMenuState", []);}});
				}
			}
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
	}
	
	private function changeAlpha(?new_data:Array<Dynamic>):Void {
		if(new_data == null){new_data = [];}
		current_text.cur_data = new_data;
		current_text.loadText();
		current_text.screenCenter();
	}

	private function startIntro():Void {
		FlxG.sound.playMusic(Paths.music('freakyMenu').getSound());
		conductor.changeBPM(115);
	}
	
	private function skipIntro(forced:Bool = false):Void {
		if(FlxG.sound.music == null){return;}
		inIntro = false;

		if(forced){FlxG.sound.music.time = 47000;}

		camHUD.flash(FlxColor.WHITE, conductor.crochet / 4000, null, true);
		changeAlpha();
		gradient.y = FlxG.height - gradient.height;
		logo.visible = true;
		Timer.delay(function(){FlxTween.tween(press_title, {y: FlxG.height - press_title.height - 10}, 1, {ease: FlxEase.elasticOut});}, Std.int(conductor.crochet));
	}

	override function beatHit(){
		super.beatHit();

		logo.scale.set(1.2, 1.2);

		if(!toStart){toStart = true; skipIntro();}

		if(inIntro){
			switch(curBeat){
				case 4:{changeAlpha(LangSupport.getText('intro_1'));}
				case 7:{changeAlpha();}
				case 8:{changeAlpha(LangSupport.getText('intro_2'));}
				case 11:{changeAlpha();}
				case 12:{changeAlpha(LangSupport.getText('intro_3'));}
				case 15:{changeAlpha();}
				case 16:{changeAlpha(LangSupport.getText('intro_4'));}
				case 19:{changeAlpha();}
				case 20:{changeAlpha([intro_list[FlxG.random.int(0,intro_list.length-1)]]);}
				case 23:{changeAlpha();}
				case 24:{FlxTween.tween(gradient, {y: FlxG.height - gradient.height}, (conductor.crochet / 1000) * 6, {ease: FlxEase.quadInOut}); changeAlpha([intro_list[FlxG.random.int(0,intro_list.length-1)]]);}
				case 27:{changeAlpha();}
				case 28:{changeAlpha(LangSupport.getText('intro_5'));}
				case 29:{changeAlpha(LangSupport.getText('intro_6'));}
				case 30:{changeAlpha(LangSupport.getText('intro_7'));}
				case 31:{changeAlpha(LangSupport.getText('intro_8'));}
				case 32:{skipIntro();}
			}

			//if(cur_text < 0){cur_text = 0;}
			//if(cur_text >= intro_list.length){cur_text = intro_list.length - 1;}
			//changeAlpha([intro_list[cur_text]]);
		}else{
			var sSize:Int = FlxG.random.int(20, 80);
			var square:FlxSprite = otherStuff.recycle(FlxSprite);
			square.setPosition(FlxG.random.float(0, FlxG.width) + 20, FlxG.height + 10);
			square.makeGraphic(sSize, sSize, FlxColor.fromRGB(0, 255, 195));
			FlxTween.tween(square, {x: FlxG.random.float(square.x - 10, square.x), y: FlxG.random.float(0, FlxG.height / 2), alpha: 0}, FlxG.random.float(1, 3));
			add(square);
		}
	}
}
