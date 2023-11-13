package states.editors;

import flixel.FlxG;
import flixel.FlxState;
import haxe.xml.Access;
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
import flixel.sound.FlxSoundGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
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
import FlxCustom.FlxUICustomNumericStepper;
import FlxCustom.FlxUICustomList;

#if desktop
import Discord.DiscordClient;
import sys.FileSystem;
import sys.io.File;
#end

using SavedFiles;
using StringTools;

class CharacterEditorState extends MusicBeatState{
    public static var _character:CharacterFile;
    public static var curAspect:String = "Default";
    public static var curSkin:String = "Default";

    var chrStage:Character;
    var healthIcon:HealthIcon;
    var cameraPointer:FlxSprite;

    var backStage:Stage;

    var MENU:FlxUITabMenu;
    var arrayFocus:Array<FlxUIInputText> = [];

    private var charPositions:Array<Dynamic> = [
        [100, 100],
        [540, 50],
        [770, 100]
    ];
	private var charPos(get, never):Array<Int>;
	inline function get_charPos():Array<Int> {
        if(chkGFPos.checked){return charPositions[1];}
        if(chrStage.onRight){return charPositions[0];}
        return charPositions[2];
    }

    var camFollow:FlxObject;

    public function new(?onConfirm:String, ?onBack:String, ?character:CharacterFile):Void {
        if(character == null){character = new Character(0, 0).charFile;}
        _character = character;

        super(onConfirm, onBack);
    }

    override function create(){
        FlxG.sound.playMusic(Paths.music('break_song').getSound());

        var bgGrid:FlxSprite = FlxGridOverlay.create(10, 10, FlxG.width, FlxG.height, true, 0xff4d4d4d, 0xff333333);
        bgGrid.cameras = [camGame];
        add(bgGrid);

        backStage = new Stage(
            "Stage",
            [
                ["Girlfriend", [540, 50], 1, false, "Default", "GF", 0],
                ["Daddy_Dearest", [100, 100], 1, true, "Default", "NORMAL", 0],
                ["Boyfriend", [770, 100], 1, false, "Default", "NORMAL", 0],
                ["Boyfriend", [770, 100], 1, false, "Default", "NORMAL", 0]
            ]
        );
        backStage.cameras = [camFGame];
        backStage.is_debug = true;
        add(backStage);

        for(char in backStage.characterData){char.alpha = 0.5;}
        
        chrStage = backStage.getCharacterById(3);
        chrStage.curAspect = curAspect;
        chrStage.curSkin = curSkin;
        chrStage.setupByCharacterFile(_character);
        chrStage.onDebug = true;
        chrStage.alpha = 1;

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

        cameraPointer = new FlxSprite(chrStage.c.getGraphicMidpoint().x + _character.camera[0], chrStage.c.getGraphicMidpoint().y + _character.camera[1]).makeGraphic(5, 5);
        cameraPointer.camera = camFGame;
        add(cameraPointer);

		camFollow = new FlxObject(chrStage.c.getGraphicMidpoint().x, chrStage.c.getGraphicMidpoint().y, 1, 1);
        camFGame.follow(camFollow, LOCKON);
		add(camFollow);

        reloadCharacter();

        #if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence('[${chrStage.curCharacter}-${curSkin}-${curAspect}]', '[Character Editor]');
		MagicStuff.setWindowTitle('Editing [${chrStage.curCharacter}-${curSkin}-${curAspect}]', 1);
		#end

        super.create();
        
        FlxG.mouse.visible = true;
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
                if(FlxG.mouse.wheel != 0){camFGame.zoom += (FlxG.mouse.wheel * 0.1);} 
                
                if(FlxG.keys.justPressed.W){_character.position[1] -= 5; reloadCharacter();}
                if(FlxG.keys.justPressed.A){_character.position[0] -= 5; reloadCharacter();}
                if(FlxG.keys.justPressed.S){_character.position[1] += 5; reloadCharacter();}
                if(FlxG.keys.justPressed.D){_character.position[0] += 5; reloadCharacter();}
                
                if(FlxG.keys.justPressed.I){_character.camera[1] -= 5; reloadCharacter();}
                if(FlxG.keys.justPressed.J){_character.camera[0] -= 5; reloadCharacter();}
                if(FlxG.keys.justPressed.K){_character.camera[1] += 5; reloadCharacter();}
                if(FlxG.keys.justPressed.L){_character.camera[0] += 5; reloadCharacter();}
            }else{
                if(FlxG.mouse.wheel != 0){camFGame.zoom += (FlxG.mouse.wheel * 0.01);}
                
                if(FlxG.keys.justPressed.W){_character.position[1]--; reloadCharacter();}
                if(FlxG.keys.justPressed.A){_character.position[0]--; reloadCharacter();}
                if(FlxG.keys.justPressed.S){_character.position[1]++; reloadCharacter();}
                if(FlxG.keys.justPressed.D){_character.position[0]++; reloadCharacter();}
                
                if(FlxG.keys.justPressed.I){_character.camera[1]--; reloadCharacter();}
                if(FlxG.keys.justPressed.J){_character.camera[0]--; reloadCharacter();}
                if(FlxG.keys.justPressed.K){_character.camera[1]++; reloadCharacter();}
                if(FlxG.keys.justPressed.L){_character.camera[0]++; reloadCharacter();}
            }

