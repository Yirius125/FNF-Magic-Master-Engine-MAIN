package states.editors;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSoundGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxArrayUtil;
import flixel.math.FlxPoint;
import flixel.util.FlxStringUtil;
import lime.ui.FileDialog;

import Character.CharacterFile;
import Character.AnimArray;
import FlxCustom.FlxCustomButton;
import FlxCustom.FlxUINumericStepperCustom;
import FlxCustom.FlxUICustomList;

using StringTools;

class CharacterEditorState extends MusicBeatState{
    public static var _character:CharacterFile;
    var bfStage:Character;
    var healthIcon:HealthIcon;
    var cameraPointer:FlxSprite;

    var backStage:Stage;

    var MENU:FlxUITabMenu;
    var arrayFocus:Array<FlxUIInputText> = [];

    private var charPositions:Array<Dynamic> = [
        [100, 100],
        [400, 130],
        [770, 100]
    ];
	private var charPos(get, never):Array<Int>;
	inline function get_charPos():Array<Int>{
        if(chkGFPos.checked){return charPositions[1];}
        if(bfStage.onRight){return charPositions[0];}
        return charPositions[2];
    }
    
    var camFollow:FlxObject;

    public static function editCharacter(?onConfirm:FlxState, ?onBack:FlxState, ?character:CharacterFile){
        if(character == null){character = new Character(0, 0).charFile;}
        _character = character;

        FlxG.sound.music.stop();
        FlxG.switchState(new CharacterEditorState(onConfirm, onBack));
    }

    override function create(){
        FlxG.mouse.visible = true;

        backStage = new Stage("Stage", [["Girlfriend",charPositions[1],1,false,"Default","GF",0],["Fliqpy",charPositions[0],1,true,"Default","NORMAL",0],["Boyfriend",charPositions[2],1,false,"Default","NORMAL",0],["Boyfriend",charPositions[2],1,false,"Default","NORMAL",0]]);
        for(char in 0...backStage.character_Length){backStage.getCharacterById(char).alpha = 0.5;}
        backStage.cameras = [camFGame];
        add(backStage);
        
        bfStage = backStage.getCharacterById(3);
        bfStage.setupByCharacterFile(_character);
        bfStage.alpha = 1;

        var menuTabs = [
            {name: "1Character", label: 'Character'},
        ];
        MENU = new FlxUITabMenu(null, menuTabs, true);
        MENU.resize(300, Std.int(FlxG.height));
		MENU.x = FlxG.width - MENU.width;
        MENU.camera = camHUD;
        addMENUTABS();
        add(MENU);

        healthIcon = new HealthIcon(_character.healthicon, true);
        healthIcon.setPosition(MENU.x - healthIcon.width, 0);
        healthIcon.camera = camHUD;
        add(healthIcon);

        cameraPointer = new FlxSprite(bfStage.getGraphicMidpoint().x + _character.camera[0], bfStage.getGraphicMidpoint().y + _character.camera[1]).makeGraphic(5, 5);
        cameraPointer.camera = camFGame;
        add(cameraPointer);

		camFollow = new FlxObject(bfStage.getGraphicMidpoint().x, bfStage.getGraphicMidpoint().y, 1, 1);
        camFGame.follow(camFollow, LOCKON);
		add(camFollow);

        reloadCharacter();

        super.create();
    }

    var pos = [[], []];
    override function update(elapsed:Float){
        var pMouse = FlxG.mouse.getPositionInCameraView(camFGame);
        if(canControlle){    
            if(FlxG.mouse.justPressedRight){pos = [[camFollow.x, camFollow.y],[pMouse.x, pMouse.y]];}
            if(FlxG.mouse.pressedRight){camFollow.setPosition(pos[0][0] + ((pos[1][0] - pMouse.x) * 1.0), pos[0][1] + ((pos[1][1] - pMouse.y) * 1.0));}

            if(FlxG.keys.pressed.SHIFT){
                if(FlxG.mouse.wheel != 0){camFGame.zoom += (FlxG.mouse.wheel * 0.1);} 
            }else{
                if(FlxG.mouse.wheel != 0){camFGame.zoom += (FlxG.mouse.wheel * 0.01);}
            }

            if(FlxG.keys.justPressed.SPACE){bfStage.playAnim(false, clAnims.getSelectedLabel(), true);}
        }
        
        super.update(elapsed);
    
        cameraPointer.setPosition(bfStage.getGraphicMidpoint().x + _character.camera[0], bfStage.getGraphicMidpoint().y + _character.camera[1]);
    }

