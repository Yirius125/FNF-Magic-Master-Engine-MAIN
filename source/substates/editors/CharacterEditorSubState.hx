package substates.editors;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUITabMenu;
import flixel.input.keyboard.FlxKey;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUI;
import flixel.tweens.FlxTween;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import states.MusicBeatState;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxG;

import FlxCustom.FlxUICustomNumericStepper;
import FlxCustom.FlxUICustomButton;
import FlxCustom.FlxUICustomList;
import FlxCustom.FlxCustomButton;
import Song.SwagSong;

class CharacterEditorSubState extends MusicBeatSubstate {
    public var last_cameras:Array<FlxCamera> = [];
    public var characters_stage:Stage;
    public var song_edit:SwagSong;

	public var curCharacter:Int = 0;
	public var selCharacter:Character;

    var camFollow:FlxObject;
	var subHUD:FlxCamera;

    var arrayFocus:Array<FlxUIInputText> = [];
    var MENU:FlxUITabMenu;

	public function new(song:SwagSong, stage:Stage, onClose:Void->Void):Void {
		this.characters_stage = stage;
        this.song_edit = song;
        super(onClose);
		curCamera.bgColor.alpha = 200;
		curCamera.alpha = 0;

		subHUD = new FlxCamera();
		subHUD.bgColor.alpha = 0;
		FlxG.cameras.add(subHUD);
        
        last_cameras = characters_stage.cameras.copy();
        characters_stage.cameras = [curCamera];

        MENU = new FlxUITabMenu(null, [], true);
        MENU.resize(300, 250);
		MENU.x = FlxG.width - MENU.width;
		MENU.scrollFactor.set(0, 0);
        MENU.camera = subHUD;
        addMENUTABS();
        add(MENU);

		camFollow = new FlxObject(0, 0, 1, 1);
        curCamera.follow(camFollow, LOCKON);
		camFollow.screenCenter();
		add(camFollow);

		curCamera.zoom = stage.zoom;

		changeCharacter();

		FlxTween.tween(curCamera, {alpha: 1}, 0.5, {onComplete: function(twn){canControlle = true;}});

	}

	override function create() {
		super.create();
		
		FlxG.mouse.visible = true;
	}

    var pos = [[], []];
	override function update(elapsed:Float):Void {
		super.update(elapsed);

        var arrayControlle = true; for(item in arrayFocus){if(item.hasFocus){arrayControlle = false;}}
        if(canControlle && arrayControlle){
            if(FlxG.mouse.justPressedRight){pos = [[camFollow.x, camFollow.y],[FlxG.mouse.x, FlxG.mouse.y]];}
            if(FlxG.mouse.pressedRight){camFollow.setPosition(pos[0][0] + (pos[1][0] - FlxG.mouse.x), pos[0][1] + (pos[1][1] - FlxG.mouse.y));}

            if(FlxG.keys.pressed.SHIFT){
                if(FlxG.mouse.wheel != 0){curCamera.zoom += (FlxG.mouse.wheel * 0.1);}
				
				if(song_edit.characters[curCharacter] != null){
					if(FlxG.keys.justPressed.W){song_edit.characters[curCharacter][1][1] -= 10; updateStage();}
					if(FlxG.keys.justPressed.A){song_edit.characters[curCharacter][1][0] -= 10; updateStage();}
					if(FlxG.keys.justPressed.S){song_edit.characters[curCharacter][1][1] += 10; updateStage();}
					if(FlxG.keys.justPressed.D){song_edit.characters[curCharacter][1][0] += 10; updateStage();}
					
					if(FlxG.keys.justPressed.E){song_edit.characters[curCharacter][6] += 1; updateStage();}
					if(FlxG.keys.justPressed.Q){song_edit.characters[curCharacter][6] -= 1; updateStage();}
				}
			}else{
                if(FlxG.mouse.wheel != 0){curCamera.zoom += (FlxG.mouse.wheel * 0.01);}

				if(song_edit.characters[curCharacter] != null){
					if(FlxG.keys.justPressed.W){song_edit.characters[curCharacter][1][1] -= 1; updateStage();}
					if(FlxG.keys.justPressed.A){song_edit.characters[curCharacter][1][0] -= 1; updateStage();}
					if(FlxG.keys.justPressed.S){song_edit.characters[curCharacter][1][1] += 1; updateStage();}
					if(FlxG.keys.justPressed.D){song_edit.characters[curCharacter][1][0] += 1; updateStage();}
					
					if(FlxG.keys.justPressed.E){song_edit.characters[curCharacter][2] += 0.1; updateStage();}
					if(FlxG.keys.justPressed.Q){song_edit.characters[curCharacter][2] -= 0.1; updateStage();}
				}
			}
			
			if(song_edit.characters[curCharacter] != null){
				if(FlxG.keys.justPressed.F){song_edit.characters[curCharacter][3] = !song_edit.characters[curCharacter][3]; updateStage();}
			}

			if(FlxG.keys.justPressed.Z){changeCharacter(-1);}
			if(FlxG.keys.justPressed.X){changeCharacter(1);}

			if(principal_controls.checkAction("Menu_Back", JUST_PRESSED)){doClose();}
        }
	}

