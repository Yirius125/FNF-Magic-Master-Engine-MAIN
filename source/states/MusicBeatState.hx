package states;

import flixel.addons.transition.FlxTransitionableState;
import openfl.utils.Assets as OpenFlAssets;
import substates.CustomScriptSubState;
import flixel.addons.ui.FlxUIState;
import haxe.rtti.CType.Abstractdef;
import substates.MusicBeatSubstate;
import FlxCustom.FlxCustomShader;
import Conductor.BPMChangeEvent;
import flixel.tweens.FlxTween;
import substates.FadeSubState;
import flixel.util.FlxTimer;
import flixel.math.FlxRect;
import flixel.FlxSubState;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.FlxState;
import flixel.FlxG;

using SavedFiles;
using StringTools;

class MusicBeatState extends FlxUIState {
	public static var state:MusicBeatState;

	public var conductor:Conductor = new Conductor();

	public var onBack:String;
	public var onConfirm:String;
	
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	public var principal_controls(get, never):Controls;
	inline function get_principal_controls():Controls{return PlayerSettings.getPlayer(0).controls;}

	private function getOtherControls(ID:Int):Controls{return PlayerSettings.getPlayer(ID).controls;}
	public var canControlle:Bool = false;

    public var tempScripts:Map<String, Script> = [];
	public function pushTempScript(key:String):Void {
		if(tempScripts.exists(key) || ModSupport.staticScripts.exists(key)){return;}
		if(!Paths.exists(Paths.event(key))){return;}
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

	public var camGame:FlxCamera = new FlxCamera();
	public var camFGame:FlxCamera = new FlxCamera();
	public var camBHUD:FlxCamera = new FlxCamera();
	public var camHUD:FlxCamera = new FlxCamera();
	public var camFHUD:FlxCamera = new FlxCamera();
	
	public function new(?onConfirm:String, ?onBack:String){
		this.onBack = onBack;
		this.onConfirm = onConfirm;

		super();
	}

	override function create(){
		state = this;
		persistentUpdate = false;
		
        FlxG.mouse.visible = false;

		FlxG.game.setFilters([]);

		camFGame.bgColor.alpha = 0;
		camBHUD.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camFHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camFGame);
		FlxG.cameras.add(camBHUD);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camFHUD);

		FlxCamera.defaultCameras = [camGame];

		if(!(this is CustomScriptState) && !ModSupport.staticScripts.exists(Type.getClassName(Type.getClass(this)))){
			var script_path:{script:String, mod:String} = Paths.script(Type.getClassName(Type.getClass(this)).replace(".", "/"));
			if(script_path.script.length > 0 && Paths.exists(script_path.script)){
				var nScript = new Script();
				nScript.Name = Type.getClassName(Type.getClass(this));
				nScript.Mod = script_path.mod;
				nScript.exScript(script_path.script.getText());
				tempScripts.set(Type.getClassName(Type.getClass(this)), nScript);
			}
		}
		for(key in ModSupport.loadScripts.keys()){
			var script_data = ModSupport.loadScripts.get(key);
			var nScript = new Script();
			nScript.Name = key;
			nScript.Mod = script_data[1];
			nScript.exScript(script_data[0].getText());
			tempScripts.set(key, nScript);
		}

		for(s in scripts){s.exFunction('create');}
		
		super.create();

		SavedFiles.clearUnusedAssets();
		openSubState(new FadeSubState());

