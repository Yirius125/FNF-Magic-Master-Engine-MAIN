package;

import flixel.util.*;
import flixel.addons.ui.*;
import flixel.addons.ui.interfaces.*;

import flixel.addons.ui.interfaces.IResizable;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import flixel.addons.ui.FlxUIGroup;
import haxe.format.JsonParser;
import flixel.tweens.FlxTween;
import states.MusicBeatState;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import haxe.DynamicAccess;
import sys.thread.Thread;
import flixel.FlxSprite;
import flixel.ui.FlxBar;
import flixel.FlxObject;
import states.PlayState;
import flixel.FlxG;
import haxe.Timer;
import haxe.Json;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

import Note.Note_Animation_Data;
import Note.Note_Graphic_Data;
import Note.ShaderColorSwap;
import Alphabet.PopUpScore;
import Song.SwagSection;
import Note.NoteSplash;
import Note.StrumNote;
import Song.SwagStrum;
import Note.NoteData;
import Note.Note;
import Controls;
import Script;

using SavedFiles;
using StringTools;

class StaticNotes extends FlxUIGroup {
    public var genWidth:Int = 160;
    public var genHeight(get, never):Int;
	inline function get_genHeight():Int{return Std.int(genWidth / keyNum);}

    public var keyNum:Int = 4;
    
    public var statics:Array<StrumNote> = [];

    public var image:String = StrumNote.IMAGE_DEFAULT;
    public var style:String = StrumNote.STYLE_DEFAULT;
    public var type:String = StrumNote.TYPE_DEFAULT;

    public function new(X:Float, Y:Float, ?_keys:Int, ?_size:Int, ?_image:String, ?_style:String, ?_type:String){
        if(_image != null){this.image = _image;}
        if(_style != null){this.style = _style;}
        if(_type != null){this.type = _type;}
        if(_keys != null){this.keyNum = _keys;}
        if(_size != null){this.genWidth = _size;}
        super(X, Y);
                        
        changeKeyNumber(keyNum, genWidth, true, true);
    }
    
    public function playById(id:Int, anim:String, force:Bool = false){
        var curStrum:StrumNote = statics[id];
        if(curStrum == null){return;}
        curStrum.playAnim(anim, force);
    }

    public function setGraphicToNotes(?_image:String, ?_style:String, ?_type:String){
        if(_image != null){image = _image;} if(_style != null){style = _style;} if(_type != null){type = _type;}

        for(key in statics){key.loadNote(image, style, type);}
    }

    public function changeKeyNumber(_keys:Int, ?_size:Int, ?force:Bool = false, ?skip:Bool = false){
        if((this.keyNum == _keys || _keys <= 0) && !force){return;}
        this.keyNum = _keys;
        
        if(_size != null){this.genWidth = _size;}
        var strumSize:Int = Std.int(genWidth / keyNum);
        
        if(skip){
            while(statics.length > 0){this.remove(statics.shift());}

            for(i in 0...keyNum){
                var strum:StrumNote = new StrumNote(i, keyNum, image, style, type);
                strum.note_size.set(strumSize, strumSize);
                strum.playAnim('idle');
                strum.x += strumSize * i;
                strum.ID = i;
                add(strum);
                statics.push(strum);
            }
        }else{
            if(statics.length > 0){
                for(i in 0...statics.length){
                    var strum:StrumNote = statics.shift();
                    strum.onDebug = true;

                    FlxTween.tween(strum, {alpha: 0, y: strum.y + (strum.height / 2)}, (0.5 * (i + 1) / statics.length), {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween){
                        this.members.remove(strum);
                        strum.destroy();
                    }});
                }
            }
            
            for(i in 0...keyNum){
                var strum:StrumNote = new StrumNote(i, keyNum, image, style, type);
                strum.note_size.set(strumSize, strumSize);
                strum.playAnim('idle');
                strum.x += strumSize * i;
                strum.y -= strumSize / 2;
                strum.alpha = 0;
                strum.ID = i;

                add(strum);
                statics.push(strum);

                FlxTween.tween(strum, {alpha: 1, y: 0}, (0.5 * (i + 1) / keyNum), {ease: FlxEase.quadInOut});
            }
        }
    }
}

typedef StrumLine_Graphic_Data = {
    var static_notes:Strums_Data;
    var gameplay_notes:Strums_Data;
}
typedef Strums_Data = {
    var general_animations:Array<Note_Animation_Data>;
    var notes:Array<Note_Graphic_Data>;
}

class StrumLine extends FlxTypedGroup<Dynamic> {
    public static var GLOBAL_VARIABLES:Dynamic = {};
    public var LOCAL_VARIABLES:Dynamic = {};

