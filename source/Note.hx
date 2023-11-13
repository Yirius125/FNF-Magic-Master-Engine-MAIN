package;

import flixel.util.*;
import flixel.addons.ui.*;
import flixel.addons.ui.interfaces.*;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxShader;
import haxe.format.JsonParser;
import flixel.tweens.FlxTween;
import states.MusicBeatState;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import haxe.DynamicAccess;
import flixel.FlxSprite;
import flixel.FlxG;
import haxe.Json;

import FlxCustom.FlxCustomShader;
import Song.SwagSection;
import Song.SwagStrum;
import Script;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
using SavedFiles;

typedef Note_Graphic_Data = {
    var animations:Array<Note_Animation_Data>;
    var antialiasing:Bool;
    var sing_animation:String;
    var color:String;
}

typedef Note_Animation_Data = {
    var anim:String;
    var symbol:String;
    var indices:Array<Int>;

    var fps:Int;
    var loop:Bool;
}

class StrumNote extends FlxSprite {
    public static var IMAGE_DEFAULT:String = "NOTE_assets";
    public static var STYLE_DEFAULT:String = "Default";
    public static var DRAW_SHADER:Bool = true;

    public static var TYPE_DEFAULT(get, never):String;
	inline static function get_TYPE_DEFAULT():String {return PreSettings.getPreSetting("Note Skin", "Visual Settings");}

    public static var global_suffix:String = "";
    public static var global_prefix:String = "";

    public var splashImage:String = NoteSplash.IMAGE_DEFAULT;
    public var image:String = IMAGE_DEFAULT;
    public var style:String = STYLE_DEFAULT;
    public var type:String = TYPE_DEFAULT;

    public var noteData:Int = 0;
    public var noteKeys:Int = 4;
    
    public var disableColor(default, set):Bool = false;
    public function set_disableColor(value:Bool):Bool {
        shader = value ? ShaderColorSwap.get_shader(note_path.getColorNote(), playColor) : null;        
        return disableColor = value;
    }

    public var playColor:FlxColor;

    public var singAnimation:String = null;

    public var onDebug:Bool = false;
    public var autoStatic:Bool = false;

    public var note_size:FlxPoint = new FlxPoint(60, 60);

    public var note_path:String = "";

	public function new(_data:Int = 0, _keys:Int = 4, ?_image:String, ?_style:String, ?_type:String){
        if(_image != null){image = _image;}
        if(_style != null){style = _style;}
        if(_type != null){type = _type;}
        this.noteData = _data;
        this.noteKeys = _keys;
        super();

        loadNote();
	}

    public function setupData(_data:Int, ?_keys:Int){
        if(_keys != null){noteKeys = _keys;}
        noteData = _data;
        loadNote();
    }

    public function loadNote(?_image:String, ?_style:String, ?_type:String){
        var sAnim:String = (this.animation != null && this.animation.curAnim != null) ? this.animation.curAnim.name : "static";
        if(_image != null){image = _image;} if(_style != null){style = _style;} if(_type != null){type = _type;}

        note_path = Paths.note(image, style, type);

        frames = note_path.getAtlas();
        var n_json:Note_Graphic_Data = (this is Note) ? SavedFiles.getDataNote(noteData, noteKeys, type) : SavedFiles.getDataStaticNote(noteData, noteKeys, type);
        
        playColor = disableColor ? 0xffffff : (n_json.color != null ? FlxColor.fromString(n_json.color) : 0xffffff);  
        antialiasing = n_json.antialiasing && !style.contains("pxl-");
        singAnimation = n_json.sing_animation;

        shader = null;
        if(StrumNote.DRAW_SHADER && !disableColor){shader = ShaderColorSwap.get_shader(note_path.getColorNote(), playColor);}

        if(frames == null || n_json.animations == null || n_json.animations.length <= 0){return;}

        for(anim in n_json.animations){
            if(anim.indices != null && anim.indices.length > 0){animation.addByIndices(anim.anim, anim.symbol, anim.indices, "", anim.fps, anim.loop);}
            else{animation.addByPrefix(anim.anim, anim.symbol, anim.fps, anim.loop);}
        }

        playAnim(sAnim);
    }
    public function addAnim(anim:String, symbol:String, fps:Int, loop:Bool):Void {
        animation.addByPrefix(anim, symbol, fps, loop);
    }