		canControlle = true;
	}

	override function update(elapsed:Float){
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if(FlxG.keys.justPressed.P){for(s in tempScripts.keys()){trace(s);}}

		if(oldStep != curStep && curStep > 0){stepHit();}

		if(canControlle){
			if(principal_controls.checkAction("Menu_Accept", JUST_PRESSED) && onConfirm != null){MusicBeatState.switchState(onConfirm, []);}
			if(principal_controls.checkAction("Menu_Back", JUST_PRESSED) && onBack != null){FlxG.sound.play(Paths.sound("cancelMenu").getSound()); MusicBeatState.switchState(onBack, []);}
		}

		for(s in scripts){s.exFunction('update', [elapsed]);}

		for(shader in FlxCustomShader.shaders){
			if(shader == null){FlxCustomShader.shaders.remove(shader); continue;}
			shader.update(elapsed);
		}

		super.update(elapsed);
	}

	private function updateBeat():Void{curBeat = Math.floor(curStep / 4);}

	private function updateCurStep():Void{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...conductor.bpmChangeMap.length){
			if(conductor.songPosition >= conductor.bpmChangeMap[i].songTime){lastChange = conductor.bpmChangeMap[i];}
		}

		curStep = lastChange.stepTime + Math.floor((conductor.songPosition - lastChange.songTime) / conductor.stepCrochet);
	}

	public function stepHit():Void {
		if(curStep % 4 == 0){beatHit();}
		for(s in scripts){s.exFunction('stepHit', [curStep]);}
	}

	public function beatHit():Void {
		for(s in scripts){s.exFunction('beatHit', [curBeat]);}
	}
	
	override public function onFocus():Void{
		for(s in scripts){s.exFunction('onFocus');}
	}
	override public function onFocusLost():Void{
		for(s in scripts){s.exFunction('onFocusLost');}
	}

	public static function getSubState(state:String, args:Array<Any>):FlxSubState {
		var to_create:Class<FlxSubState> = Type.resolveClass(state) != null ? cast Type.resolveClass(state) : null;
		
		var script_path:{script:String, mod:String} = Paths.script(state.replace(".", "/"));
		if(script_path.script.length > 0 && Paths.exists(script_path.script)){
			var nScript = new Script();
			nScript.Name = state;
			nScript.Mod = script_path.mod;
			nScript.exScript(script_path.script.getText());
			if(nScript.getVariable('CustomSubState') && !ModSupport.exStates.contains(state)){
				to_create = CustomScriptSubState;
				args.insert(0, nScript);
			}
		}
		
		if(to_create == null){return null;}
		var new_state = Type.createInstance(to_create, args);
		return new_state;
	}

	public function loadSubState(substate:String, args:Array<Any>):Void {
		var new_substate:FlxSubState = getSubState(substate, args);
		if(new_substate == null){trace('Null SubState: ${substate}'); return;}
		openSubState(new_substate);
	}

	override function openSubState(SubState:FlxSubState){super.openSubState(SubState);}
	override function closeSubState(){super.closeSubState();}

	public static function getState(state:String, args:Array<Any>):FlxState {
		var to_create:Class<FlxState> = Type.resolveClass(state) != null ? cast Type.resolveClass(state) : null;
		
		var script_path:{script:String, mod:String} = Paths.script(state.replace(".", "/"));
		if(script_path.script.length > 0 && Paths.exists(script_path.script)){
			var nScript = new Script();
			nScript.Name = state;
			nScript.Mod = script_path.mod;
			nScript.exScript(script_path.script.getText());
			if(nScript.getVariable('CustomState') && !ModSupport.exStates.contains(state)){
				to_create = CustomScriptState;
				args.insert(0, nScript);
			}
		}

		if(to_create == null){return null;}
		
		var new_state = Type.createInstance(to_create, args);		
		return new_state;
	}

	public static function loadState(state:String, state_args:Array<Any>, load_args:Array<Any>):Void {
		var new_stage:FlxState = getState(state, state_args);
		if(new_stage == null){trace('Null State: ${state}'); return;}
		load_args.insert(0, new_stage);
		_switchState(Type.createInstance(LoadingState, load_args));
	}

	public static function switchState(state:String, args:Array<Any>):Void {
		var new_stage:FlxState = getState(state, args);
		if(new_stage == null){trace('Null State: ${state}'); return;}
		_switchState(new_stage);
	}

	public static function _switchState(nextState:FlxState):Void {
		if(state == null){
			FlxG.switchState(new VoidState(nextState));
		}else{
			state.canControlle = false;
			state.openSubState(new FadeSubState(nextState));
		}
	}
}