    // STRUM OBJECTS
    public var staticnotes:StaticNotes;

    public var x(get, set):Float;
    inline public function get_x(){return staticnotes.x;}
    inline public function set_x(x){return staticnotes.x = x;}

    public var y(get, set):Float;
    inline public function get_y(){return staticnotes.y;}
    inline public function set_y(y){return staticnotes.y = y;}

    public var alpha(get, set):Float;
    inline public function get_alpha(){return staticnotes.alpha;}
    inline public function set_alpha(alpha){return staticnotes.alpha = alpha;}

    public var key_number(get, never):Int; inline function get_key_number():Int{return staticnotes.keyNum;}
    public var genWidth(get, never):Int; inline function get_genWidth():Int{return staticnotes.genWidth;}
    public var genHeight(get, never):Int; inline function get_genHeight():Int{return staticnotes.genHeight;}
    public var image(get, never):String; inline function get_image():String{return staticnotes.image;}
    public var style(get, never):String; inline function get_style():String{return staticnotes.style;}
    public var type(get, never):String; inline function get_type():String{return staticnotes.type;}

    public var holdNotes:Array<Note> = [];
    public var notelist:Array<Note> = [];
    public var notes:FlxTypedGroup<Note>;

    //OBJECT VARIABLES
	public var healthBar:FlxBar;
	public var leftIcon:HealthIcon;
	public var rightIcon:HealthIcon;
	public var sprite_healthBar:FlxSprite;
	public var lblStats:FlxText;

    // STRUMLINE VARIABLES
    public var isPlayer(get, never):Bool;
    public function get_isPlayer():Bool {
        if(!(MusicBeatState.state is PlayState)){return false;}
        var curState:PlayState = cast MusicBeatState.state;
        for(p in PlayState.strum_players){
            if(this != curState.strumsGroup.members[p.strum]){continue;}
            return true;
        }

        return false;
    }

    public var typeStrum:String = "BotPlay"; //BotPlay, Playing, Charting, 

    // NOTE EVENTS
    public dynamic function onHIT(_note:Note):Void {};
    public dynamic function onMISS(_note:Note):Void {}
    public dynamic function onRANK(_note:Note, _score:Float, _rank:String, _pop_image:String):Void {
        if(PreSettings.getPreSetting("Type Splash", "Visual Settings") == "OnSick" && _score >= 350){splashNote(_note);}
        var cur_character = LOCAL_VARIABLES.Player;
        if(cur_character == null){return;}

        if(tween_icon != null){tween_icon.cancel();} rankIcon.revive();
        rankIcon.loadGraphic(Paths.styleImage(_pop_image, ui_style).getGraphic());
        rankIcon.scale.set(0.7, 0.7); rankIcon.updateHitbox(); rankIcon.alpha = 1;
        rankIcon.setPosition(cur_character.c.getGraphicMidpoint().x, cur_character.c.getGraphicMidpoint().y);
        tween_icon = FlxTween.tween(rankIcon, {y: rankIcon.y - 25, alpha: 0}, 0.5, {ease:FlxEase.quadOut, onComplete: function(twn){rankIcon.kill();}});
    }
    public dynamic function onGAME_OVER():Void {}
    public dynamic function update_hud():Void {}
    public dynamic function onLIFE(value:Float){
        if(PreSettings.getPreSetting("Type Mode", "Cheating Settings") == "Practice"){return;}

        HEALTH += value;
        
        if(HEALTH > MAXHEALTH){HEALTH = MAXHEALTH;}
        if(HEALTH <= 0){  
            HEALTH = 0;
            if(onGAME_OVER != null){onGAME_OVER();}
        }
    };

    // STATS VARIABLES    
    public static var P_STAT:Array<{rank:String, popup:String, score:Int, diff:Int}> = [
        {rank:"PERFECT", popup:"perfect", score:400, diff:0},
        {rank:"SICK", popup:"sick", score:350, diff:45},
        {rank:"GOOD", popup:"good", score:200, diff:90},
        {rank:"BAD", popup:"bad", score:100, diff:135},
        {rank:"._.", popup:"shit", score:50, diff:200},
    ];
    
    public var STATS:Dynamic = {
        TotalNotes: 0,
		Record: 0,
		Score: 0,
		Combo: 0,
		MaxCombo: 0,
		Hits: 0,
		Misses: 0,
        Percent: 0,
		Rating: "MAGIC"
    };

    public static var RATING:Array<Dynamic> = [
        {percent: 1.0, rate:"MAGIC!!"},
        {percent: 0.9, rate:"Sick!!"},
        {percent: 0.8, rate:"Great"},
        {percent: 0.7, rate:"Cool"},
        {percent: 0.6, rate:"Good"},
        {percent: 0.5, rate:"Bad"},
        {percent: 0.4, rate:"Shit"},
        {percent: 0.3, rate:"._."}
	];