            if(FlxG.keys.justPressed.Q){clAnims.setIndex(clAnims.getSelectedIndex() - 1);}
            if(FlxG.keys.justPressed.E){clAnims.setIndex(clAnims.getSelectedIndex() + 1);}
            if(FlxG.keys.justPressed.SPACE){chrStage.playAnim(clAnims.getSelectedLabel(), true);}

            if(FlxG.mouse.justPressedMiddle){camFollow.screenCenter();}
        }
        
        super.update(elapsed);
    
        cameraPointer.setPosition(chrStage.c.getGraphicMidpoint().x + _character.camera[0], chrStage.c.getGraphicMidpoint().y + _character.camera[1]);
    }

    override function destroy() {
        FlxG.sound.music.stop();
        super.destroy();
    }

    public function reloadCharacter():Void{
        chrStage.setupByCharacterFile(_character);
        chrStage.turnLook(chkLEFT.checked);
        chrStage.setPosition(charPos[0], charPos[1]);
        chrStage.playAnim(clAnims.getSelectedLabel(), true);
        
        stpCharacterY.value = _character.position[1];
        stpCharacterX.value = _character.position[0];
        stpCharacterY.value = _character.position[1];
        stpCharacterX.value = _character.position[0];

        stpCameraY.value = _character.camera[1];
        stpCameraX.value = _character.camera[0];
        stpCameraY.value = _character.camera[1];
        stpCameraX.value = _character.camera[0];
    }

    var chkLEFT:FlxUICheckBox;
    var chkGFPos:FlxUICheckBox;
    var lblOriPos:FlxText;
    var txtCharacter:FlxUIInputText;
    var txtScript:FlxUIInputText;
    var txtSkin:FlxUIInputText;
    var txtAspect:FlxUIInputText;
    var txtImage:FlxUIInputText;
    var txtIcon:FlxUIInputText;
    var txtDeathChar:FlxUIInputText;
    var txtScriptChar:FlxUIInputText;
    var stpCharacterX:FlxUINumericStepper;
    var stpCharacterY:FlxUINumericStepper;
    var stpCameraX:FlxUINumericStepper;
    var stpCameraY:FlxUINumericStepper;
    var stpScale:FlxUINumericStepper;
    var chkFlipImage:FlxUICheckBox;
    var chkAntialiasing:FlxUICheckBox;
    var chkDanceIdle:FlxUICheckBox;
    var clAnims:FlxUICustomList;
    var txtAnimName:FlxUIInputText;
    var txtAnimSymbol:FlxUIInputText;
    var txtAnimIndices:FlxUIInputText;
    var stpAnimFrameRate:FlxUINumericStepper;
    var stpSingDuration:FlxUINumericStepper;
    var stpAnimHold:FlxUINumericStepper;
    var chkAnimLoop:FlxUICheckBox;
    private function addMENUTABS(){
        var tabMENU = new FlxUI(null, MENU);
        tabMENU.name = "1Character";

        var lblCharacter = new FlxText(5, 15, 0, "CHARACTER:", 8); tabMENU.add(lblCharacter);
        txtCharacter = new FlxUIInputText(lblCharacter.x + lblCharacter.width + 5, lblCharacter.y, Std.int(MENU.width - lblCharacter.width - 15), chrStage.curCharacter, 8); tabMENU.add(txtCharacter);
        arrayFocus.push(txtCharacter);
        txtCharacter.name = "CHARACTER_NAME";

        var lblSkin = new FlxText(lblCharacter.x, txtCharacter.y + txtCharacter.height + 5, 0, "SKIN:", 8); tabMENU.add(lblSkin);
        txtSkin = new FlxUIInputText(lblSkin.x + lblSkin.width + 5, lblSkin.y, Std.int(MENU.width - lblSkin.width - 15), curSkin, 8); tabMENU.add(txtSkin);
        arrayFocus.push(txtSkin);
        txtSkin.name = "CHARACTER_SKIN";
        
        var lblCat = new FlxText(lblCharacter.x, txtSkin.y + txtSkin.height + 5, 0, "ASPECT:", 8); tabMENU.add(lblCat);
        txtAspect = new FlxUIInputText(lblCat.x + lblCat.width + 5, lblCat.y, Std.int(MENU.width - lblCat.width - 15), curAspect, 8); tabMENU.add(txtAspect);
        arrayFocus.push(txtAspect);
        txtAspect.name = "CHARACTER_ASPECT";

        var btnLoadCharacter:FlxButton = new FlxCustomButton(lblCat.x, lblCat.y + lblCat.height + 5, Std.int(MENU.width / 2) - 10, null, "Load Character", null, null, function(){
            var newCharacter:Character = new Character(0, 0, Paths.getFileName(txtCharacter.text, true), Paths.getFileName(txtAspect.text, true));
            newCharacter.curSkin = Paths.getFileName(txtSkin.text, true);
            newCharacter.setupByCharacterFile();

            curAspect = txtAspect.text;
            curSkin = txtSkin.text;
            
            MusicBeatState.switchState("states.editors.CharacterEditorState", [null, "states.MainMenuState", newCharacter.charFile]);
        }); tabMENU.add(btnLoadCharacter);

        var btnSaveCharacter:FlxButton = new FlxCustomButton(btnLoadCharacter.x + btnLoadCharacter.width + 10, btnLoadCharacter.y, Std.int(MENU.width / 2) - 10, null, "Save Character", null, null, function(){saveCharacter('${txtCharacter.text}-${txtSkin.text}-${txtAspect.text}');}); tabMENU.add(btnSaveCharacter);

        var line0 = new FlxSprite(5, btnLoadCharacter.y + btnLoadCharacter.height + 5).makeGraphic(Std.int(MENU.width - 10), 2, FlxColor.BLACK); tabMENU.add(line0);

        chkLEFT = new FlxUICheckBox(5, line0.y + line0.height + 5, null, null, "onRight?", 100); tabMENU.add(chkLEFT);
        chkGFPos = new FlxUICheckBox(5, chkLEFT.y + chkLEFT.height + 5, null, null, "Girlfriend Position?", 100); tabMENU.add(chkGFPos);

        var line1 = new FlxSprite(5, chkGFPos.y + chkGFPos.height + 5).makeGraphic(Std.int(MENU.width - 10), 2, FlxColor.BLACK); tabMENU.add(line1);

        var lblIcon = new FlxText(5, line1.y + line1.height + 5, 0, "Icon:", 8); tabMENU.add(lblIcon);
        txtIcon = new FlxUIInputText(lblIcon.x + lblIcon.width + 5, lblIcon.y, Std.int(MENU.width - lblIcon.width - 15), _character.healthicon, 8); tabMENU.add(txtIcon);
        arrayFocus.push(txtIcon);
        txtIcon.name = "CHARACTER_ICON";
        
        var lblScript = new FlxText(5, lblIcon.y + lblIcon.height + 5, 0, "Script:", 8); tabMENU.add(lblScript);
        txtScript = new FlxUIInputText(lblScript.x + lblScript.width + 5, lblScript.y, Std.int(MENU.width - lblScript.width - 15), _character.script, 8); tabMENU.add(txtScript);
        arrayFocus.push(txtScript);
        txtScript.name = "CHARACTER_SCRIPT";

        var lblScale = new FlxText(5, lblScript.y + lblScript.height + 5, 0, "Scale:", 8); tabMENU.add(lblScale);
        stpScale = new FlxUICustomNumericStepper(lblScale.x + lblScale.width + 5, lblScale.y, Std.int(MENU.width - lblScale.width - 15), 0.1, _character.scale, -99999, 99999, 1); tabMENU.add(stpScale);
            @:privateAccess arrayFocus.push(cast stpScale.text_field);
        stpScale.name = "CHARACTER_Scale";

        var lblSingDuration = new FlxText(5, lblScale.y + lblScale.height + 5, 0, "Sing Duration:", 8); tabMENU.add(lblSingDuration);
        stpSingDuration = new FlxUICustomNumericStepper(lblSingDuration.x + lblSingDuration.width + 5, lblSingDuration.y, Std.int(MENU.width - lblSingDuration.width - 15), 0.5, _character.scale, 0, 99999, 1); tabMENU.add(stpSingDuration);
            @:privateAccess arrayFocus.push(cast stpSingDuration.text_field);
        stpSingDuration.name = "CHARACTER_SingDuration";
        
        lblOriPos = new FlxText(5, lblSingDuration.y + lblSingDuration.height + 10, Std.int(MENU.width) - 10, 'Character Position: [${charPos[0]}, ${charPos[1]}]', 8); tabMENU.add(lblOriPos); lblOriPos.alignment = CENTER;
        var lblCharX = new FlxText(lblOriPos.x, lblOriPos.y + lblOriPos.height + 5, 0, "Offset [X]:", 8); tabMENU.add(lblCharX);
        stpCharacterX = new FlxUICustomNumericStepper(lblCharX.x + lblCharX.width + 5, lblCharX.y, Std.int(MENU.width - lblCharX.width - 15), 1, _character.position[0], -99999, 99999, 1); tabMENU.add(stpCharacterX);
            @:privateAccess arrayFocus.push(cast stpCharacterX.text_field);
        stpCharacterX.name = "CHARACTER_X";

        var lblCharY = new FlxText(5, lblCharX.y + lblCharX.height + 5, 0, "Offset [Y]:", 8); tabMENU.add(lblCharY);
        stpCharacterY = new FlxUICustomNumericStepper(lblCharY.x + lblCharY.width + 5, lblCharY.y, Std.int(MENU.width - lblCharX.width - 15), 1, _character.position[1], -99999, 99999, 1); tabMENU.add(stpCharacterY);
            @:privateAccess arrayFocus.push(cast stpCharacterY.text_field);
        stpCharacterY.name = "CHARACTER_Y";

        var lblCamX = new FlxText(5, lblCharY.y + lblCharY.height + 10, 0, "Camera [X]:", 8); tabMENU.add(lblCamX);
        stpCameraX = new FlxUICustomNumericStepper(lblCamX.x + lblCamX.width + 5, lblCamX.y, Std.int(MENU.width - lblCamX.width - 15), 1, _character.camera[0], -99999, 99999, 1); tabMENU.add(stpCameraX);
            @:privateAccess arrayFocus.push(cast stpCameraX.text_field);
        stpCameraX.name = "CHARACTER_CameraX";

        var lblCamY = new FlxText(5, lblCamX.y + lblCamX.height + 5, 0, "Camera [Y]:", 8); tabMENU.add(lblCamY);
        stpCameraY = new FlxUICustomNumericStepper(lblCamY.x + lblCamY.width + 5, lblCamY.y, Std.int(MENU.width - lblCamY.width - 15), 1, _character.camera[1], -99999, 99999, 1); tabMENU.add(stpCameraY);
            @:privateAccess arrayFocus.push(cast stpCameraY.text_field);
        stpCameraY.name = "CHARACTER_CameraY";
        
        chkFlipImage = new FlxUICheckBox(5, lblCamY.y + lblCamY.height + 5, null, null, "Flip Image", 0); chkFlipImage.checked = _character.onRight; tabMENU.add(chkFlipImage);
        chkAntialiasing = new FlxUICheckBox(5, chkFlipImage.y + chkFlipImage.height + 5, null, null, "\nWith Antialiasing", 0); chkAntialiasing.checked = _character.antialiasing; tabMENU.add(chkAntialiasing);
        chkDanceIdle = new FlxUICheckBox(5, chkAntialiasing.y + chkAntialiasing.height + 5, null, null, "Dance on Idle", 0); chkDanceIdle.checked = _character.danceIdle; tabMENU.add(chkDanceIdle);

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

        var btnAnimAdd:FlxButton = new FlxCustomButton(clAnims.x, clAnims.y + clAnims.height + 5, Std.int(MENU.width / 4) - 7, null, "Add Anim", null, FlxColor.fromRGB(138, 255, 142), function(){
            var arrIndices:Array<Int> = [];
            try{arrIndices = Json.parse('{ "Anims": ${txtAnimIndices.text}}').Anims; txtAnimIndices.color = FlxColor.BLACK;}catch(e){trace(e); txtAnimIndices.color = FlxColor.RED;}

            if(!clAnims.contains(txtAnimName.text) && txtAnimName.text.length > 0){
                var nCharAnim:AnimArray = {
                    anim: txtAnimName.text,
                    symbol: txtAnimSymbol.text,
                    fps: Std.int(stpAnimFrameRate.value),
                    indices: arrIndices,
                    sustain_sing: Std.int(stpAnimHold.value),
                    loop: chkAnimLoop.checked
                }

                _character.anims.push(nCharAnim);
                
                var anims:Array<String> = []; for(anim in _character.anims){anims.push(anim.anim);}
                clAnims.setData(anims);
                clAnims.updateIndex();
            }          

            reloadCharacter();
        }); tabMENU.add(btnAnimAdd);
        var btnAnimUpd:FlxButton = new FlxCustomButton(btnAnimAdd.x + btnAnimAdd.width + 5, btnAnimAdd.y, Std.int(MENU.width / 4) - 7, null, "Update Anim", null, FlxColor.fromRGB(138, 255, 142), function(){
            var arrIndices:Array<Int> = [];
            try{arrIndices = Json.parse('{ "Anims": ${txtAnimIndices.text}}').Anims; txtAnimIndices.color = FlxColor.BLACK;}catch(e){trace(e); txtAnimIndices.color = FlxColor.RED;}

            for(anim in _character.anims){
                if(anim.anim == clAnims.getSelectedLabel()){
                    anim.anim = txtAnimName.text;
                    anim.symbol = txtAnimSymbol.text;
                    anim.fps = Std.int(stpAnimFrameRate.value);
                    anim.indices = arrIndices;
                    anim.sustain_sing = Std.int(stpAnimHold.value);
                    anim.loop = chkAnimLoop.checked;
                    break;
                }
            }
            
            var anims:Array<String> = []; for(anim in _character.anims){anims.push(anim.anim);}
            clAnims.setData(anims);

            reloadCharacter();
        }); tabMENU.add(btnAnimUpd);

        var btnAnimDel:FlxButton = new FlxCustomButton(btnAnimUpd.x + btnAnimUpd.width + 10, btnAnimUpd.y, Std.int(MENU.width / 2) - 10, null, "Delete Animation", null, FlxColor.fromRGB(255, 138, 138), function(){
            if(!clAnims.contains(txtAnimName.text)){return;}
            for(anim in _character.anims){
                if(anim.anim != txtAnimName.text){continue;}
                _character.anims.remove(anim); break;
            }
            
            var anims:Array<String> = []; for(anim in _character.anims){anims.push(anim.anim);}
            clAnims.setData(anims);
            clAnims.updateIndex();

            reloadCharacter();
        }); tabMENU.add(btnAnimDel);

        var lblAnimName = new FlxText(5, btnAnimAdd.y + btnAnimAdd.height + 7, 0, "Anim Name:", 8); tabMENU.add(lblAnimName);
        txtAnimName = new FlxUIInputText(lblAnimName.x + lblAnimName.width + 5, lblAnimName.y, Std.int(MENU.width - lblAnimName.width - 15), "", 8); tabMENU.add(txtAnimName);
        arrayFocus.push(txtAnimName);
        txtAnimName.name = "ANIMATION_NAME";
        
        var lblAnimSymbol = new FlxText(5, lblAnimName.y + lblAnimName.height + 5, 0, "Anim Symbol:", 8); tabMENU.add(lblAnimSymbol);
        txtAnimSymbol = new FlxUIInputText(lblAnimSymbol.x + lblAnimSymbol.width + 5, lblAnimSymbol.y, Std.int(MENU.width - lblAnimSymbol.width - 15), "", 8); tabMENU.add(txtAnimSymbol);
        arrayFocus.push(txtAnimSymbol);
        txtAnimSymbol.name = "ANIMATION_SYMBOL";

        var lblAnimIndices = new FlxText(5, lblAnimSymbol.y + lblAnimSymbol.height + 5, 0, "Anim Indices:", 8); tabMENU.add(lblAnimIndices);
        txtAnimIndices = new FlxUIInputText(lblAnimIndices.x + lblAnimIndices.width + 5, lblAnimIndices.y, Std.int(MENU.width - lblAnimIndices.width - 15), "", 8); tabMENU.add(txtAnimIndices);
        arrayFocus.push(txtAnimIndices);
        txtAnimIndices.name = "ANIMATION_INDICES";

        var lblAnimFrame = new FlxText(5, lblAnimIndices.y + lblAnimIndices.height + 7, 0, "Framerate:", 8); tabMENU.add(lblAnimFrame);
        stpAnimFrameRate = new FlxUICustomNumericStepper(lblAnimFrame.x + lblAnimFrame.width + 5, lblAnimFrame.y, Std.int(MENU.width - lblAnimFrame.width - 15), 1, 0, -99999, 99999, 1); tabMENU.add(stpAnimFrameRate);
            @:privateAccess arrayFocus.push(cast stpAnimFrameRate.text_field);
        stpAnimFrameRate.name = "ANIMATION_FRAMERATE";

        var lblAnimHold = new FlxText(5, lblAnimFrame.y + lblAnimFrame.height + 7, 0, "Hold Sing:", 8); tabMENU.add(lblAnimHold);
        stpAnimHold = new FlxUICustomNumericStepper(lblAnimHold.x + lblAnimHold.width + 5, lblAnimHold.y, Std.int(MENU.width - lblAnimHold.width - 15), 1, 0, -99999, 99999, 1); tabMENU.add(stpAnimHold);
            @:privateAccess arrayFocus.push(cast stpAnimHold.text_field);
        stpAnimHold.name = "ANIMATION_HOLDSING";

        chkAnimLoop = new FlxUICheckBox(5, lblAnimHold.y + lblAnimHold.height + 5, null, null, "Animation Loop", 100); tabMENU.add(chkAnimLoop);
        
        var btnSetXMLAnims:FlxButton = new FlxCustomButton(chkAnimLoop.x, chkAnimLoop.y + chkAnimLoop.height + 10, Std.int(MENU.width - 10), null, "SET ANIMATIONS FROM XML", null, null, function(){
            var character_path:String = Paths.image('characters/${chrStage.curCharacter}/${_character.image}').replace('.png', '.xml');
            if(!Paths.exists(character_path)){return;}
            var xml =  Xml.parse(character_path.getText());
            var animSymbols:Array<String> = XMLEditorState.getNamesArray(new Access(xml.firstElement()).elements);

            _character.anims = [];
            for(symbol in animSymbols){
                var nCharAnim:AnimArray = {
                    anim: symbol,
                    symbol: symbol,
                    
                    fps: 24,    
                    indices: [],
                    sustain_sing: 0,

                    loop: false
                }

                _character.anims.push(nCharAnim);
            }
            
            reloadCharacter();
            var anims:Array<String> = []; for(anim in _character.anims){anims.push(anim.anim);}
            clAnims.setData(anims);
        }); tabMENU.add(btnSetXMLAnims);

        var ttlCharFunc = new FlxText(btnSetXMLAnims.x, btnSetXMLAnims.y + btnSetXMLAnims.height + 5, Std.int(MENU.width - 10), "Script Function", 8); ttlCharFunc.alignment = CENTER; tabMENU.add(ttlCharFunc);
        var txtCharFunc = new FlxUIInputText(ttlCharFunc.x, ttlCharFunc.y + ttlCharFunc.height + 5, Std.int(MENU.width - 10), "", 8); tabMENU.add(txtCharFunc);
        arrayFocus.push(txtCharFunc);
        var btnCharFunc:FlxButton = new FlxCustomButton(txtCharFunc.x, txtCharFunc.y + txtCharFunc.height, Std.int(MENU.width - 10), null, "Execute Script Function", null, null, function(){
            chrStage.charScript.exFunction(txtCharFunc.text);
        }); tabMENU.add(btnCharFunc);


        MENU.addGroup(tabMENU);

        MENU.showTabId("1Character");
    }

    private function getFile(_file:FlxUIInputText):Void{
        var fDialog = new FileDialog();
        fDialog.onSelect.add(function(str){_file.text = str;});
        fDialog.browse();
	}
    
    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>){
        if(id == FlxUICheckBox.CLICK_EVENT){
            var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch(label){
                default:{trace('$label WORKS!');}
                case "onRight?":{lblOriPos.text = 'Character Position: [${charPos[0]}, ${charPos[1]}]'; reloadCharacter();}
                case "Girlfriend Position?":{lblOriPos.text = 'Character Position: [${charPos[0]}, ${charPos[1]}]'; reloadCharacter();}
                case "With Antialiasing":{_character.antialiasing = check.checked; reloadCharacter();}
                case "Dance on Idle":{_character.danceIdle = check.checked; reloadCharacter();}
                case "Flip Image":{_character.onRight = check.checked; reloadCharacter();}
			}
		}else if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)){
            var input:FlxUIInputText = cast sender;
            var wname = input.name;
            switch(wname){
                default:{trace('$wname WORKS!');}
                case "CHARACTER_ICON":{
                    _character.healthicon = input.text;
                    healthIcon.setIcon(_character.healthicon);
                    healthIcon.x = MENU.x - healthIcon.width;
                }
                case "CHARACTER_NAME":{_character.name = input.text; reloadCharacter();}
                case "CHARACTER_SKIN":{chrStage.curSkin = input.text; reloadCharacter();}
                case "CHARACTER_ASPECT":{chrStage.curAspect = input.text; reloadCharacter();}
                case "CHARACTER_SCRIPT":{_character.script = input.text; reloadCharacter();}
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
                case "CHARACTER_Scale":{_character.scale = nums.value; reloadCharacter();}
                case "CHARACTER_SingDuration":{_character.sing_time = nums.value;}
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
                        chrStage.playAnim(curAnim.anim, true);
                        txtAnimName.text = curAnim.anim;
                        txtAnimSymbol.text = curAnim.symbol;
                        if(curAnim.indices != null){txtAnimIndices.text = curAnim.indices.toString();}else{txtAnimIndices.text = "[]";}
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
        var data:String = Json.stringify(_character, "\t");
    
        if((data != null) && (data.length > 0)){
            _file = new FileReference();
            _file.addEventListener(Event.COMPLETE, onSaveComplete);
            _file.addEventListener(Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
            _file.save(data, '${name}.json');
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