    override function update(elapsed:Float){
		super.update(elapsed);

        if(animation != null && animation.curAnim != null && animation.finished && animation.curAnim.name != "static" && autoStatic){playAnim('static');}
	}

    public function playAnim(anim:String, force:Bool = false){
		animation.play(global_prefix + anim + global_suffix, force);
        setGraphicSize(Std.int(note_size.x), Std.int(note_size.y));
	}

    override public function setGraphicSize(Width:Float = 0, Height:Float = 0):Void {
        super.setGraphicSize(Width, Height);
        this.updateHitbox();
    }
}

typedef NoteData = {
    var strumTime:Float;
    var keyData:Int;
    var sustainLength:Float;
    var multiHits:Int;
    var preset:String;
    var eventData:Array<Dynamic>;
    var otherStuff:Array<Dynamic>;
}
typedef EventData = {
    var strumTime:Float;
    var eventData:Array<Dynamic>;
    var condition:String;
    var isExternal:Bool;
    var isBroken:Bool;
}

class Note extends StrumNote {
    //Static Methods
    public static function compNotes(n1:Dynamic, n2:Dynamic, checkData:Bool = true, specific:Bool = false):Bool {
        if((n1 != null && n2 != null) && (((n1.strumTime >= n2.strumTime - 10 && n1.strumTime <= n2.strumTime + 10) && (!checkData || (checkData && (n1.keyData == n2.keyData)))) || (specific && (n1 == n2)))){return true;}
        return false;
    }

    public static function getNoteStyles(?type:String):Array<String> {
        if(type == null){type = PreSettings.getPreSetting("Note Skin", "Visual Settings");}

        var toReturn:Array<String> = [];
        for(i in Paths.readDirectory('assets/notes/$type')){
            if(i.contains(".")){continue;}
            toReturn.push(i.split("/").pop());
        }

        return toReturn;
    }
    public static function getNotePressets():Array<String> {
        var toReturn:Array<String> = ["Default"];
        for(i in Paths.readDirectory('assets/notes')){
            if(!i.endsWith(".json")){continue;}
            toReturn.push(i.split("/").pop().replace(".json", ""));
        }

        return toReturn;
    }
    public static function getNoteEvents(isNote:Bool = false, ?stage:String):Array<String> {
        var toReturn:Array<String> = [];

        for(i in Paths.readDirectory('assets/data/events')){
            if(!i.endsWith(".hx")){continue;}
            toReturn.push(i.split("/").pop().replace(".hx",""));
        }
        
        if(isNote){
            for(i in Paths.readDirectory('assets/data/note_events')){
                if(!i.endsWith(".hx")){continue;}
                toReturn.push(i.split("/").pop().replace(".hx",""));
            }
        }

        if(stage != null){
            for(i in Paths.readDirectory('assets/stages/${stage}/events')){
                if(!i.endsWith(".hx")){continue;}
                toReturn.push(i.split("/").pop().replace(".hx", ""));
            }
        }        

        return toReturn;
    }

    public static function set_note(n1:Array<Dynamic>, n2:Array<Dynamic>):Void {
        if(!(n1 is Array) || !(n2 is Array)){return;}
        for(i in 0...n2.length){
            if(n1.length <= i){
                n1.push(n2[i]);
            }else{
                n1[i] = n2[i];
            }
        }
    }
    
    public static function convNoteData(data:NoteData):Array<Dynamic> {
        if(data == null){return null;}
        return [data.strumTime, data.keyData, data.sustainLength, data.multiHits, data.preset, data.eventData, data.otherStuff];
    }
    public static function convEventData(data:EventData):Array<Dynamic> {
        if(data == null){return null;}
        return [data.strumTime, data.eventData, data.condition, data.isExternal, data.isBroken];
    }
    