    // SONG VARIABLES
    public var ui_style:String = "Default";
    public var swagStrum:SwagStrum = null;
    public var strumConductor:Conductor = null;
    public var curSection(get, never):Int;
	inline function get_curSection():Int{return Std.int(strumConductor.getCurStep() / 16);}

    public var scrollSpeed:Float = 1;
    public var bpm:Float = 150;

    public var HEALTH:Float = 1;
    public var MAXHEALTH:Float = 2;

    public var strumGenerated:Bool = false;

    // CONTROLS VARIABLES
    public var controls:Controls;
    public var disableArray:Array<Bool> = [];
    public var pressArray:Array<Bool> = [];
    public var releaseArray:Array<Bool> = [];
    public var holdArray:Array<Bool> = [];

    public var rankIcon:FlxSprite;
    public var splashIcon:NoteSplash;
    public var tween_icon:FlxTween;
    
	//Other Variables
	public var pre_TypeScroll:String = PreSettings.getPreSetting("Type Scroll", "Visual Settings");
    public var destroyNotes:Bool = true;
    
    public function new(X:Float, Y:Float, ?_keys:Int, ?_size:Int, ?_controls:Controls, ?_image:String, ?_style:String, ?_type:String){
        this.controls = _controls;
        super();

        staticnotes = new StaticNotes(X, Y, _keys, _size, _image, _style, _type);
        add(staticnotes);

        notes = new FlxTypedGroup<Note>();
        add(notes);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

        changeTypeStrum(typeStrum);

        rankIcon = new FlxSprite();
        rankIcon.cameras = [FlxG.camera];
        add(rankIcon);
        rankIcon.kill();
        
        splashIcon = new NoteSplash();
        add(splashIcon);
        splashIcon.kill();

        if(controls != null){controls.setKeyData(_keys);}
    }

    public function load_solo_ui():Void {
        update_hud = function(){
            if(STATS.Combo > STATS.MaxCombo){STATS.MaxCombo = STATS.Combo;}
            if(STATS.Score > STATS.Record){STATS.Record = STATS.Score;}

            if(healthBar != null){
                healthBar.x = staticnotes.x;
                if(!healthBar.flipX){healthBar.x = staticnotes.x + staticnotes.genWidth - healthBar.width;}

                var _player:Character = LOCAL_VARIABLES.Player;
                if(_player != null){
                    healthBar.flipX = _player.onRight;

                    if(leftIcon != null){
                        var _char_left:Character = LOCAL_VARIABLES.Player;
                        if(_char_left != null && leftIcon.curIcon != _char_left.healthIcon){leftIcon.setIcon(_char_left.healthIcon); leftIcon.visible = true;}
                                    
                        leftIcon.flipX = !_player.onRight;
                        leftIcon.x = sprite_healthBar.x - (leftIcon.width / 2);
                        if(leftIcon.flipX){leftIcon.x = sprite_healthBar.x + sprite_healthBar.width - (leftIcon.width / 2);}

                        leftIcon.playAnim(HEALTH < 0.8 ? 'losing' : 'default');		
                    }
                }
            }
            if(sprite_healthBar != null){
                sprite_healthBar.x = healthBar.x;
                sprite_healthBar.flipX = !healthBar.flipX;
            }
    
            if(lblStats != null){
                lblStats.x = staticnotes.x;
                
                if(LOCAL_VARIABLES.GameOver){lblStats.text = '|| You Died ||';}
                else{lblStats.text = getInfo(true);}
            }
        }

		var cont:Array<Bool> = []; for(s in MusicBeatState.state.scripts){cont.push(s.exFunction('load_solo_ui', [this, this.ID]));}
		if(cont.contains(true)){return; trace("RETURN");}

        if(healthBar == null){
			healthBar = new FlxBar(x, pre_TypeScroll == "DownScroll" ? 52 : 663, RIGHT_TO_LEFT, 330, 16, this, 'HEALTH', 0, MAXHEALTH);
			healthBar.numDivisions = 500;
			add(healthBar);
		}

		if(sprite_healthBar == null){
			sprite_healthBar = new FlxSprite(x, pre_TypeScroll == "DownScroll" ? 50 : 655).loadGraphic(Paths.styleImage("single_healthBar", ui_style, "shared").getGraphic());
			sprite_healthBar.scale.set(0.7,0.7); sprite_healthBar.updateHitbox();
			add(sprite_healthBar);
		}

		if(leftIcon == null){
			leftIcon = new HealthIcon('tankman');
			leftIcon.setPosition(healthBar.x-(leftIcon.width/2),healthBar.y-(leftIcon.height/2));
			add(leftIcon);
		}

        if(lblStats == null){
			lblStats = new FlxText(x, 0, genWidth, "|| ...Starting Song... ||");
			lblStats.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			lblStats.y = pre_TypeScroll == "DownScroll" ? sprite_healthBar.y + sprite_healthBar.height : FlxG.height - lblStats.height - 5;
			add(lblStats);
		}
    }

