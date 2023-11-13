package substates;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import states.PlayState;
import states.VoidState;
import flixel.FlxCamera;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import states.MusicBeatState;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;

using SavedFiles;

class GameOverSubstate extends MusicBeatSubstate {
    public var characters_created:Bool = false;

    public var cur_style_ui:String;

    public var death_characters:FlxTypedGroup<Character>;
    public var camFollow:FlxObject;

    public var cur_playstate:PlayState;

    public var otherCamera:FlxCamera;
    
	public function new(characters:Array<Character>, style_ui:String){
		cur_style_ui = style_ui;
        super();
        curCamera.bgColor.alpha = 0;

        otherCamera = new FlxCamera();
		FlxG.cameras.add(otherCamera);
        otherCamera.zoom = FlxG.camera.zoom;

        if((MusicBeatState.state is PlayState)){cur_playstate = cast MusicBeatState.state;}

        death_characters = new FlxTypedGroup<Character>();
        death_characters.cameras = [otherCamera];
        add(death_characters);

		for(i in 0...characters.length){
            var new_character = new Character(characters[i].x, characters[i].y, characters[i].curCharacter, characters[i].curAspect, characters[i].curType, true);
            new_character.turnLook(characters[i].onRight);
            new_character.playAnim('firstDeath', true);
            death_characters.add(new_character);
            new_character.noDance = true;
		}
        characters_created = true;

		FlxG.sound.play(Paths.styleSound('fnf_loss_sfx', cur_style_ui).getSound());
        curCamera.fade(FlxColor.BLACK, 2);

		conductor.changeBPM(100);

		camFollow = new FlxObject(characters[0].c.x + (characters[0].c.width / 2), characters[0].c.y + (characters[0].c.height / 2), 1, 1); add(camFollow);
        otherCamera.scroll = FlxG.camera.scroll; otherCamera.follow(camFollow, LOCKON, 0.04);
		FlxG.camera.follow(camFollow, LOCKON, 0.04);
	}

	override function update(elapsed:Float){
		super.update(elapsed);

        if(characters_created && !canControlle){
            if(death_characters.members.length > 0 && death_characters.members[0].c.animation.curAnim != null){
                if(death_characters.members[0].c.animation.curAnim.finished){
                    FlxG.sound.playMusic(Paths.styleMusic('gameOver', cur_style_ui).getSound());
                    for(char in death_characters){char.playAnim('deathLoop', true);}
                    if(cur_playstate != null){cur_playstate.stage.destroy();}
                    MusicBeatState.state.persistentUpdate = false;
                    MusicBeatState.state.persistentDraw = false;
                    characters_created = false;
                    canControlle = true;
                }
            }else{
                FlxG.sound.playMusic(Paths.styleMusic('gameOver', cur_style_ui).getSound());
                if(cur_playstate != null){cur_playstate.stage.destroy();}
                MusicBeatState.state.persistentUpdate = false;
                MusicBeatState.state.persistentDraw = false;
                characters_created = false;
                canControlle = true;
            }
        }

        if(canControlle){
            if(principal_controls.checkAction("Menu_Accept", JUST_PRESSED)){retrySong();}
            if(principal_controls.checkAction("Menu_Back", JUST_PRESSED)){exitSong();}
        }

		if(FlxG.sound.music.playing){conductor.songPosition = FlxG.sound.music.time;}
	}
    
	override function beatHit(){
		super.beatHit();

        if(canControlle){
            for(char in death_characters){char.playAnim('deathLoop', true);}
        }
	}

    function exitSong():Void {
        canControlle = false;
        FlxG.sound.music.stop();

        if(states.PlayState.isStoryMode){states.MusicBeatState.switchState("states.MainMenuState", []);}
        else{states.MusicBeatState.switchState("states.FreeplayState", [null, "states.MainMenuState"]);}
    }

    function retrySong():Void {
        canControlle = false;

        FlxG.sound.music.stop();
        FlxG.sound.play(Paths.styleMusic('gameOverEnd', cur_style_ui).getSound());

        for(char in death_characters){char.playAnim('deathConfirm', true);}

        new FlxTimer().start(0.7, function(tmr:FlxTimer){otherCamera.fade(FlxColor.BLACK, 2, false, function(){
			VoidState.clearAssets = false;
			SongListData.playSong(PlayState.isStoryMode);
        });});
    }

}