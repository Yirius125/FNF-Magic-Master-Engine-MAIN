package substates;

import states.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import haxe.DynamicAccess;
import flixel.FlxObject;

import states.PlayState.SongListData;

class InformationSubState extends MusicBeatSubstate {
    public var _cam_follow:FlxObject;

    public var lblInfo:Alphabet;

	public function new(information:Array<Dynamic>, onClose:Void->Void){
		super(onClose);
		curCamera.bgColor.alpha = 200;
		curCamera.alpha = 0;

        lblInfo = new Alphabet(0,0,information);
        lblInfo.cameras = [curCamera];
        add(lblInfo);

        _cam_follow = new FlxObject(0, 0, 1, 1);
        _cam_follow.screenCenter();
		curCamera.follow(_cam_follow, LOCKON);

		FlxTween.tween(curCamera, {alpha: 1}, 1, {onComplete: function(twn){canControlle = true;}});
	}

	override function update(elapsed:Float){
		super.update(elapsed);

        if(canControlle){
            _cam_follow.y -= FlxG.mouse.wheel * 15;
			
			if(principal_controls.checkAction("Menu_Back", JUST_PRESSED)){doClose();}
        }

        if(_cam_follow.y >= lblInfo.y + lblInfo.height - (FlxG.height/2)){_cam_follow.y = lblInfo.y + lblInfo.height - (FlxG.height/2);}
        if(_cam_follow.y <= (FlxG.height/2)){_cam_follow.y = (FlxG.height/2);}
	}

	override function destroy(){
		super.destroy();
	}

	public function doClose(){
		canControlle = false;
		FlxTween.tween(curCamera, {alpha: 0}, 1, {onComplete: function(twn){close();}});
	}
}