	public function changeCharacter(value:Int = 0, force:Bool = false):Void {
		curCharacter = force ? value : curCharacter + value;
		if(curCharacter < 0){curCharacter = song_edit.characters.length - 1;}
		if(curCharacter >= song_edit.characters.length){curCharacter = 0;}

		for(c in characters_stage.characterData){c.alpha = 0.5;}
		selCharacter = characters_stage.characterData[curCharacter];
		if(selCharacter != null){selCharacter.alpha = 1;}

		updateValues();
	}

	public function updateStage():Void {
        characters_stage.setCharacters(song_edit.characters);
		
		for(c in characters_stage.characterData){c.alpha = 0.5;}
		selCharacter = characters_stage.characterData[curCharacter];
		if(selCharacter != null){selCharacter.alpha = 1;}

		updateValues();
	}

	public function updateValues():Void {
		if(selCharacter == null){return;}
		var char_data:Array<Dynamic> = song_edit.characters[curCharacter];

		txtCharacter.text = char_data[0];
		txtAspect.text = char_data[4];
		chkLEFT.checked = char_data[3];
		stpCharX.value = char_data[1][0];
		stpCharY.value = char_data[1][1];
		stpCharSize.value = char_data[2];
		stpCharLayout.value = char_data[6];
	}

	public function doClose():Void {
		canControlle = false;
		subHUD.visible = false;
		for(c in characters_stage.characterData){c.alpha = 1;}
		FlxTween.tween(curCamera, {alpha: 0}, 0.5, {onComplete: function(twn){close();}});
	}

	override function close():Void {
		characters_stage.cameras = last_cameras.copy();

		FlxG.cameras.remove(subHUD);
		subHUD.destroy();

		super.close();
	}