    public static function getNoteData(?note:Array<Dynamic>):NoteData {
        var toReturn:NoteData = {
            strumTime: -100,
            keyData: 0,
            sustainLength: 0,
            multiHits: 0,
            preset: "Default",
            eventData: [],
            otherStuff: []
        }

        if(note == null){return toReturn;}

        if(note.length >= 0 && Std.isOfType(note[0], Float)){toReturn.strumTime = note[0];}
        if(note.length >= 1 && Std.isOfType(note[1], Int)){toReturn.keyData = note[1];}    
        if(note.length >= 2 && Std.isOfType(note[2], Float)){toReturn.sustainLength = note[2];}      
        if(note.length >= 3 && Std.isOfType(note[3], Int)){toReturn.multiHits = note[3];}
        if(note.length >= 4 && Std.isOfType(note[4], String)){toReturn.preset = note[4];}
        if(note.length >= 5 && Std.isOfType(note[5], Array)){toReturn.eventData = note[5];}
        if(note.length >= 6 && Std.isOfType(note[6], Array)){toReturn.otherStuff = note[6];}
        
        return toReturn;
    }

    public static function getEventData(?event:Array<Dynamic>):EventData {
        var toReturn:EventData = {
            strumTime: -1,
            eventData: [],
            condition: "OnHit",
            isExternal: false,
            isBroken: false
        }

        if(event == null){return toReturn;}

        if(event.length >= 0 && Std.isOfType(event[0], Float)){toReturn.strumTime = event[0];}
        if(event.length >= 1 && Std.isOfType(event[1], Array)){
            for(e in cast(event[1],Array<Dynamic>)){
                if(e.length <= 1){e = [e[0], []];}
                if(!Std.isOfType(e[0], String)){e[0] = "None";}
                if(!Std.isOfType(e[1], Array)){
                    var new_event_data:Array<Dynamic> = [e[1]];
                    if(e.length > 2){
                        for(i in 2...cast(e,Array<Dynamic>).length){
                            new_event_data.push(e[i]);
                            e.remove(e[i]);
                        }
                    }
                    e[1] = new_event_data;
                }
            }
            toReturn.eventData = event[1];

        }
        if(event.length >= 2 && Std.isOfType(event[2], String)){toReturn.condition = event[2];}
        if(event.length >= 3 && event[3]){toReturn.isExternal = true;}
        if(event.length >= 4 && event[4]){toReturn.isBroken = true;}

        return toReturn;
    }

    public static function getScript(key:String):Script {
        var curScript:Script = Script.getScript(key);
        if(curScript == null){MusicBeatState.state.pushTempScript(key);}
        curScript = Script.getScript(key);
        return curScript;
    }
    
    public static var defaultHitHealth:Float = 0.023;
    public static var defaultMissHealth:Float = 0.0475;

    //General Variables
    public var strumParent:StrumLine = null;
    public var prevNote:Note = null;
    public var nextNote(default, set):Note = null;
    public function set_nextNote(value:Note):Note {
        value.prevNote = this;
        return nextNote = value;
    }

    public var prevStrumTime:Float = 0;
    public var strumTime:Float = 0;
    //public var noteData:Int = 0; //Now on StrumNote
    public var noteLength:Float = 0;
    public var noteHits:Int = 0; // Determinate if MultiTap o Sustain

    public var typeNote:String = "Normal"; // [Normal, Sustain, Merge] CurNormal Types
    public var typeHit:String = "Press"; // [Press | Normal Hits] [Hold | Hold Hits] [Release | Release Hits] [Always | Just Hit] [Ghost | Just Hit Withowt Strum Anim] [None | Can't Hit]
    public var hitMiss:Bool = false;
    public var ignoreMiss:Bool = false;
    
    public var customChart:Bool = false;
    public var customInput:Bool = false;
    public var customAnim:Bool = false;

	public var otherData:Array<Dynamic> = [];
    public var typePreset:String = "Default";

    //Other Variables
    public var noteStatus:String = "Spawned"; //status: Spawned, CanBeHit, Pressed, Late, MultiTap
    public var hitHealth:Float = 0.023;
    public var missHealth:Float = 0.0475;

    public var singCharacters:Array<Int> = null;
    
	//PreSettings Variables
	public var pre_TypeScroll:String = ((states.MusicBeatState.state is states.editors.ChartEditorState)) ? "UpScroll" : PreSettings.getPreSetting("Type Scroll", "Visual Settings");
    
	public function new(data:NoteData, noteKeys:Int, ?_image:String, ?_style:String, ?_type:String){
        if(data.eventData != null){this.otherData = data.eventData;}
        this.noteLength = data.sustainLength;
        this.strumTime = data.strumTime;
        this.noteHits = data.multiHits;

        this.image = _image != null ? _image : this.image;
        this.style = _style != null ? _style : this.style;
        this.type = _type != null ? _type : this.type;

        loadPreset(data.preset, true);
        
        execute_events("OnCreate");

        super(data.keyData, noteKeys, image, style, type);
        
        execute_events("OnCreated");
	}

