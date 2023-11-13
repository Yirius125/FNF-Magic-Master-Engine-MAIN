package;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.animation.FlxBaseAnimation;
import flixel.group.FlxSpriteGroup;
import Song.SwagGeneralSection;
import flixel.tweens.FlxTween;
import haxe.format.JsonParser;
import openfl.utils.AssetType;
import states.MusicBeatState;
import haxe.macro.Expr.Catch;
import flash.geom.Rectangle;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import openfl.utils.Assets;
import flixel.FlxCamera;
import Song.SwagSection;
import flixel.FlxObject;
import flixel.FlxSprite;
import Song.SwagSong;
import Song.SwagStrum;
import flixel.FlxG;
import haxe.Json;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

using SavedFiles;
using StringTools;

typedef CharacterFile = {
	var name:String;

	var image:String;
	var healthicon:String;

	var script:String;

	var onRight:Bool;
	var antialiasing:Bool;
	var danceIdle:Bool;

	var sing_time:Float;

	var scale:Float;

	var position:Array<Float>;
	var camera:Array<Float>;
	var anims:Array<AnimArray>;
}

typedef AnimArray = {
	var anim:String;
	var symbol:String;
	var fps:Int;

	var sustain_sing:Int;

	var indices:Array<Int>;
	var loop:Bool;
}

class Character extends FlxSpriteGroup {
	public static function getFocusCharID(song:SwagSong, section:Int, ?strum:Int):Int {
		section = Std.int(Math.min(section, song.generalSection.length - 1));
		section = Std.int(Math.max(section, 0));
		
		var strum_list = song.sectionStrums;
		var focused_strum = strum != null ? strum : song.generalSection[section].strumToFocus;
		var focused_character = song.generalSection[section].charToFocus;

		if(strum_list == null || strum_list[focused_strum] == null){return 0;}
		if(strum_list[focused_strum].notes[section] != null && strum_list[focused_strum].notes[section].changeSing){return strum_list[focused_strum].notes[section].charToSing[focused_character];}
		return strum_list[focused_strum].charToSing[focused_character];
	}

	public static function setCameraToCharacter(char:Character, cam:FlxObject, stage:Stage){
		if(char == null){return;} if(cam == null){return;}

		var camMoveX = char.c.getGraphicMidpoint().x;
		var camMoveY = char.c.getGraphicMidpoint().y;

		camMoveX += char.cameraPosition[0];
		camMoveY += char.cameraPosition[1];
		
		if(stage != null){
			if(stage.camP_1 != null){
				camMoveX = Math.max(camMoveX, stage.camP_1[0]);
				camMoveY = Math.max(camMoveY, stage.camP_1[1]);
			}
			if(stage.camP_2 != null){
				camMoveX = Math.min(camMoveX, stage.camP_2[0]);
				camMoveY = Math.min(camMoveY, stage.camP_2[1]);
			}
		}

		switch(PreSettings.getPreSetting("Type Camera", "Visual Settings")){
			case "Static":{}
			case "MoveToSing":{
				if(char.curAnim.contains("UP")){
					camMoveY -= 25;
				}else if(char.curAnim.contains("DOWN")){
					camMoveY += 25;
				}else if(char.curAnim.contains("LEFT")){
					camMoveX -= 25;
				}else if(char.curAnim.contains("RIGHT")){
					camMoveX += 25;
				}
			}
		}

		if(stage != null){
			if(stage.camP_1 != null){
				camMoveX = Math.max(camMoveX, stage.camP_1[0]);
				camMoveY = Math.max(camMoveY, stage.camP_1[1]);
			}
			if(stage.camP_2 != null){
				camMoveX = Math.min(camMoveX, stage.camP_2[0]);
				camMoveY = Math.min(camMoveY, stage.camP_2[1]);
			}
		}

		
		cam.setPosition(FlxMath.lerp(cam.x, camMoveX, FlxG.elapsed * 20), FlxMath.lerp(cam.y, camMoveY, FlxG.elapsed * 20));
	}

	public static function getCharacters():Array<String>{
		var charArray = [];
		for(path in Paths.readDirectory('assets/characters')){
			charArray.push(path.split("/").pop());
		}

		return charArray;
	}

	public static function addToLoad(list:Array<Dynamic>, character:String = 'Boyfriend', aspect:String = 'Default'):Void {
		trace('|| CHARACTER: ${character} | ASPECT: ${aspect} ||');

		var char_path:String = Paths.character(character, aspect);
		var char_file:CharacterFile = cast char_path.getJson();

		list.push({type: IMAGE, instance: Paths.image('characters/${character}/${char_file.image}')});
		list.push({type: IMAGE, instance: Paths.image('icons/icon-${char_file.healthicon}')});

		if(!Paths.exists(Paths._character(character, '${char_file.script}.hx'))){return;}
		Script.importScript(Paths._character(character, '${char_file.script}.hx')).exFunction('addToLoad', [list]);
	}

	public static var DEFAULT_CHARACTER:String = 'Boyfriend';

