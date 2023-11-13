package substates;

import flixel.addons.ui.FlxUISubState;
import Conductor.BPMChangeEvent;
import states.MusicBeatState;
import flixel.util.FlxColor;
import flixel.FlxSubState;
import flixel.FlxCamera;
import flixel.FlxG;

using SavedFiles;
using StringTools;

class MusicBeatSubstate extends FlxUISubState {
	public var conductor:Conductor = MusicBeatState.state.conductor;

	public var onClose:Void->Void = function(){};

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	public var curCamera:FlxCamera = new FlxCamera();
	
	public var principal_controls(get, never):Controls;
	inline function get_principal_controls():Controls{return PlayerSettings.getPlayer(0).controls;}
	private function getOtherControls(ID:Int):Controls{return PlayerSettings.getPlayer(ID).controls;}
	public var canControlle:Bool = false;
	
    public var tempScripts:Map<String, Script> = [];
	public function pushTempScript(key:String):Void {
		if(tempScripts.exists(key) || ModSupport.staticScripts.exists(key)){return;}
		var nScript = new Script(); nScript.Name = key;
		nScript.exScript(Paths.event(key).getText());
		tempScripts.set(key, nScript);
	}
	public function removeTempScript(key:String):Void {
		if(!tempScripts.exists(key) && !ModSupport.staticScripts.exists(key)){return;}
		ModSupport.staticScripts.remove(key);
		tempScripts.remove(key);
	}

	public var scripts(get, never):Array<Script>;
	function get_scripts():Array<Script> {
		var toReturn:Array<Script> = [];
		for(sc in tempScripts.keys()){toReturn.push(tempScripts.get(sc));}
		for(sc in ModSupport.staticScripts.keys()){
			if(sc.contains(".") && sc != Type.getClassName(Type.getClass(this))){continue;}
			toReturn.push(ModSupport.staticScripts.get(sc));
		}
		for(sc in ModSupport.modDataScripts.keys()){toReturn.push(ModSupport.modDataScripts.get(sc));}
		return toReturn;
	}

	public function new(onClose:Void->Void = null){
		if(onClose != null){this.onClose = onClose;}
		curCamera.bgColor = FlxColor.BLACK;
		curCamera.bgColor.alpha = 100;
		FlxG.cameras.add(curCamera);
		
		super();
	}

	override function create() {
		super.create();
		
		FlxG.mouse.visible = false;

		for(s in scripts){s.setVariable('getSubstate', function(){return this;});}
		for(s in scripts){s.exFunction('create');}
	}

	override function update(elapsed:Float){
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		curBeat = Math.floor(curStep / 4);

		if(oldStep != curStep && curStep > 0){stepHit();}

		if(FlxG.keys.justPressed.P){for(s in tempScripts.keys()){trace(s);}}

		for(s in scripts){s.exFunction('update', [elapsed]);}

		super.update(elapsed);
	}

	private function updateCurStep():Void{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}

		for(i in 0...conductor.bpmChangeMap.length){if(conductor.songPosition > conductor.bpmChangeMap[i].songTime){lastChange = conductor.bpmChangeMap[i];}}
		curStep = lastChange.stepTime + Math.floor((conductor.songPosition - lastChange.songTime) / conductor.stepCrochet);
	}

	public function stepHit():Void {
		if(curStep % 4 == 0){beatHit();}

		for(s in scripts){s.exFunction('stepHit', [curStep]);}
	}

	public function beatHit():Void {
		//do literally nothing dumbass

		for(s in scripts){s.exFunction('beatHit', [curBeat]);}
	}

	public function loadSubState(substate:String, args:Array<Any>):Void {
		var new_substate:FlxSubState = MusicBeatState.getSubState(substate, args);
		if(new_substate == null){trace('Null SubState: ${substate}'); return;}
		openSubState(new_substate);
	}

	override function close():Void {
		for(s in scripts){s.exFunction('onClose');}

		onClose();

		FlxG.cameras.remove(curCamera);
		curCamera.destroy();

		super.close();
	}

	override function destroy(){		
		super.destroy();
	}
}