    public function loadPreset(preset:String, onCreate:Bool = false):Void {
        if(!onCreate && preset == "Default"){otherData = []; loadNote(StrumNote.IMAGE_DEFAULT); return;}
        typePreset = preset;

        var json_path:String = Paths.getPath('${preset}.json', TEXT, 'notes');
        if(preset != "" && Paths.exists(json_path)){
            var eventList:Dynamic = json_path.getJson();
            otherData = eventList.Events;
        }
    }

    public function execute_events(type:String){
        for(event in otherData){
            if(event[2] != type){continue;}
            
            var curScript:Script = Note.getScript(event[0]);
            if(curScript == null){continue;}
            curScript.setVariable("_note", this);
            curScript.exFunction("execute", event[1]);
        }
    }

    override function update(elapsed:Float){
		super.update(elapsed);

        if(customAnim){return;}
        switch(this.typeNote){
            case "Normal":{playAnim("static");}
            case "Sustain":{
                if(this.nextNote != null){playAnim("sustain");}
                else{playAnim("end"); if(pre_TypeScroll == "DownScroll"){flipY = true;}}
            }
            case "Switch":{playAnim("line");}
            case "Merge":{playAnim("merge");}
        }
	}

    override public function playAnim(anim:String, force:Bool = false){
		animation.play(StrumNote.global_prefix + anim + StrumNote.global_suffix, force);

        switch(typeNote){
            default:{
                setGraphicSize(Std.int(note_size.x), Std.int(note_size.y));
            }
            case "Sustain":{
                switch(pre_TypeScroll){
                    default:{
                        if(nextNote != null){
                            switch(nextNote.typeNote){
                                default:{setGraphicSize(Std.int(note_size.x), Std.int(nextNote.y - this.y) + Std.int(nextNote.height / 2));}
                                case "Sustain":{setGraphicSize(Std.int(note_size.x), Std.int(nextNote.y - this.y) + 2);}
                            }                
                        }else{setGraphicSize(Std.int(note_size.x), Std.int(note_size.y / 4));}
                    }
                    case "DownScroll":{
                        if(prevNote != null){
                            switch(prevNote.typeNote){
                                default:{setGraphicSize(Std.int(note_size.x), Std.int(prevNote.y - this.y) + Std.int(prevNote.height / 2));}
                                case "Sustain":{setGraphicSize(Std.int(note_size.x), Std.int(prevNote.y - this.y) + 2);}
                            }                
                        }else{setGraphicSize(Std.int(note_size.x), Std.int(note_size.y / 4));}
                    }
                }
            }
            case "Switch":{
                if((prevNote != null && prevNote.exists) && (nextNote != null && nextNote.exists)){
                    setGraphicSize(FlxMath.distanceBetween(prevNote, nextNote), Std.int(note_size.y));
                    angle = Math.atan2(nextNote.y - prevNote.y, nextNote.x - prevNote.x) * (180.0 / Math.PI);
                }
            }
        }
	}
}

class StrumEvent extends StrumNote {
    public var conductor:Conductor = null;
    public var strumTime:Float = 0;
    public var isExternal:Bool = false;
    public var isBroke:Bool = false;

    public function new(_strumtime:Float, _conductor:Conductor = null, _isExternal:Bool = false, _isBroke:Bool = false){
        this.strumTime = _strumtime;
        this.conductor = _conductor;
        this.isExternal = _isExternal;
        this.isBroke = _isBroke;
        super(-1, 4, isExternal ? "Laptop" : "EventIcon");
        playAnim("BeEvent");
	}

    override public function loadNote(?_image:String, ?_style:String, ?_type:String){
        var sAnim:String = this.animation != null && this.animation.curAnim != null ? this.animation.curAnim.name : "static";
        if(_image != null){image = _image;} if(_style != null){style = _style;} if(_type != null){type = _type;}

        note_path = Paths.note(image, style, type);
        frames = note_path.getAtlas();
            
        antialiasing = !style.contains("pxl-");
        if(frames == null){return;}

        animation.addByPrefix("BeEvent", "BeEvent", 30, false);
        animation.addByPrefix("AfEvent", "AfEvent", 30, false);
        animation.addByPrefix("OffEvent", "OffEvent", 30, false);
        
        playAnim(sAnim);
    }

