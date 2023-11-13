package;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.text.FlxTypeText;
import flixel.addons.ui.FlxUIGroup;
import flixel.group.FlxSpriteGroup;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.FlxSprite;
import haxe.xml.Access;
import haxe.io.Bytes;
import flixel.FlxG;
import haxe.Timer;

import states.MusicBeatState;
import states.editors.XMLEditorState;
import FlxCustom.FlxCustomFlxTypeText;

using SavedFiles;
using StringTools;

typedef DialogueData = {
	var box:String;
	var dialogue_position:Array<Float>;
	var portraits:Array<String>;
	var dialogue:Array<DialogueItem>;
}

typedef DialogueItem = {
	var appear_left:String;
	var appear_right:String;
	var appear_middle:String;

	var text_type:String;

	var box_anim:String;
	var flip_box:Bool;
	var dialog:Array<Dynamic>;
}

class DialogueBox extends FlxUIGroup {
	public var portraits:Map<String, Dynamic> = [];
	public var sides:Map<String, Portrait> = [
		"Left" => null,
		"Middle" => null,
		"Right" => null
	];

	public var dialogue_box:FlxSprite;

	public var dialogue_flixel_text:FlxCustomFlxTypeText;
	public var dialogue_custom_text:Alphabet;
	
	public var dialogue_data:DialogueData;
	public var cur_dialogue:Int = 0;

	public var finishFunc:Void->Void = function(){};
	
	public var script:Script;

	public var controls:Controls;
	public var can_controlle:Bool = false;

	public var curAnim:String = "";

	public function new(_data:Dynamic, ?options:Dynamic){
		this.dialogue_data = _data.dialogue;
		this.controls = MusicBeatState.state.principal_controls;
		if(options.onComplete != null){finishFunc = options.onComplete;}
		super();
		this.autoBounds = false;

		for(port in dialogue_data.portraits){
			trace(port);
			var new_port:Portrait = new Portrait(port);
			new_port.alpha = 0;

			portraits.set(port, {side:"null", sprite: new_port});
			add(new_port);
		}

		dialogue_box = new FlxSprite();
		add(dialogue_box);

		dialogue_flixel_text = new FlxCustomFlxTypeText(dialogue_data.dialogue_position[0], dialogue_data.dialogue_position[1], 0);
		add(dialogue_flixel_text);
			
		dialogue_custom_text = new Alphabet(dialogue_data.dialogue_position[0], dialogue_data.dialogue_position[1], []);
		dialogue_custom_text.onType = function(char:String, item:Dynamic):Void {
			if(item.portrait == null){return;}
			var cur_port:Portrait = portraits.get(item.portrait).sprite;
			if(cur_port == null){return;}

			cur_port.talk();
		}
		add(dialogue_custom_text);

		loadDialogueBox(dialogue_data.box);

		if(options.script != null){
			script = options.script;
		}else if(options.script_path != null){
			script = new Script();
			script.Name = "Dialogue_Script";
			script.exScript(options.script_path);
		}

		this.screenCenter();
		this.y = FlxG.height - dialogue_box.height - 30;

		can_controlle = true;
		nextDialogue();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if(can_controlle){
			if(controls.checkAction("Menu_Accept", JUST_PRESSED)){nextDialogue(1);}
		}

		if(dialogue_box != null && dialogue_box.animation != null && dialogue_box.animation.curAnim != null && dialogue_box.animation.finished && dialogue_box.animation.curAnim.name.contains("Appear")){
			dialogue_box.animation.play('${curAnim}_Idle', true);
		}
	}

