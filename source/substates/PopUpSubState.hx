package substates;

import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import states.PlayState.SongListData;
import flixel.addons.ui.FlxUITabMenu;
import flixel.input.keyboard.FlxKey;
import flixel.addons.ui.FlxUI;
import flixel.tweens.FlxTween;
import flixel.sound.FlxSound;
import states.MusicBeatState;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.FlxSubState;
import haxe.DynamicAccess;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxG;

import FlxCustom.FlxUICustomNumericStepper;
import FlxCustom.FlxUICustomButton;
import FlxCustom.FlxUICustomList;
import FlxCustom.FlxCustomButton;

class PopUpSubState extends MusicBeatSubstate {
	public var onYes:Void->Void = function(){};
    
    public var MENU:FlxUITabMenu;

    public function new(information:String, onYes:Void->Void, onClose:Void->Void){
		this.onYes = onYes;
        super(onClose);
		curCamera.bgColor.alpha = 200;

        MENU = new FlxUITabMenu(null, [], true);
        MENU.cameras = [curCamera];
        MENU.resize(400, 100);
        addMENUTABS(information);
        add(MENU);
	}

	override function create() {
		super.create();
		
		FlxG.mouse.visible = true;
	}

	public function doClose(){
		canControlle = false;
        curCamera.alpha = 0;
        close();
	}

	function addMENUTABS(info:String):Void {
        var tabMENU = new FlxUI(null, MENU);
        tabMENU.name = "Selected";
        MENU.addGroup(tabMENU);

        var lblInformation = new FlxText(0, 25, MENU.width, info, 24); tabMENU.add(lblInformation);
        lblInformation.alignment = CENTER;
        
        MENU.resize(400, 25 + lblInformation.height + 75);
        MENU.screenCenter();

        var btnYes:FlxButton = new FlxCustomButton(0, 0, 150, null, "Yes", null, FlxColor.GREEN, function(){onYes(); doClose();});
        var btnNo:FlxButton = new FlxCustomButton(0, 0, 150, null, "No", null, FlxColor.RED, function(){doClose();});
        btnYes.setPosition(MENU.width - btnYes.width - 25, MENU.height - btnYes.height - 25);
        btnNo.setPosition(25, MENU.height - btnYes.height - 25);
        tabMENU.add(btnYes); tabMENU.add(btnNo);
        btnYes.label.color = FlxColor.WHITE;
        btnNo.label.color = FlxColor.WHITE;

        MENU.showTabId("Selected");
	}
}