	var stpCharX:FlxUICustomNumericStepper;
	var stpCharY:FlxUICustomNumericStepper;
	var stpCharLayout:FlxUINumericStepper;
	var stpCharSize:FlxUINumericStepper;
	var txtCharacter:FlxUIInputText;
	var txtAspect:FlxUIInputText;
	var chkLEFT:FlxUICheckBox;
	function addMENUTABS():Void {
        var tabMENU = new FlxUI(null, MENU);
        tabMENU.name = "Characters";
        MENU.addGroup(tabMENU);

        var btnAddChar:FlxButton = new FlxCustomButton(25, 25, 100, null, "Create Character", null, null, function(){song_edit.characters.push(["Boyfriend", [100, 100], 1, false, "Default", "NORMAL", 0]); updateStage(); updateValues();}); tabMENU.add(btnAddChar);
        var btnDelChar:FlxButton = new FlxCustomButton(150, 25, 100, null, "Delete Character", null, null, function(){song_edit.characters.remove(song_edit.characters[curCharacter]); updateStage(); updateValues();}); tabMENU.add(btnDelChar);
        
        var lblCharacter = new FlxText(25, 75, 0, "Name:", 8); tabMENU.add(lblCharacter);
        txtCharacter = new FlxUIInputText(25 + lblCharacter.width + 5, lblCharacter.y, 200, "", 8); tabMENU.add(txtCharacter);
        arrayFocus.push(txtCharacter);
        txtCharacter.name = "CHARACTER_NAME";

        var lblAspect = new FlxText(25, 100, 0, "Aspect:", 8); tabMENU.add(lblAspect);
        txtAspect = new FlxUIInputText(25 + lblAspect.width + 5, lblAspect.y, 200, "", 8); tabMENU.add(txtAspect);
        arrayFocus.push(txtAspect);
        txtAspect.name = "CHARACTER_ASPECT";

        chkLEFT = new FlxUICheckBox(25, 125, null, null, "onRight?", 100); tabMENU.add(chkLEFT);

        var lblCharX = new FlxText(25, 150, 0, "X:", 8); tabMENU.add(lblCharX);
        stpCharX = new FlxUICustomNumericStepper(25 + lblCharX.width + 5, 150, 90, 1, 0, -99999, 99999, 1); tabMENU.add(stpCharX);
            @:privateAccess arrayFocus.push(cast stpCharX.text_field);
        stpCharX.name = "CHARACTER_X";

        var lblCharSize = new FlxText(150, 150, 0, "Size:", 8); tabMENU.add(lblCharSize);
        stpCharSize = new FlxUINumericStepper(150 + lblCharSize.width + 10, 150, 0.1, 1, 0, 999, 1); tabMENU.add(stpCharSize);
            @:privateAccess arrayFocus.push(cast stpCharSize.text_field);
        stpCharSize.name = "CHARACTER_SIZE";

        var lblCharY = new FlxText(25, 175, 0, "Y:", 8); tabMENU.add(lblCharY);
        stpCharY = new FlxUICustomNumericStepper(25 + lblCharY.width + 5, 175, 100, 1, 0, -99999, 99999, 1); tabMENU.add(stpCharY);
            @:privateAccess arrayFocus.push(cast stpCharY.text_field);
        stpCharY.name = "CHARACTER_Y";

        var lblCharLayout = new FlxText(150, 175, 0, "Layout:", 8); tabMENU.add(lblCharLayout);
        stpCharLayout = new FlxUINumericStepper(150 + lblCharLayout.width + 5, 175, 1, 0, -999, 999); tabMENU.add(stpCharLayout);
            @:privateAccess arrayFocus.push(cast stpCharLayout.text_field);
        stpCharLayout.name = "CHARACTER_LAYOUT";

        var btnPrevChar:FlxButton = new FlxCustomButton(25, 200, 100, null, "Previous Character", null, null, function(){changeCharacter(-1);}); tabMENU.add(btnPrevChar);
        var btnNextChar:FlxButton = new FlxCustomButton(150, 200, 100, null, "Next Character", null, null, function(){changeCharacter(1);}); tabMENU.add(btnNextChar);
    
		
        MENU.showTabId("Characters");
	}

	
    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>){
        if(id == FlxUICheckBox.CLICK_EVENT){
            var check:FlxUICheckBox = cast sender;
			var wname = check.getLabel().text;
			switch(wname){
                case "onRight?":{
                    if(song_edit.characters[curCharacter] == null){return;}
					song_edit.characters[curCharacter][3] = check.checked;
                    updateStage();
                }
			}
		}else if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)){
            var input:FlxUIInputText = cast sender;
            var wname = input.name;

			switch(wname){
				case "CHARACTER_NAME":{
                    if(song_edit.characters[curCharacter] == null){return;}
					song_edit.characters[curCharacter][0] = input.text;
					updateStage();
				}
                case "CHARACTER_ASPECT":{
                    if(song_edit.characters[curCharacter] == null){return;}
					song_edit.characters[curCharacter][4] = input.text;
					updateStage();
				}
			}
		}else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)){
            var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;

			switch(wname){
                case "CHARACTER_X":{
                    if(song_edit.characters[curCharacter] == null){return;}
                    song_edit.characters[curCharacter][1][0] = nums.value;
                    updateStage();
                }
                case "CHARACTER_Y":{
                    if(song_edit.characters[curCharacter] == null){return;}
                    song_edit.characters[curCharacter][1][1] = nums.value;
                    updateStage();
                }
                case "CHARACTER_SIZE":{
                    if(song_edit.characters[curCharacter] == null){return;}
					song_edit.characters[curCharacter][2] = nums.value;
                    updateStage();
                }
                case "CHARACTER_LAYOUT":{
                    if(song_edit.characters[curCharacter] == null){return;}
                    song_edit.characters[curCharacter][6] = Std.int(nums.value);
                    updateStage();
                }
			}
		}
	}
}