    var _lastAnim:String = "";
    override function update(elapsed:Float){
		super.update(elapsed);

        if(isExternal && isBroke){
            if(_lastAnim != "OffEvent"){playAnim("OffEvent"); _lastAnim = "OffEvent";}
        }else if(conductor != null && strumTime < conductor.songPosition){
            if(_lastAnim != "AfEvent"){playAnim("AfEvent"); _lastAnim = "AfEvent";}
        }else{
            if(_lastAnim != "BeEvent"){playAnim("BeEvent"); _lastAnim = "BeEvent";}
        }
	}
}

class NoteSplash extends FlxSprite {
    public static var IMAGE_DEFAULT(get, never):String;
    public static function get_IMAGE_DEFAULT(){return Paths.getFileName(PreSettings.getPreSetting("Splash Skin", "Visual Settings"), true);}

    public var onSplashed:Void->Void = function(){};

    public var note_path:String = "";

    public var splash_anims:Array<String> = [];

    public function new(){super();}

    override function update(elapsed:Float){
		super.update(elapsed);

        if(animation.finished){onSplashed();}
	}

    public function setup(X:Float = 0, Y:Float = 0, ?image:String, ?style:String, ?type:String){
        splash_anims = [];

        if(image == null){image = IMAGE_DEFAULT;}
        if(style == null){style = StrumNote.STYLE_DEFAULT;}
        if(type == null){type = StrumNote.TYPE_DEFAULT;}

        this.setPosition(X, Y);

        note_path = Paths.note(image, style, type);
        frames = note_path.getAtlas();
        
        var json_path:String = note_path.replace('${IMAGE_DEFAULT}.png', 'Splash_Anims.json');
        if(Paths.exists(json_path)){
            var anim_list:Array<String> = cast Reflect.getProperty(json_path.getJson(), IMAGE_DEFAULT);
            for(a in anim_list){
                animation.addByPrefix(a, a, 30, false);
                splash_anims.push(a);
            }
        }else{
            animation.addByPrefix("Splash", "Splash", 30, false);
            splash_anims.push("Splash");
        }

        playAnim(splash_anims[FlxG.random.int(0, splash_anims.length - 1)]);
    }

    public function setupByNote(daNote:Note, strumNote:StrumNote):Void {
        splash_anims = [];

        this.setPosition(strumNote.x, strumNote.y);

        note_path = Paths.note(IMAGE_DEFAULT, daNote.style, daNote.type);

        frames = note_path.getAtlas();
        
        var json_path:String = note_path.replace('${IMAGE_DEFAULT}.png', 'Splash_Anims.json');
        if(Paths.exists(json_path)){
            var anim_list:Array<String> = cast Reflect.getProperty(json_path.getJson(), IMAGE_DEFAULT);
            for(a in anim_list){
                animation.addByPrefix(a, a, 30, false);
                splash_anims.push(a);
            }
        }else{
            animation.addByPrefix("Splash", "Splash", 30, false);
            splash_anims.push("Splash");
        }

        if(StrumNote.DRAW_SHADER){shader = ShaderColorSwap.get_shader(note_path.getColorNote(), daNote.playColor);}

        playAnim(splash_anims[FlxG.random.int(0, splash_anims.length - 1)]);
        setGraphicSize(Std.int(daNote.note_size.x), Std.int(daNote.note_size.y));
        updateHitbox();
    }

    public function playAnim(anim:String, ?force:Bool = false){
        animation.play(StrumNote.global_prefix + anim + StrumNote.global_suffix, force);
	}
}

class ShaderColorSwap extends FlxCustomShader {
    public static var shader_list:Array<ShaderColorSwap> = [];