	public var c:FlxSprite;

	public var charFile:CharacterFile;
	public var charScript:Script;

	public var curCharacter:String = DEFAULT_CHARACTER;
	public var curSkin:String = "Default";
	public var curAspect:String = "Default";
	public var curType:String = "Normal";
	public var curLayer:Int = 0;

	public var singTimer:Float = 4;
	public var holdTimer:Float = 0;
	public var isDeath:Bool = false;
	public var specialAnim:Bool = false;
	public var dancedIdle:Bool = false;
	public var noDance:Bool = false;
	public var onRight:Bool = true;

	public var healthIcon:String = 'face';
	public var animationsArray:Map<String, AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var imageFile:String = '';

	public var onDebug:Bool = false;

	public function new(x:Float, y:Float, ?character:String = 'Boyfriend', ?aspect:String = 'Default', ?type:String = "NORMAL", is_death:Bool = false):Void {
		super(x, y);

		curCharacter = character;
		curAspect = aspect;
		curType = type;

		isDeath = is_death;

		switch(curCharacter){
			default:{setupByCharacterFile();}
		}
	}

	public function setupByName(?_character:String, ?_aspect:String, ?_type:String):Void {
		if(_character != null){curCharacter = _character;}
		if(_aspect != null){curAspect = _aspect;}
		if(_type != null){curType = _type;}
		setupByCharacterFile();
	}

	public function setupByCharacterFile(?jCharacter:CharacterFile):Void {
		var char_path:String = Paths.character(curCharacter, curAspect, curSkin, isDeath);
		if(jCharacter == null){jCharacter = cast char_path.getJson();}

		charFile = jCharacter;

		parseCharacterFiler(charFile);

		curCharacter = charFile.name;

		singTimer = charFile.sing_time;
		healthIcon = charFile.healthicon;
		this.dancedIdle = charFile.danceIdle;
		this.antialiasing = charFile.antialiasing;

		imageFile = charFile.image;
		
		animationsArray.clear();
		for(a in charFile.anims){animationsArray.set(a.anim, a);}

		positionArray = charFile.position;
		cameraPosition = charFile.camera;

		if(charScript != null){
			charScript.destroy();
			charScript = null;
		}

		if(Paths.exists(Paths._character(curCharacter, '${charFile.script}.hx'))){
			charScript = new Script();
			charScript.setVariable("instance", this);
			charScript.exScript(Paths._character(curCharacter, '${charFile.script}.hx').getText());
		}

		setCharacterGraphic();
		turnLook(onRight);

		dance();
	}

	public static function parseCharacterFiler(charFile:CharacterFile):Void {
		if(charFile.healthicon == null){charFile.healthicon = "face";}

		if(charFile.image == null){charFile.image = "BOYFRIEND";}
		if(charFile.anims == null){charFile.anims = [];}

		if(charFile.position == null){charFile.position = [];}		
		if(charFile.camera == null){charFile.camera = [0, 0];}
	}

	private var last_path:String = null;
	public function setCharacterGraphic(?IMAGE:String):Void {
		if(IMAGE != null){imageFile = IMAGE;}

		this.clear();

		c = new FlxSprite(positionArray[0], positionArray[1]);

		c.antialiasing = charFile.antialiasing;

		var new_path:String = Paths.image('characters/${curCharacter}/${imageFile}');
		c.frames = new_path.getAtlas();
		last_path = new_path;

		if(animationsArray != null){
			for(anim in animationsArray){
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.symbol;
				var animFps:Int = anim.fps;
				var animLoop:Bool = anim.loop; // Bruh
				var animIndices:Array<Int> = anim.indices;
				if(animIndices != null && animIndices.length > 0){
					c.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				}else{
					c.animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
			}
		}
		dance();
		scaleCharacter();

		if(charScript != null){charScript.exFunction('load_before_char');}

		this.add(c);

		if(charScript != null){charScript.exFunction('load_after_char');}
	}

	private var oldBeat:Int = 0;
	override function update(elapsed:Float){
		if(!onDebug && !noDance){
			if(holdTimer > 0){
				holdTimer -= elapsed;
			}else{
				if(MusicBeatState.state.curBeat != oldBeat){
					dance();
				}
			}

			if(curPAnim() != null && curPAnim().finished && getAnim('${curAnim}-loop') != null){
				c.animation.play('${curAnim}-loop');
			}
		}

		oldBeat = MusicBeatState.state.curBeat;
		
		if(curPAnim() != null && curPAnim().finished && specialAnim){specialAnim = false;}

		super.update(elapsed);

		if(charScript != null){charScript.exFunction('update', [elapsed]);}
	}

	private var isDanceRight:Bool = false;
	public function dance():Void {
		if(specialAnim || (charScript != null && charScript.exFunction('dance'))){return;}

		if(dancedIdle){
			isDanceRight = !isDanceRight;
			if(!isDanceRight){
				c.animation.play('danceLeft', true);
			}else{
				c.animation.play('danceRight', true);
			}
		}else{
			c.animation.play('idle');
		}
	}

	public var curAnim:String = "";
	public function singAnim(AnimName:String, Force:Bool = false, Special:Bool = false):Void {
		playAnim(AnimName, Force, Special);
		holdTimer = singTimer;
	}
	public function playAnim(AnimName:String, Force:Bool = false, Special:Bool = false):Void {
		if(specialAnim && !Special){return;}
		if(
			curAnim == AnimName &&
			animationsArray.exists(AnimName) &&
			curPAnim() != null &&
			curPAnim().curFrame < animationsArray[AnimName].sustain_sing &&
			!Force
		){return;}
		if(charScript != null && charScript.exFunction('playAnim', [AnimName, Force])){return;}
		if(c == null){return;}
		if(c.animation.getByName(AnimName) == null){return;}
		
		specialAnim = Special;
		curAnim = AnimName;
		
		if(c.flipX){
			if(AnimName.contains("LEFT")){AnimName = AnimName.replace("LEFT", "RIGHT");}
			else{AnimName = AnimName.replace("RIGHT", "LEFT");}
		}
		
		c.animation.play(AnimName, Force);
	}

	public function aniName():String {if(c.animation.curAnim == null){return "";} return c.animation.curAnim.name;}
	public function getAnim(name:String){return c.animation.getByName(name);}
	public function curPAnim(){return c.animation.curAnim;}

	public function turnLook(toRight:Bool = true):Void {
		onRight = toRight;
		c.flipX = onRight ? !charFile.onRight : charFile.onRight;
		if(charScript != null){charScript.exFunction('turnLook', [toRight]);}
	}

	public function scaleCharacter(_scale:Float = 1):Void {
		var new_scale = _scale * charFile.scale;
		c.scale.set(new_scale, new_scale);
		c.updateHitbox();
	}

	override public function destroy():Void {
		super.destroy();

		if(charScript != null){
			charScript.destroy();
			charScript = null;
		}
	}
}

class Skins {
	private static var skin_manager:Map<String, Dynamic> = [];