    public function load_global_ui():Void {
        update_hud = function(){
            if(STATS.Combo > STATS.MaxCombo){STATS.MaxCombo = STATS.Combo;}
            if(STATS.Score > STATS.Record){STATS.Record = STATS.Score;}

            if(healthBar != null){
                var _player:Character = LOCAL_VARIABLES.Player;
                if(_player != null){
                    healthBar.flipX = _player.onRight;

                    if(leftIcon != null){
                        var _char_left:Character = (_player.onRight ? GLOBAL_VARIABLES.Player : GLOBAL_VARIABLES.Enemy);
                        if(_char_left != null && leftIcon.curIcon != _char_left.healthIcon){leftIcon.setIcon(_char_left.healthIcon); leftIcon.visible = true;}
        
                        leftIcon.y = (healthBar.y + (healthBar.height / 2)) - (leftIcon.height / 2);
                        if(_player.onRight){                        
                            leftIcon.playAnim(HEALTH < (MAXHEALTH * 0.2) ? 'losing': 'default');
                            leftIcon.x = healthBar.x + (healthBar.width - (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))) - leftIcon.width;
                        }else{                        
                            leftIcon.playAnim(HEALTH > (MAXHEALTH * 0.8) ? 'losing': 'default');
                            leftIcon.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - leftIcon.width;
                        }
                    }

                    if(rightIcon != null){
                        var _char_right:Character = (_player.onRight ? GLOBAL_VARIABLES.Enemy : GLOBAL_VARIABLES.Player);
                        if(_char_right != null && rightIcon.curIcon != _char_right.healthIcon){rightIcon.setIcon(_char_right.healthIcon); rightIcon.visible = true;}
    
                        rightIcon.y = (healthBar.y + (healthBar.height / 2)) - (rightIcon.height / 2);
                        if(_player.onRight){
                            rightIcon.playAnim(HEALTH > (MAXHEALTH * 0.8) ? 'losing': 'default');
                            rightIcon.x = healthBar.x + (healthBar.width - (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)));
                        }else{
                            rightIcon.playAnim(HEALTH < (MAXHEALTH * 0.2) ? 'losing': 'default');
                            rightIcon.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01));
                        }
                    }
                }
            }
    
            if(lblStats != null){
                lblStats.text = getInfo();
                lblStats.screenCenter(X);
            }
        }

		var cont:Array<Bool> = []; for(s in MusicBeatState.state.scripts){cont.push(s.exFunction('load_global_ui',[this]));}
		if(cont.contains(true)){trace("RETURN"); return;}

		if(sprite_healthBar == null){
			sprite_healthBar = new FlxSprite(326, pre_TypeScroll == "DownScroll" ? 35 : 655).loadGraphic(Paths.styleImage("healthBar", ui_style, "shared").getGraphic());
			sprite_healthBar.scale.set(0.7,0.7); sprite_healthBar.updateHitbox();
		}

		if(healthBar == null){
			healthBar = new FlxBar(330, pre_TypeScroll == "DownScroll" ? 45 : 664, RIGHT_TO_LEFT, Std.int(FlxG.width / 2) - 20, 16, this, 'HEALTH', 0, MAXHEALTH);
			healthBar.numDivisions = 500;
            healthBar.screenCenter(X);
		}
        
		if(leftIcon == null){
			leftIcon = new HealthIcon('face');
			leftIcon.setPosition(healthBar.x-(leftIcon.width/2),healthBar.y-(leftIcon.height/2));
            leftIcon.visible = false;
		}

		if(rightIcon == null){
			rightIcon = new HealthIcon('face', true);
			rightIcon.setPosition(healthBar.x+healthBar.width-(rightIcon.width/2),healthBar.y-(rightIcon.height/2));
            rightIcon.visible = false;
		}
        
		if(lblStats == null){
			lblStats = new FlxText(0,0,0,"|| ...Starting Song... ||");
			lblStats.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			lblStats.screenCenter(X);
			lblStats.y = pre_TypeScroll == "DownScroll" ? sprite_healthBar.y + sprite_healthBar.height : FlxG.height - lblStats.height - 5;
		}

        add(healthBar);
        add(sprite_healthBar);
        add(leftIcon);
        add(rightIcon);
        add(lblStats);
	}

    public function getInfo(isSingle:Bool = false):String {
        if(isSingle){
            switch(PreSettings.getPreSetting("Type HUD", "Visual Settings")){
                case "Detailed":{
                    return '||'+
                        ' ${LangSupport.getText('gmp_score')}: ${STATS.Score} |' +
                        ' ${LangSupport.getText('gmp_misses')}: ${STATS.Misses} ' +
                    '||';
                }
                case "MagicHUD":{
                    return '||'+
                        ' ${LangSupport.getText('gmp_score')}: ${STATS.Score} |' +
                        ' ${LangSupport.getText('gmp_misses')}: ${STATS.Misses} ' +
                    '||';
                }
                case "Original":{
                    return '||'+
                        ' ${LangSupport.getText('gmp_score')}: ${STATS.Score} |' +
                        ' ${LangSupport.getText('gmp_misses')}: ${STATS.Misses} ' +
                    '||';
                }
                case "Minimized":{
                    return '||'+
                        ' ${LangSupport.getText('gmp_score')}: ${STATS.Score} ' +
                    '||';
                }
                case "OnlyNotes":{
                    return '';
                }
            }
            return '';
        }
        switch(PreSettings.getPreSetting("Type HUD", "Visual Settings")){
            case "Detailed":{
                return '||'+
                    ' ${LangSupport.getText('gmp_score')}: ${STATS.Score} |' +
                    ' ${LangSupport.getText('gmp_record')}: ${STATS.Record} |' +
                    ' ${LangSupport.getText('gmp_combo')}: ${STATS.Combo} |' +
                    ' ${LangSupport.getText('gmp_maxCombo')}: ${STATS.MaxCombo} |' +
                    ' ${LangSupport.getText('gmp_misses')}: ${STATS.Misses} |' +
                    ' ${LangSupport.getText('gmp_hits')}: ${STATS.Hits} |' +
                    ' ${LangSupport.getText('gmp_rating')}: ${STATS.Rating} ' +
                '||';
            }
            case "MagicHUD":{
                return '||'+
                    ' ${LangSupport.getText('gmp_score')}: ${STATS.Score} |' +
                    ' ${LangSupport.getText('gmp_combo')}: ${STATS.Combo} |' +
                    ' ${LangSupport.getText('gmp_misses')}: ${STATS.Misses} |' +
                    ' ${LangSupport.getText('gmp_rating')}: ${STATS.Rating} ' +
                '||';
            }
            case "Original":{
                return '||'+
                    ' ${LangSupport.getText('gmp_score')}: ${STATS.Score} |' +
                    ' ${LangSupport.getText('gmp_misses')}: ${STATS.Misses} ' +
                '||';
            }
            case "Minimized":{
                return '||'+
                    ' ${LangSupport.getText('gmp_score')}: ${STATS.Score} ' +
                '||';
            }
            case "OnlyNotes":{
                return '';
            }
        }
        return '';
    }

    public function changeTypeStrum(_type:String):Void {
        typeStrum = _type;

        switch(typeStrum){
            default:{for(c in staticnotes.statics){c.autoStatic = false;}}
            case 'BotPlay', 'Nothing':{for(c in staticnotes.statics){c.autoStatic = true;}}
        }
    }

    override function destroy() {
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		super.destroy();
	}

    var pressed_keys:Array<FlxKey> = [];
    private function onKeyPress(event:KeyboardEvent):Void {
        if(typeStrum != "Playing" || PreSettings.getPreSetting("Type Mode", "Cheating Settings") == "BotPlay"){return;}
        if(controls.keyboardScheme != Solo){return;}

        var eventKey:FlxKey = event.keyCode;
        var cur_key:Int = controls.getNoteDataFromKey(eventKey);
    
        if(!pressed_keys.contains(eventKey)){pressed_keys.push(eventKey);}
        
        if(cur_key < 0){return;}
        if(holdArray[cur_key]){return;}
        if(disableArray[cur_key]){return;}

        staticnotes.playById(cur_key, "pressed", true);
        
        pressArray[cur_key] = true;
        holdArray[cur_key] = true;
        keyShit();
        pressArray[cur_key] = false;
    }

    private function onKeyRelease(event:KeyboardEvent):Void {
        if(typeStrum != "Playing" || PreSettings.getPreSetting("Type Mode", "Cheating Settings") == "BotPlay"){return;}
        if(controls.keyboardScheme != Solo){return;}
        
        var eventKey:FlxKey = event.keyCode; pressed_keys.remove(eventKey);
        var key:Int = controls.getNoteDataFromKey(eventKey);
    
        if(key < 0 || disableArray[key]){return;}
        
        staticnotes.playById(key, "static", true);
        
        releaseArray[key] = true;
        keyShit();
        holdArray[key] = false;
        releaseArray[key] = false;
    }

    public var daSing:Array<Int> = [];
	public function getToSing(?note:Note):Array<Int> {
		if(note != null && note.singCharacters != null){return note.singCharacters;}
        return daSing;
	}

    public function getStrumSize():Int {return Std.int(genWidth / key_number);}

    public function setGraphicToNotes(?_image:String, ?_style:String, ?_type:String){
        staticnotes.setGraphicToNotes(_image, _style, _type);
        for(n in notelist){n.loadNote(image, style, type);}
    }

    public function changeKeyNumber(_keys:Int, ?_size:Int, ?force:Bool = false, ?skip:Bool = false){
        staticnotes.changeKeyNumber(_keys, _size, force, skip);

        disableArray.resize(key_number);
        pressArray.resize(key_number);
        releaseArray.resize(key_number);
        holdArray.resize(key_number);

        if(controls != null){controls.setKeyData(_keys);}
        for(n in notelist){n.note_size.set(getStrumSize(), getStrumSize());}
    }

    public function loadStrumNotes(swagStrum:SwagStrum){
        var pre_TypeNotes:String = PreSettings.getPreSetting("Note Skin", "Visual Settings");
        this.swagStrum = swagStrum;

        notelist = [];
        for(i in 0...swagStrum.notes.length){
            var sectionInfo:Array<Dynamic> = swagStrum.notes[i].sectionNotes.copy();
            
            for(n in sectionInfo){if(n[1] < 0 || n[1] >= swagStrum.keys){sectionInfo.remove(n);}}

            for(n in sectionInfo){
                var note:NoteData = Note.getNoteData(n);
    
                var swagNote:Note = new Note(note, swagStrum.keys, image, style, type);
                swagNote.note_size.set(getStrumSize(), getStrumSize());
                swagNote.strumParent = this;

                notelist.push(swagNote);
        
                if(note.sustainLength <= 0 || note.multiHits > 0){continue;}

                var cSusNote = Math.floor(note.sustainLength / (strumConductor.stepCrochet * 0.25)) + 2;
        
                var prevSustain:Note = swagNote;
                for(sNote in 0...Math.floor(note.sustainLength / (strumConductor.stepCrochet * 0.25)) + 2){
                    var sStrumTime = note.strumTime + (strumConductor.stepCrochet / 2) + ((strumConductor.stepCrochet * 0.25) * sNote);
                    var nSData:NoteData = Note.getNoteData(Note.convNoteData(note));
                    nSData.strumTime = sStrumTime;
        
                    var nSustain:Note = new Note(nSData, key_number, image, style, type);
                    nSustain.note_size.set(getStrumSize(), getStrumSize());
        
                    nSustain.typeNote = "Sustain";
                    nSustain.typeHit = "Hold";
                    prevSustain.nextNote = nSustain;
                        
                    notelist.push(nSustain);
        
                    prevSustain = nSustain;
                    cSusNote--;
                }

                var lastNote:Note = swagNote; while(lastNote.nextNote != null){lastNote = lastNote.nextNote;}
            }
        }

        notelist.sort(function(a, b){
            if(a.strumTime < b.strumTime){return -1;}
            else if(a.strumTime > b.strumTime){return 1;}
            else if(a.noteData < b.noteData){return -1;}
            else if(a.noteData > b.noteData){return 1;}
            else {return 0;}
        });
    
        daSing = swagStrum.charToSing;

        if(notelist.length > 0){onRANK(notelist[0], 900, "sick", "sick");}

        strumGenerated = true;
    }

    var pre_TypeStrums:String = PreSettings.getPreSetting("Type Light Strums", "Visual Settings");
    override function update(elapsed:Float){
		super.update(elapsed);

        if(swagStrum.notes[curSection] != null && swagStrum.notes[curSection].changeSing){
            daSing = swagStrum.notes[curSection].charToSing;
        }

        for(i in 0...staticnotes.members.length){
            if(!staticnotes.members[i].animation.finished){continue;}
            if(staticnotes.members[i].animation.curAnim.name == 'static'){continue;}
            if(holdArray[i]){continue;}
            staticnotes.playById(i, "static", true);
        }
        
        if(update_hud != null){update_hud();}

        if(notelist[0] != null){
            if(notelist[0].strumTime - strumConductor.songPosition < 3500){
				notes.insert(0, notelist.shift());
            }
        }

        if(!strumGenerated){return;}

        notes.forEachAlive(function(daNote:Note){
            if(daNote.strumTime <= strumConductor.songPosition && (daNote.typeHit == "Ghost" || daNote.typeHit == "Always")){hitNOTE(daNote); return;}
            if(!daNote.customInput){
                if(daNote.strumTime < strumConductor.songPosition + (Conductor.safeZoneOffset * 0.5)){daNote.noteStatus = "CanBeHit";}
                if(strumConductor.songPosition > daNote.strumTime + (350 / getScrollSpeed()) && daNote.noteStatus != "Pressed"){missNOTE(daNote); return;}
            }
            
            if(daNote.customChart){return;}

            daNote.visible = false;
            var noteStrum:StrumNote = staticnotes.statics[daNote.noteData];
            if(noteStrum == null){return;}

            var yStuff:Float = noteStrum.y - getScroll(daNote);
            if(pre_TypeScroll == "DownScroll"){yStuff = noteStrum.y + getScroll(daNote);}

            switch(daNote.noteStatus){
                default:{daNote.y = yStuff;}
                case "MultiTap":{
                    var radio:Float = (strumConductor.songPosition - daNote.prevStrumTime) * 1 / daNote.noteLength;
                    radio = Math.min(1, radio); radio = Math.max(0, radio);

                    daNote.y = FlxMath.lerp(daNote.y, yStuff, radio);
                }
            }

            daNote.visible = noteStrum.visible;

            if(daNote.typeNote == "Switch"){
                daNote.x = noteStrum.x + (noteStrum.width / 2);
                daNote.alpha = noteStrum.alpha * 0.8;
            }else{
                daNote.x = noteStrum.x;
                daNote.alpha = noteStrum.alpha;
                daNote.angle = noteStrum.angle;
                if(daNote.typeNote == "Sustain" || daNote.typeNote == "SustainEnd"){
                    daNote.alpha = noteStrum.alpha * 0.5;
                    daNote.angle = 0;
                }
            }
        });
        
        if(typeStrum == "BotPlay" || PreSettings.getPreSetting("Type Mode", "Cheating Settings") == "BotPlay"){
            keyShit();
        }else if(controls.keyboardScheme != Solo){
            pressArray = controls.getStrumCheckers(key_number, JUST_PRESSED);
            releaseArray = controls.getStrumCheckers(key_number, JUST_RELEASED);
            holdArray = controls.getStrumCheckers(key_number, PRESSED);

            for(i in 0...pressArray.length){if(!pressArray[i]){continue;} staticnotes.playById(i, "pressed", true);}
            for(i in 0...releaseArray.length){if(!releaseArray[i]){continue;} staticnotes.playById(i, "static", true);}
        
            keyShit();
        }

        for(holdnote in holdNotes){
            if(holdnote.typeHit != "Hold"){holdNotes.remove(holdnote); continue;}
            if(!holdArray[holdnote.noteData]){continue;}
            if(holdnote.noteStatus != "CanBeHit" || (holdnote.noteStatus == "CanBeHit" && !holdArray[holdnote.noteData])){continue;}
            hitNOTE(holdnote);
        }

        //PERCENT = Math.min(1, Math.max(0, TNOTES / HITS));
        //for(k in RATING.keys()){if(PERCENT <= k){RATE = RATING.get(k);}}
	}

    public function getScroll(daNote:Note):Float {return 0.45 * (strumConductor.songPosition - daNote.strumTime) * getScrollSpeed();}

    private function keyShit():Void{
        if(typeStrum == "BotPlay" || PreSettings.getPreSetting("Type Mode", "Cheating Settings") == "BotPlay"){
            notes.forEachAlive(function(daNote:Note){
                if(daNote.strumTime <= strumConductor.songPosition && !daNote.hitMiss && daNote.noteStatus == "CanBeHit"){
                    hitNOTE(daNote);
                }
            });
        }else if(typeStrum == "Nothing"){}else{
            notes.forEachAlive(function(daNote:Note){
                if(daNote.noteStatus == "CanBeHit" &&
                    (
                        (daNote.typeHit == "Press" && pressArray[daNote.noteData]) ||
                        (daNote.typeHit == "Release" && releaseArray[daNote.noteData])
                    )
                ){
                    hitNOTE(daNote);
                }
            });
        }
    }

    public function hitNOTE(daNote:Note) {
        daNote.noteStatus = "Pressed";

        if((pre_TypeStrums == "All" || pre_TypeStrums == "OnlyOtherStrums") && daNote.typeHit != "Ghost"){
            staticnotes.playById(daNote.noteData, "confirm", true);
        }

        daNote.execute_events("OnHit");
        
        if(daNote.hitMiss){missNOTE(daNote); return;}
        
        if(daNote.typeNote == "Sustain"){daNote.hitHealth *= 0.25;}

        if(daNote.noteHits > 0){
            daNote.noteStatus = "MultiTap";
            daNote.prevStrumTime = daNote.strumTime;
            daNote.strumTime += daNote.noteLength;            
            daNote.noteHits--;
        }

        if(daNote.typeHit != "Ghost"){
            onLIFE(daNote.hitHealth * PreSettings.getPreSetting("Healing Multiplier", "Cheating Settings"));

            rankNote(daNote);
            if(onHIT != null){onHIT(daNote);}
        }

        if(daNote.nextNote != null && daNote.nextNote.typeHit == "Hold"){holdNotes.push(daNote.nextNote);}

        if((daNote.noteStatus != "MultiTap" && daNote.noteHits <= 0) || (daNote.noteHits < 0 && daNote.noteStatus == "MultiTap")){
            daNote.kill();
            holdNotes.remove(daNote);
            if(destroyNotes){
                notes.remove(daNote, true);
                daNote.destroy();
            }
        }
    }

    public function missNOTE(daNote:Note) {
        if(typeStrum == 'Practice'){return;}

        if(daNote.typeNote == "Sustain"){daNote.missHealth *= 0.25;}
        if(daNote.noteHits > 0){daNote.missHealth *= daNote.noteHits + 1;}
        
        daNote.execute_events("OnMiss");
        
        if(daNote.ignoreMiss && !daNote.hitMiss){
            daNote.kill();
            holdNotes.remove(daNote);
            if(destroyNotes){
                notes.remove(daNote, true);
                daNote.destroy();
            }
            
            return;
        }

        if(daNote.typeNote != "Sustain"){
            if(PreSettings.getPreSetting("Miss Sounds", "Game Settings")){FlxG.sound.play(Paths.styleSound('missnote${FlxG.random.int(1,3)}', states.PlayState.SONG.uiStyle).getSound(), 0.4);}
            onLIFE(-daNote.missHealth * PreSettings.getPreSetting("Damage Multiplier", "Cheating Settings"));
            STATS.Misses += 1 + daNote.noteHits;
        }

        STATS.TotalNotes++;
        STATS.Score -= 100;
        STATS.Combo = 0;

        if(onMISS != null){onMISS(daNote);}
        
        if(daNote.nextNote != null){missNOTE(daNote.nextNote);}

        daNote.kill();
        holdNotes.remove(daNote);
        if(destroyNotes){
            notes.remove(daNote, true);
            daNote.destroy();
        }
    }

    public function rankNote(daNote:Note){
        if(typeStrum == 'BotPlay' || daNote.typeNote == "Sustain"){return;}
        
        STATS.TotalNotes++;
        STATS.Hits++;
        STATS.Combo++;

        var diff_rate:Float = Math.abs(daNote.strumTime - strumConductor.songPosition);
        
        var _score:Int = 0;
        var _rate:String = "MAGIC!!!";
        var _popImage:String = "good";

        for(r in P_STAT){
            if(diff_rate > r.diff){continue;}
            _popImage = r.popup;
            _score = r.score;
            _rate = r.rank;
            break;
        }

        STATS.Percent = STATS.Hits / STATS.TotalNotes;
        for(rt in RATING){
            if(rt.percent > STATS.Percent){continue;}
            STATS.Rating = rt.rate;
            break;
        }

        STATS.Score += _score;

        if(onRANK != null){onRANK(daNote, _score, _rate, _popImage);}
    }

    public function splashNote(daNote:Note):Void {
        var cur_data:Int =  daNote.noteData % key_number;

        var cur_strum:StrumNote = staticnotes.statics[cur_data];
        if(cur_strum == null){return;}

        splashIcon.revive();
        splashIcon.setupByNote(daNote, cur_strum);
        splashIcon.onSplashed = function(){splashIcon.kill();}
    }

    public function getScrollSpeed():Float{
        var pre_TypeScrollSpeed:String = PreSettings.getPreSetting("Scroll Speed Type", "Game Settings");
        var pre_ScrollSpeed:Float = PreSettings.getPreSetting("ScrollSpeed", "Game Settings");
        var pre_NoteOffset:Float = PreSettings.getPreSetting("Note Offset", "Game Settings");

        switch(pre_TypeScrollSpeed){
            case "Scale":{return (scrollSpeed * pre_ScrollSpeed) + pre_NoteOffset;}
            case "Force":{return pre_ScrollSpeed + pre_NoteOffset;}
            default:{return scrollSpeed + pre_NoteOffset;}
        }
    }
}