    @:glFragmentHeader('
        uniform int checkColor;
        uniform int typeChange;
        uniform vec3 replaceColor;
        uniform vec3 replaceColor2;
    ')
	@:glFragmentSource("
        #pragma header

        vec4 get_grad(vec3 color1, vec3 color2){
            float normalizedX = openfl_TextureCoordv.x / openfl_TextureSize.x;
            vec3 blendedColor = mix(color1, color2, normalizedX);
            return vec4(blendedColor, 1.0);
        }

        vec3 norm_color(vec3 color){
            return vec3(color[0] / 255.0, color[1] / 255.0, color[2] / 255.0);
        }
        
        float transform_color(int rep_color, int check_color, vec4 texColor, vec4 repColor){
            if(rep_color == 0){
                float diff = texColor.r - ((texColor.b + texColor.g) / 2.0);
                if(check_color == 0){
                    return (texColor.b + texColor.g) / 2.0 + (diff * repColor.r);
                }else if(check_color == 1){
                    return texColor.g + (repColor.g * diff);
                }else if(check_color == 2){
                    return texColor.b + (repColor.b * diff);
                }
            }else if(rep_color == 1){
                float diff = texColor.g - ((texColor.r + texColor.b) / 2.0);
                if(check_color == 0){
                    return texColor.r + (repColor.r * diff);
                }else if(check_color == 1){
                    return (texColor.r + texColor.b) / 2.0 + (diff * repColor.g);
                }else if(check_color == 2){
                    return texColor.b + (repColor.b * diff);
                }
            }else if(rep_color == 2){
                float diff = texColor.b - ((texColor.r + texColor.g) / 2.0);
                if(check_color == 0){
                    return texColor.r + (repColor.r * diff);
                }else if(check_color == 1){
                    return texColor.g + (repColor.g * diff);
                }else if(check_color == 2){
                    return (texColor.r + texColor.g) / 2.0 + (diff * repColor.b);
                }
            }else{
                if(check_color == 0){
                    return texColor.r;
                }else if(check_color == 1){
                    return texColor.g;
                }else if(check_color == 2){
                    return texColor.b;
                }
            }
            return 0.0;
        }
        
        void mainImage(out vec4 fragColor, in vec2 fragCoord){    
            vec4 texColor = flixel_texture2D(iChannel0, fragCoord / iResolution.xy);
            
            vec4 repColor;
            if(typeChange == 0){
                repColor = vec4(norm_color(replaceColor), 1.0);
            }else if(typeChange == 1){
                repColor = get_grad(norm_color(replaceColor), norm_color(replaceColor2));
            }
        
            vec4 newColor = vec4(
                transform_color(checkColor, 0, texColor, repColor),
                transform_color(checkColor, 1, texColor, repColor),
                transform_color(checkColor, 2, texColor, repColor),
                texColor.a
            );
        
            fragColor = newColor;
        }
    ")

    public var v_typeChange(default, set):Int = 0;
    public function set_v_typeChange(value:Int):Int {
        this.typeChange.value = [value];
        return v_typeChange = value;
    }

    public var v_checkColor(default, set):String = "Blue";
    public function set_v_checkColor(value:String):String {
        var toSet:Int = -1;
        switch(value){
            case "Red":{toSet = 0;}
            case "Green":{toSet = 1;}
            case "Blue":{toSet = 2;}
        }
        this.checkColor.value = [toSet];
        return v_checkColor = value;
    }
    
    public var v_replaceColor(default, set):FlxColor;
    public function set_v_replaceColor(value:FlxColor):FlxColor {
        this.replaceColor.value = [value.red, value.green, value.blue];
        return v_replaceColor = value;
    }
    public var v_replaceColor2(default, set):FlxColor;
    public function set_v_replaceColor2(value:FlxColor):FlxColor {
        this.replaceColor2.value = [value.red, value.green, value.blue];
        return v_replaceColor2 = value;
    }

    public static function get_shader(new_checkColor:String = "Blue", new_replaceColor:FlxColor, ?new_secondColor:FlxColor):ShaderColorSwap {
        for(s in shader_list){
            if(s.v_checkColor != new_checkColor){continue;}
            if(s.v_replaceColor != new_replaceColor){continue;}
            if(new_secondColor != null && s.v_replaceColor2 != new_secondColor){continue;}
            return s;
        }
        return new ShaderColorSwap(new_checkColor, new_replaceColor, new_secondColor);
    }
    public function new(new_checkColor:String = "Blue", new_replaceColor:FlxColor, ?new_secondColor:FlxColor):Void {
        super({});
        v_typeChange = 0;
        v_checkColor = new_checkColor;
        v_replaceColor = new_replaceColor;
        if(new_secondColor != null){v_replaceColor2 = new_secondColor; v_typeChange = 1;}

        shader_list.push(this);
    }
}