	public var type_dialog:String = "Alphabet";
	public function nextDialogue(value:Int = 0, force:Bool = false):Void {
		switch(type_dialog){
			case "Alphabet":{if(dialogue_custom_text.isTyping){dialogue_custom_text.loadText(); return;}}
			case "Flixel":{if(dialogue_flixel_text.isTyping){dialogue_flixel_text.skip(); return;}}
		}
		

		cur_dialogue += value; if(force){cur_dialogue = value;}
		
		var cur_dialog_stuff:DialogueItem = dialogue_data.dialogue[cur_dialogue];

		if(cur_dialog_stuff == null){
			can_controlle = false;
			
			dialogue_custom_text.cur_data = []; dialogue_custom_text.loadText();
			dialogue_flixel_text.startText(" ", 0.1);

			FlxTween.tween(dialogue_box, {alpha: 0}, 1, {onComplete: function(twn:FlxTween){destroy(); if(finishFunc != null){finishFunc();}}});
			for(prt in sides){if(prt == null){continue;} FlxTween.tween(prt, {alpha: 0, y: prt.y + 6}, 0.5);}
			return;
		}

		if(cur_dialog_stuff.text_type != null){type_dialog = cur_dialog_stuff.text_type;}
		dialogue_box.flipX = cur_dialog_stuff.flip_box;

		if(cur_dialog_stuff.box_anim != null && cur_dialog_stuff.box_anim != curAnim){
			curAnim = cur_dialog_stuff.box_anim;
			
			if(dialogue_box.animation.getByName('${curAnim}_Appear') != null){
				dialogue_box.animation.play('${curAnim}_Appear');
			}else{
				dialogue_box.animation.play('${curAnim}_Idle');
			}
		}

		if(cur_dialog_stuff.appear_left != null){changePortrait(cur_dialog_stuff.appear_left, "Left");}
		if(cur_dialog_stuff.appear_right != null){changePortrait(cur_dialog_stuff.appear_right, "Right");}
		if(cur_dialog_stuff.appear_middle != null){changePortrait(cur_dialog_stuff.appear_middle, "Middle");}

		if(script != null){script.exFunction("toChangeDialogue", [cur_dialogue]);}
		
		switch(type_dialog){
			case "Alphabet":{
				dialogue_flixel_text.visible = false;
				dialogue_custom_text.visible = true;

				dialogue_custom_text.cur_data = dialogue_data.dialogue[cur_dialogue].dialog;
				dialogue_custom_text.startText();				
			}
			case "Flixel":{
				dialogue_custom_text.visible = false;
				dialogue_flixel_text.visible = true;
				
				dialogue_flixel_text.startData(dialogue_data.dialogue[cur_dialogue].dialog);
			}
		}

		if(script != null){script.exFunction("onDialogueChanged", [cur_dialogue]);}
	}

	public function loadDialogueBox(sprite_box:String = "Default_Box"):Void {
		var box_path:String = Paths.image('dialogue_boxes/${sprite_box}');
		var box_xml_path:String = box_path.replace(".png", ".xml");

		dialogue_box.frames = box_path.getAtlas();
		
		if(!Paths.exists(box_xml_path)){return;}

		var xml = Xml.parse(box_xml_path.getText());
		var animSymbols:Array<String> = XMLEditorState.getNamesArray(new Access(xml.firstElement()).elements);

		for(symbol in animSymbols){dialogue_box.animation.addByPrefix(symbol, symbol, false);}

		if(dialogue_custom_text != null){dialogue_custom_text.textWidth = dialogue_box.width - 90;}
		if(dialogue_flixel_text != null){dialogue_flixel_text.fieldWidth = dialogue_box.width - 90;}
	}

	public function changePortrait(port:String, side:String):Void {portraits.get(port).side = side; updatePortrait(port);};
	public function updatePortrait(port:String):Void {
		var data_port:Dynamic = portraits.get(port);

		var last_port:Portrait = sides.get(data_port.side);
		if(last_port != null){FlxTween.tween(last_port, {alpha: 0, y: last_port.y + 6}, 0.5);}

		var new_port:Portrait = data_port.sprite;
		sides.set(data_port.side, new_port);
		if(new_port == null){return;}

		switch(data_port.side){
			case "Left":{new_port.setPosition(dialogue_box.x, dialogue_box.y - new_port.height + 6);}
			case "Middle":{new_port.screenCenter(X); new_port.y = dialogue_box.y - new_port.height + 6;}
			case "Right":{new_port.setPosition(dialogue_box.x + dialogue_box.width - new_port.width, dialogue_box.y - new_port.height + 6);}
		}

		FlxTween.tween(new_port, {alpha: 1, y: new_port.y - 6}, 0.5);
	}
}

class Portrait extends FlxSprite {
	public var curPortrait:String = "PlaceHolder";
	public var curExpresion:String = "Normal";

	public function new(_name:String){
		curPortrait = _name;
		super();

		loadPortrait(curPortrait);
	}

	public function loadPortrait(_port:String):Void {
		var port_path:String = Paths.image('dialogue_portraits/${_port}'); trace(port_path);
		var port_xml_path:String = port_path.replace(".png", ".xml");

		this.frames = port_path.getAtlas();
		
		if(!Paths.exists(port_xml_path)){return;}

		var xml = Xml.parse(port_xml_path.getText());
		var animSymbols:Array<String> = XMLEditorState.getNamesArray(new Access(xml.firstElement()).elements);

		for(symbol in animSymbols){this.animation.addByPrefix(symbol, symbol, false);}

		updateHitbox();
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if(animation != null && animation.curAnim != null && animation.finished && animation.curAnim.name.contains("Talk")){
			animation.play('${curExpresion}_Idle', true);
		}
	}

	public function talk():Void {
		if(animation.getByName('${curExpresion}_Talk') == null){return;}
		animation.play('${curExpresion}_Talk', true);
	}
}