	public static function init():Void {
		skin_manager.clear();

		var character_list:Array<String> = Character.getCharacters();

		for(char in character_list){
			var current_skin_char = {current_skin: "Default", skins: [{name: "Default", locked: false}]};

			for(json in Paths.readDirectory('assets/characters/$char')){
				var j_array:Array<String> = json.split("/").pop().split("-");
				if(j_array.length < 2){continue;}

				var cur_skin:String = j_array[1];
				for(s in current_skin_char.skins){if(s.name == cur_skin){continue;}}
				current_skin_char.skins.push({name: cur_skin, locked: true});
			}
			skin_manager.set(char, current_skin_char);
		}

		var saved_skin_data:Map<String, Dynamic> = FlxG.save.data.skins;

		if(saved_skin_data == null){return;}
		for(skin_key in saved_skin_data.keys()){
			setSkin(skin_key, saved_skin_data[skin_key].skin);
			var character_unlockeds:Array<Dynamic> = saved_skin_data[skin_key].unlockeds;
			for(unlocked in character_unlockeds){unlockSkin(skin_key, unlocked);}
		}
	}

	public static function getSkin(character:String):String {
		if(!skin_manager.exists(character)){return "Default";}
		return skin_manager.get(character).current_skin;
	}

	public static function getSkinList(character:String):Array<Dynamic> {
		if(!skin_manager.exists(character)){return ["Default"];}
		return skin_manager.get(character).skins;
	}

	public static function unlockSkin(character:String, skin:String):Void {		
		if(!skin_manager.exists(character)){trace("Null Character"); return;}

		var character_skins:Array<Dynamic> =skin_manager.get(character).skins;

		for(_skin in character_skins){
			if(_skin.name == skin){
				_skin.locked = false;
				return;
			}
		}

		trace("Skin Not Found");
	}

	public static function rewardSkin(character:String, skin:String):Void {
		unlockSkin(character, skin);
		save();
	}

	public static function setSkin(character:String, skin:String):Void {
		if(!skin_manager.exists(character)){trace("Null Character"); return;}
		skin_manager.get(character).current_skin = skin;
	}

	public static function checkLocked(character:String, skin:String):Bool {
		if(!skin_manager.exists(character)){trace("Null Character"); return true;}

		var skin_list:Array<Dynamic> = skin_manager.get(character).skins;

		for(_skin in skin_list){
			if(_skin.name == skin){
				return _skin.locked;
			}
		}

		return true;
	}

	public static function save():Void {
		var skins_to_save:Map<String, Dynamic> = [];

		for(char_key in skin_manager.keys()){
			var current_skin_data = {
				skin: getSkin(char_key),
				unlockeds: []
			};

			for(skin in getSkinList(char_key)){
				if(!skin.locked){
					current_skin_data.unlockeds.push(skin.name);
				}
			}

			skins_to_save.set(char_key, current_skin_data);
		}

		FlxG.save.data.skins = skins_to_save;
		FlxG.save.flush();
	}
}