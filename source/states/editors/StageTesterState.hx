package states.editors;

import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIAssets;
import flixel.addons.ui.FlxUIButton;
import openfl.filters.ShaderFilter;
import flixel.sound.FlxSoundGroup;
import flixel.addons.ui.FlxUIGroup;
import openfl.events.IOErrorEvent;
import flixel.util.FlxStringUtil;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxArrayUtil;
import openfl.net.FileReference;
import flixel.addons.ui.FlxUI;
import flixel.sound.FlxSound;
import openfl.utils.ByteArray;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flash.geom.Rectangle;
import flixel.text.FlxText;
import openfl.events.Event;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import openfl.media.Sound;
import lime.ui.FileDialog;
import haxe.DynamicAccess;
import lime.utils.Assets;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxState;
import haxe.xml.Access;
import flixel.FlxG;
import haxe.Json;

import Song.SaverMaster;
import Character.AnimArray;
import Character.CharacterFile;
import FlxCustom.FlxCustomShader;
import FlxCustom.FlxCustomButton;
import FlxCustom.FlxUICustomList;
import FlxCustom.FlxUICustomButton;
import FlxCustom.FlxUICustomNumericStepper;

#if desktop
import Discord.DiscordClient;
import sys.FileSystem;
import sys.io.File;
#end

using SavedFiles;
using StringTools;

class StageTesterState extends MusicBeatState {    
    public var stage:Stage;

    var MENU:FlxUITabMenu;

    var camera_sprite:FlxSprite;

    var arrayFocus:Array<FlxUIInputText> = [];

    var camFollow:FlxObject;

    override function create(){
        if(FlxG.sound.music != null){FlxG.sound.music.stop();}

        #if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence('Editing Stage', '[Stage Editor]');
		MagicStuff.setWindowTitle('Editing...', 1);
		#end
        
        FlxG.mouse.visible = true;
        
        var bgGrid:FlxSprite = FlxGridOverlay.create(10, 10, FlxG.width, FlxG.height, true, 0xff4d4d4d, 0xff333333);
        bgGrid.cameras = [camGame];
        add(bgGrid);

        stage = new Stage("Stage", []);
        stage.showCamPoints = true;
        stage.is_debug = true;
        stage.cameras = [camFGame];
        add(stage);
        
        for(char in stage.characterData){char.alpha = 0.5;}
        
        var menuTabs = [
            {name: "1Stage", label: 'Stage'},
        ];
        MENU = new FlxUITabMenu(null, menuTabs, true);
        MENU.resize(250, Std.int(FlxG.height));
		MENU.x = FlxG.width - MENU.width;
        MENU.camera = camHUD;
        addMENUTABS();
        add(MENU);

        camera_sprite = new FlxSprite().loadGraphic(Paths.image("camera_border").getGraphic());
        camera_sprite.scrollFactor.set(0,0);
        camera_sprite.cameras = [camFGame];
        camera_sprite.antialiasing = false;
        camera_sprite.alpha = 0.5;
        add(camera_sprite);
        
        super.create();
        
		camFollow = new FlxObject(0, 0, 1, 1);
        camFollow.screenCenter();
        camFGame.follow(camFollow, LOCKON);
		add(camFollow);
    }

    var pos = [[], []];
    override function update(elapsed:Float){
        var pMouse = FlxG.mouse.getPositionInCameraView(camFGame);

        var arrayControlle = true;
        for(item in arrayFocus){if(item.hasFocus){arrayControlle = false;}}

        if(canControlle && arrayControlle){    
            if(FlxG.mouse.justPressedRight){pos = [[camFollow.x, camFollow.y],[pMouse.x, pMouse.y]];}
            if(FlxG.mouse.pressedRight){camFollow.setPosition(pos[0][0] + ((pos[1][0] - pMouse.x) * 1.0), pos[0][1] + ((pos[1][1] - pMouse.y) * 1.0));}

            if(FlxG.keys.pressed.SHIFT){
                if(FlxG.mouse.justPressedMiddle){camFGame.zoom = stage.zoom;}
                if(FlxG.mouse.wheel != 0){camFGame.zoom += (FlxG.mouse.wheel * 0.1);}
            }else{
                if(FlxG.mouse.justPressedMiddle){camFollow.screenCenter();}
                if(FlxG.mouse.wheel != 0){camFGame.zoom += (FlxG.mouse.wheel * 0.01);}
            }
        }
        
        super.update(elapsed);
    
    }

    var txtStage:FlxUIInputText;
    private function addMENUTABS(){
        var tabMENU = new FlxUI(null, MENU);
        tabMENU.name = "1Stage";

        var lblStage = new FlxText(5, 15, 0, "STAGE:", 8); tabMENU.add(lblStage);
        txtStage = new FlxUIInputText(lblStage.x + lblStage.width + 5, lblStage.y, Std.int(MENU.width - lblStage.width - 20), 'Stage', 8); tabMENU.add(txtStage);
        arrayFocus.push(txtStage);
        txtStage.name = "STAGE_NAME";

        var btnLoad:FlxButton = new FlxCustomButton(5, lblStage.y + lblStage.height + 5, Std.int((MENU.width) - 10), null, "Load Stage", null, null, function(){
            stage.loadStage(txtStage.text); Paths.stage(txtStage.text).unsaveFile();
            camera_sprite.scale.x = camera_sprite.scale.y = camHUD.zoom / stage.zoom;
            camera_sprite.screenCenter();
        }); tabMENU.add(btnLoad);

        ////////////////////////////////////////////////////////////
        MENU.addGroup(tabMENU);
        ////////////////////////////////////////////////////////////

        MENU.showTabId("1Stage");
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>){
        if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)){
            var input:FlxUIInputText = cast sender;
            var wname = input.name;
        }else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)){
            var nums:FlxUINumericStepper = cast sender;
            var wname = nums.name;
        }else if(id == FlxUICheckBox.CLICK_EVENT){
            var check:FlxUICheckBox = cast sender;
            var wname = check.name;
        }
    }
}