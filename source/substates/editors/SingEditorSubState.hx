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

class SingEditorSubState extends MusicBeatSubstate {
    public var last_cameras:Array<FlxCamera> = [];
    public var characters_stage:Stage;
    public var song_edit:SwagSong;

    public var singAnimations:Array<String> = ["singUP", "singLEFT", "singDOWN", "singRIGHT"];
	public var curCharacter:Int = 0;
    public var curSection:Int = 0;
    public var curStrum:Int = 0;

    var camFollow:FlxObject;
	var subHUD:FlxCamera;

    var arrayFocus:Array<FlxUIInputText> = [];
    var MENU:FlxUITabMenu;

	public function new(song:SwagSong, stage:Stage, curStrum:Int, curSection:Int, onClose:Void->Void):Void {
        this.characters_stage = stage;
        this.curSection = curSection;
        this.curStrum = curStrum;
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

        doSing(elapsed);

        var arrayControlle = true; for(item in arrayFocus){if(item.hasFocus){arrayControlle = false;}}
        if(canControlle && arrayControlle){
            if(FlxG.mouse.justPressedRight){pos = [[camFollow.x, camFollow.y],[FlxG.mouse.x, FlxG.mouse.y]];}
            if(FlxG.mouse.pressedRight){camFollow.setPosition(pos[0][0] + (pos[1][0] - FlxG.mouse.x), pos[0][1] + (pos[1][1] - FlxG.mouse.y));}

            if(FlxG.keys.pressed.SHIFT){
                if(FlxG.mouse.wheel != 0){curCamera.zoom += (FlxG.mouse.wheel * 0.1);}
				
			}else{
                if(FlxG.mouse.wheel != 0){curCamera.zoom += (FlxG.mouse.wheel * 0.01);}
			}

			if(FlxG.keys.justPressed.A){changeCharacter(-1);}
			if(FlxG.keys.justPressed.D){changeCharacter(1);}

			if(principal_controls.checkAction("Menu_Back", JUST_PRESSED)){doClose();}
        }
	}

    var holdSing:Float = 0.2;
    public function doSing(elapsed:Float):Void {
        if(song_edit.sectionStrums[curStrum] == null){return;}
        holdSing -= elapsed;
        if(holdSing <= 0){
            holdSing = 0.2;
            
            var toSing:Array<Int> = [];
            if(song_edit.sectionStrums[curStrum].notes[curSection] != null && song_edit.sectionStrums[curStrum].notes[curSection].changeSing){
                toSing = song_edit.sectionStrums[curStrum].notes[curSection].charToSing.copy();
            }else{
                toSing = song_edit.sectionStrums[curStrum].charToSing.copy();
            }

            for(s in characters_stage.characterData){s.dance();}
            for(s in toSing){
                var cur_character = characters_stage.characterData[s];
                if(cur_character == null){continue;}
                cur_character.singAnim(singAnimations[FlxG.random.int(0, singAnimations.length - 1)], true);
            }
        }

    }

	public function changeCharacter(value:Int = 0, force:Bool = false):Void {
		curCharacter = force ? value : curCharacter + value;
		if(curCharacter < 0){curCharacter = song_edit.characters.length - 1;}
		if(curCharacter >= song_edit.characters.length){curCharacter = 0;}

		for(c in characters_stage.characterData){c.alpha = 0.5;}
		var selCharacter = characters_stage.characterData[curCharacter];
		if(selCharacter != null){selCharacter.alpha = 1;}

        if(song_edit.sectionStrums[curStrum].notes[curSection] != null && song_edit.sectionStrums[curStrum].notes[curSection].changeSing){
            chkSing.checked = song_edit.sectionStrums[curStrum].notes[curSection].charToSing.contains(curCharacter); 
        }else{
            chkSing.checked = song_edit.sectionStrums[curStrum].charToSing.contains(curCharacter);
        }
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

	var chkSing:FlxUICheckBox;
	var chkSecSing:FlxUICheckBox;
	function addMENUTABS():Void {
        var tabMENU = new FlxUI(null, MENU);
        tabMENU.name = "Characters";
        MENU.addGroup(tabMENU);

        var btnPrevChar:FlxButton = new FlxCustomButton(25, 25, 100, null, "Previous Character", null, null, function(){changeCharacter(-1);}); tabMENU.add(btnPrevChar);
        var btnNextChar:FlxButton = new FlxCustomButton(150, 25, 100, null, "Next Character", null, null, function(){changeCharacter(1);}); tabMENU.add(btnNextChar);
    
        chkSing = new FlxUICheckBox(25, 75, null, null, "Sing?", 100); tabMENU.add(chkSing);

        chkSecSing = new FlxUICheckBox(25, 100, null, null, "Change Section Characters?", 200);
        chkSecSing.checked = song_edit.sectionStrums[curStrum].notes[curSection].changeSing;
        tabMENU.add(chkSecSing);
		
        MENU.showTabId("Characters");
	}

	
    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>){
        if(id == FlxUICheckBox.CLICK_EVENT){
            var check:FlxUICheckBox = cast sender;
			var wname = check.getLabel().text;
			switch(wname){
                case "Sing?":{
                    if(song_edit.sectionStrums[curStrum] == null){return;}
                    if(check.checked){
                        if(song_edit.sectionStrums[curStrum].notes[curSection] != null && song_edit.sectionStrums[curStrum].notes[curSection].changeSing){
                            if(song_edit.sectionStrums[curStrum].notes[curSection].charToSing.contains(curCharacter)){return;}
                            song_edit.sectionStrums[curStrum].notes[curSection].charToSing.push(curCharacter); 
                        }else{
                            if(song_edit.sectionStrums[curStrum].charToSing.contains(curCharacter)){return;}
                            song_edit.sectionStrums[curStrum].charToSing.push(curCharacter);   
                        }
                    }else{
                        if(song_edit.sectionStrums[curStrum].notes[curSection] != null && song_edit.sectionStrums[curStrum].notes[curSection].changeSing){
                            if(!song_edit.sectionStrums[curStrum].notes[curSection].charToSing.contains(curCharacter)){return;}
                            song_edit.sectionStrums[curStrum].notes[curSection].charToSing.remove(curCharacter);
                        }else{
                            if(!song_edit.sectionStrums[curStrum].charToSing.contains(curCharacter)){return;}
                            song_edit.sectionStrums[curStrum].charToSing.remove(curCharacter);
                        }
                    }
                }
                case "Change Section Characters?":{
                    if(song_edit.sectionStrums[curStrum] == null){return;}
                    if(song_edit.sectionStrums[curStrum].notes[curSection] == null){return;}
                    song_edit.sectionStrums[curStrum].notes[curSection].changeSing = check.checked;
                    changeCharacter();
                }
			}
		}
	}
}