    public function reloadCharacter():Void{
        bfStage.setupByCharacterFile(_character);
        bfStage.turnLook(chkLEFT.checked);
        bfStage.setPosition(charPos[0] + bfStage.positionArray[0], charPos[1] + bfStage.positionArray[1]);
    }

    var chkLEFT:FlxUICheckBox;
    var chkGFPos:FlxUICheckBox;
    var lblOriPos:FlxText;
    var txtCharacter:FlxUIInputText;
    var txtSkin:FlxUIInputText;
    var txtCategory:FlxUIInputText;
    var txtImage:FlxUIInputText;
    var txtIcon:FlxUIInputText;
    var stpCharacterX:FlxUINumericStepper;
    var stpCharacterY:FlxUINumericStepper;
    var stpCameraX:FlxUINumericStepper;
    var stpCameraY:FlxUINumericStepper;
    var chkFlipImage:FlxUICheckBox;
    var chkAntialiasing:FlxUICheckBox;
    var chkDanceIdle:FlxUICheckBox;
    var clAnims:FlxUICustomList;
    var txtAnimName:FlxUIInputText;
    var txtAnimSymbol:FlxUIInputText;
    var txtAnimIndices:FlxUIInputText;
    var stpAnimFrameRate:FlxUINumericStepper;
    var chkAnimLoop:FlxUICheckBox;
    private function addMENUTABS(){
        var tabMENU = new FlxUI(null, MENU);
        tabMENU.name = "1Character";

        var lblCharacter = new FlxText(5, 15, 0, "CHARACTER:", 8); tabMENU.add(lblCharacter);
        txtCharacter = new FlxUIInputText(lblCharacter.x + lblCharacter.width + 5, lblCharacter.y, Std.int(MENU.width - lblCharacter.width - 15), bfStage.curCharacter, 8); tabMENU.add(txtCharacter);
        arrayFocus.push(txtCharacter);
        txtCharacter.name = "CHARACTER_NAME";

        var lblSkin = new FlxText(lblCharacter.x, txtCharacter.y + txtCharacter.height + 5, 0, "SKIN:", 8); tabMENU.add(lblSkin);
        txtSkin = new FlxUIInputText(lblSkin.x + lblSkin.width + 5, lblSkin.y, Std.int(MENU.width - lblSkin.width - 15), bfStage.curSkin, 8); tabMENU.add(txtSkin);
        arrayFocus.push(txtSkin);
        txtSkin.name = "CHARACTER_SKIN";
        
        var lblCat = new FlxText(lblCharacter.x, txtSkin.y + txtSkin.height + 5, 0, "ASPECT:", 8); tabMENU.add(lblCat);
        txtCategory = new FlxUIInputText(lblCat.x + lblCat.width + 5, lblCat.y, Std.int(MENU.width - lblCat.width - 15), bfStage.curCategory, 8); tabMENU.add(txtCategory);
        arrayFocus.push(txtCategory);
        txtCategory.name = "CHARACTER_CATEGORY";

        var btnLoadCharacter:FlxButton = new FlxCustomButton(lblCat.x, lblCat.y + lblCat.height + 5, Std.int(MENU.width / 2) - 10, null, "Load Character", null, function(){
            var newCharacter:Character = new Character(0, 0, txtCharacter.text, txtCategory.text); newCharacter.curSkin = txtSkin.text;
            newCharacter.setupByCharacterFile();

            bfStage.curCharacter = txtCharacter.text;
            bfStage.curCategory = txtCategory.text;
            bfStage.curSkin = txtSkin.text;

            CharacterEditorState.editCharacter(newCharacter.charFile);
        }); tabMENU.add(btnLoadCharacter);

        var btnSaveCharacter:FlxButton = new FlxCustomButton(btnLoadCharacter.x + btnLoadCharacter.width + 10, btnLoadCharacter.y, Std.int(MENU.width / 2) - 10, null, "Save Character", null, function(){saveCharacter('${txtCharacter.text}-${txtSkin.text}-${txtCategory.text}');}); tabMENU.add(btnSaveCharacter);

        var line0 = new FlxSprite(5, btnLoadCharacter.y + btnLoadCharacter.height + 5).makeGraphic(Std.int(MENU.width - 10), 2, FlxColor.BLACK); tabMENU.add(line0);

        chkLEFT = new FlxUICheckBox(line0.x, line0.y + line0.height + 5, null, null, "onRight?", 100); tabMENU.add(chkLEFT);
        chkGFPos = new FlxUICheckBox(chkLEFT.x, chkLEFT.y + chkLEFT.height + 5, null, null, "Girlfriend Position?", 100); tabMENU.add(chkGFPos);

        var line1 = new FlxSprite(5, chkGFPos.y + chkGFPos.height + 5).makeGraphic(Std.int(MENU.width - 10), 2, FlxColor.BLACK); tabMENU.add(line1);

        var lblIcon = new FlxText(line1.x, line1.y + line1.height + 5, 0, "Icon:", 8); tabMENU.add(lblIcon);
        txtIcon = new FlxUIInputText(lblIcon.x + lblIcon.width + 5, lblIcon.y, Std.int(MENU.width - lblIcon.width - 15), _character.healthicon, 8); tabMENU.add(txtIcon);
        arrayFocus.push(txtIcon);
        txtIcon.name = "CHARACTER_ICON";

        lblOriPos = new FlxText(lblIcon.x, lblIcon.y + lblIcon.height + 10, Std.int(MENU.width) - 10, 'Character Position: [${charPos[0]}, ${charPos[1]}]', 8); tabMENU.add(lblOriPos); lblOriPos.alignment = CENTER;
        var lblCharX = new FlxText(lblOriPos.x, lblOriPos.y + lblOriPos.height + 5, 0, "Offset [X]:", 8); tabMENU.add(lblCharX);
        stpCharacterX = new FlxUINumericStepperCustom(lblCharX.x + lblCharX.width + 5, lblCharX.y, Std.int(MENU.width - lblCharX.width - 15), 1, _character.position[0], -99999, 99999, 1); tabMENU.add(stpCharacterX);
            @:privateAccess arrayFocus.push(cast stpCharacterX.text_field);
        stpCharacterX.name = "CHARACTER_X";

        var lblCharY = new FlxText(lblCharX.x, lblCharX.y + lblCharX.height + 5, 0, "Offset [Y]:", 8); tabMENU.add(lblCharY);
        stpCharacterY = new FlxUINumericStepperCustom(lblCharY.x + lblCharY.width + 5, lblCharY.y, Std.int(MENU.width - lblCharX.width - 15), 1, _character.position[1], -99999, 99999, 1); tabMENU.add(stpCharacterY);
            @:privateAccess arrayFocus.push(cast stpCharacterY.text_field);
        stpCharacterY.name = "CHARACTER_Y";

        var lblCamX = new FlxText(lblCharY.x, lblCharY.y + lblCharY.height + 10, 0, "Camera [X]:", 8); tabMENU.add(lblCamX);
        stpCameraX = new FlxUINumericStepperCustom(lblCamX.x + lblCamX.width + 5, lblCamX.y, Std.int(MENU.width - lblCamX.width - 15), 1, _character.camera[0], -99999, 99999, 1); tabMENU.add(stpCameraX);
            @:privateAccess arrayFocus.push(cast stpCameraX.text_field);
        stpCameraX.name = "CHARACTER_CameraX";

        var lblCamY = new FlxText(lblCamX.x, lblCamX.y + lblCamX.height + 5, 0, "Camera [Y]:", 8); tabMENU.add(lblCamY);
        stpCameraY = new FlxUINumericStepperCustom(lblCamY.x + lblCamY.width + 5, lblCamY.y, Std.int(MENU.width - lblCamY.width - 15), 1, _character.camera[1], -99999, 99999, 1); tabMENU.add(stpCameraY);
            @:privateAccess arrayFocus.push(cast stpCameraY.text_field);
        stpCameraY.name = "CHARACTER_CameraY";
        
        chkFlipImage = new FlxUICheckBox(lblCamY.x, lblCamY.y + lblCamY.height + 5, null, null, "Character Image is Looking Right", 0); chkFlipImage.checked = _character.onRight; tabMENU.add(chkFlipImage);
        chkAntialiasing = new FlxUICheckBox(chkFlipImage.x, chkFlipImage.y + chkFlipImage.height + 5, null, null, "Without Antialiasing", 0); chkAntialiasing.checked = _character.nAntialiasing; tabMENU.add(chkAntialiasing);
        chkDanceIdle = new FlxUICheckBox(chkAntialiasing.x, chkAntialiasing.y + chkAntialiasing.height + 5, null, null, "Dance on Idle", 0); chkDanceIdle.checked = _character.danceIdle; tabMENU.add(chkDanceIdle);

        var line2 = new FlxSprite(5, chkDanceIdle.y + chkDanceIdle.height + 5).makeGraphic(Std.int(MENU.width - 10), 2, FlxColor.BLACK); tabMENU.add(line2);

        var lblImage = new FlxText(line2.x, line2.y + line2.height + 5, 0, "Image:", 8); tabMENU.add(lblImage);
        txtImage = new FlxUIInputText(lblImage.x + lblImage.width + 5, lblImage.y, Std.int(MENU.width - lblImage.width - 15), _character.image, 8); tabMENU.add(txtImage);
        arrayFocus.push(txtImage);
        txtImage.name = "CHARACTER_IMAGE";

        var ttlCharAnims = new FlxText(lblImage.x, lblImage.y + lblImage.height + 5, Std.int(MENU.width - 10), "Character Animations", 8); ttlCharAnims.alignment = CENTER; tabMENU.add(ttlCharAnims);
        
        var anims:Array<String> = [];
        for(anim in _character.anims){anims.push(anim.anim);}
        clAnims = new FlxUICustomList(ttlCharAnims.x, ttlCharAnims.y + ttlCharAnims.height + 5, Std.int(MENU.width - 10), anims); tabMENU.add(clAnims);
        clAnims.name = "CHARACTER_ANIMS";

        var btnAnimAdd:FlxButton = new FlxCustomButton(clAnims.x, clAnims.y + clAnims.height + 5, Std.int(MENU.width / 2) - 10, null, "Add / Update Animation", FlxColor.fromRGB(138, 255, 142), function(){
            var arrIndices:Array<Int> = [];
            if(txtAnimIndices.text.trim().split(",").length > 1){for(i in txtAnimIndices.text.trim().split(",")){arrIndices.push(Std.parseInt(i));}}

            if(clAnims.contains(txtAnimName.text)){
                for(anim in _character.anims){
                    if(anim.anim == txtAnimName.text){
                        anim.symbol = txtAnimSymbol.text;
                        anim.fps = Std.int(stpAnimFrameRate.value);
                        anim.indices = arrIndices;
                        anim.loop = chkAnimLoop.checked;
                        break;
                    }
                }
            }else if(txtAnimName.text.length > 0){
                var nCharAnim:AnimArray = {
                    anim: txtAnimName.text,
                    symbol: txtAnimSymbol.text,
                    fps: Std.int(stpAnimFrameRate.value),
    
                    indices: arrIndices,
    
                    loop: chkAnimLoop.checked
                }

                _character.anims.push(nCharAnim);
                
                var anims:Array<String> = []; for(anim in _character.anims){anims.push(anim.anim);}
                clAnims.setData(anims);
            }          

            reloadCharacter();
        }); tabMENU.add(btnAnimAdd);
        var btnAnimDel:FlxButton = new FlxCustomButton(btnAnimAdd.x + btnAnimAdd.width + 10, btnAnimAdd.y, Std.int(MENU.width / 2) - 10, null, "Delete Animation", FlxColor.fromRGB(255, 138, 138), function(){
            if(clAnims.contains(txtAnimName.text)){
                for(anim in _character.anims){
                    if(anim.anim == txtAnimName.text){
                        _character.anims.remove(anim);
                        break;
                    }
                }
            }
            var anims:Array<String> = []; for(anim in _character.anims){anims.push(anim.anim);}
            clAnims.setData(anims);

            reloadCharacter();
        }); tabMENU.add(btnAnimDel);

        var lblAnimName = new FlxText(btnAnimAdd.x, btnAnimAdd.y + btnAnimAdd.height + 7, 0, "Anim Name:", 8); tabMENU.add(lblAnimName);
        txtAnimName = new FlxUIInputText(lblAnimName.x + lblAnimName.width + 5, lblAnimName.y, Std.int(MENU.width - lblAnimName.width - 15), "", 8); tabMENU.add(txtAnimName);
        arrayFocus.push(txtAnimName);
        txtAnimName.name = "ANIMATION_NAME";
        
        var lblAnimSymbol = new FlxText(lblAnimName.x, lblAnimName.y + lblAnimName.height + 5, 0, "Anim Symbol:", 8); tabMENU.add(lblAnimSymbol);
        txtAnimSymbol = new FlxUIInputText(lblAnimSymbol.x + lblAnimSymbol.width + 5, lblAnimSymbol.y, Std.int(MENU.width - lblAnimSymbol.width - 15), "", 8); tabMENU.add(txtAnimSymbol);
        arrayFocus.push(txtAnimSymbol);
        txtAnimSymbol.name = "ANIMATION_SYMBOL";

        var lblAnimIndices = new FlxText(lblAnimSymbol.x, lblAnimSymbol.y + lblAnimSymbol.height + 5, 0, "Anim Indices:", 8); tabMENU.add(lblAnimIndices);
        txtAnimIndices = new FlxUIInputText(lblAnimIndices.x + lblAnimIndices.width + 5, lblAnimIndices.y, Std.int(MENU.width - lblAnimIndices.width - 15), "", 8); tabMENU.add(txtAnimIndices);
        arrayFocus.push(txtAnimIndices);
        txtAnimIndices.name = "ANIMATION_INDICES";

        var lblAnimFrame = new FlxText(lblAnimIndices.x, lblAnimIndices.y + lblAnimIndices.height + 7, 0, "Framerate:", 8); tabMENU.add(lblAnimFrame);
        stpAnimFrameRate = new FlxUINumericStepperCustom(lblAnimFrame.x + lblAnimFrame.width + 5, lblAnimFrame.y, Std.int(MENU.width - lblAnimFrame.width - 15), 1, 0, -99999, 99999, 1); tabMENU.add(stpAnimFrameRate);
            @:privateAccess arrayFocus.push(cast stpAnimFrameRate.text_field);
        stpAnimFrameRate.name = "ANIMATION_FRAMERATE";

        chkAnimLoop = new FlxUICheckBox(lblAnimFrame.x, lblAnimFrame.y + lblAnimFrame.height + 5, null, null, "Animation Loop", 100); tabMENU.add(chkAnimLoop);
        
        var btnEditXEML:FlxButton = new FlxCustomButton(chkAnimLoop.x, chkAnimLoop.y + chkAnimLoop.height + 10, Std.int(MENU.width - 10), null, "EDIT POSITION ON XML", null, function(){
            FlxG.switchState(new states.editors.XMLEditorState(null, this));
        }); tabMENU.add(btnEditXEML);


        MENU.addGroup(tabMENU);

        MENU.showTabId("1Character");
    }
    
    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>){
        if(id == FlxUICheckBox.CLICK_EVENT){
            var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch(label){
                default:{trace('$label WORKS!');}
                case "onRight?":{lblOriPos.text = 'Character Position: [${charPos[0]}, ${charPos[1]}]'; reloadCharacter();}
                case "Girlfriend Position?":{lblOriPos.text = 'Character Position: [${charPos[0]}, ${charPos[1]}]'; reloadCharacter();}
                case "Character Image is Looking Right":{_character.onRight = check.checked; reloadCharacter();}
                case "Without Antialiasing":{_character.nAntialiasing = check.checked; reloadCharacter();}
                case "Dance on Idle":{_character.danceIdle = check.checked; reloadCharacter();}
			}
		}else if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)){
            var input:FlxUIInputText = cast sender;
            var wname = input.name;
            switch(wname){
                default:{trace('$wname WORKS!');}
                case "CHARACTER_NAME":{bfStage.curCharacter = input.text; reloadCharacter();}
                case "CHARACTER_SKIN":{bfStage.curSkin = input.text; reloadCharacter();}
                case "CHARACTER_CATEGORY":{bfStage.curCategory = input.text; reloadCharacter();}
                case "CHARACTER_ICON":{
                    _character.healthicon = input.text;
                    healthIcon.setIcon(_character.healthicon);
                    healthIcon.x = FlxG.width - healthIcon.width;
                }
                case "CHARACTER_IMAGE":{_character.image = input.text; reloadCharacter();}
            }
        }else if(id == FlxUIDropDownMenu.CLICK_EVENT && (sender is FlxUIDropDownMenu)){
            var drop:FlxUIDropDownMenu = cast sender;
            var wname = drop.name;
            switch(wname){
                default:{trace('$wname WORKS!');}
            }
        }else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)){
            var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
            switch(wname){
                default:{trace('$wname WORKS!');}
                case "CHARACTER_X":{_character.position[0] = nums.value; reloadCharacter();}
                case "CHARACTER_Y":{_character.position[1] = nums.value; reloadCharacter();}
                case "CHARACTER_CameraX":{_character.camera[0] = nums.value;}
                case "CHARACTER_CameraY":{_character.camera[1] = nums.value;}
            }
        }else if(id == FlxUICustomList.CHANGE_EVENT && (sender is FlxUICustomList)){
            var list:FlxUICustomList = cast sender;
			var wname = list.name;
            switch(wname){
                default:{trace('$wname WORKS!');}
                case "CHARACTER_ANIMS":{
                    var curAnim = _character.anims[list.getSelectedIndex()];
                    if(curAnim != null){
                        bfStage.playAnim(false, curAnim.anim, true);
                        txtAnimName.text = curAnim.anim;
                        txtAnimSymbol.text = curAnim.symbol;
                        txtAnimIndices.text = curAnim.indices.toString();
                        stpAnimFrameRate.value = curAnim.fps;
                        chkAnimLoop.checked = curAnim.loop;
                    }else{
                        txtAnimName.text = "";
                        txtAnimSymbol.text = "";
                        txtAnimIndices.text = "[]";
                        stpAnimFrameRate.value = 0;
                        chkAnimLoop.checked = false;
                    }
                }
            }
        }
    }

    var _file:FileReference;
    function saveCharacter(name:String){
        var data:String = Json.stringify(_character);
    
        if((data != null) && (data.length > 0)){
            _file = new FileReference();
            _file.addEventListener(Event.COMPLETE, onSaveComplete);
            _file.addEventListener(Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
            _file.save(data, name + ".json");
        }
    }

    function onSaveComplete(_):Void {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.notice("Successfully saved CHARACTER DATA.");
    }
        
    function onSaveCancel(_):Void {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
    }

    function onSaveError(_):Void{
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.error("Problem saving Character data");
    }
}