package;

import states.MusicBeatState;
import flixel.FlxBasic;
import hscript.Interp;
import openfl.Lib;

using StringTools;

enum Script_Calls {
    Stop_And_Break;
    Continue;
    Break;
    Stop;
}

class Script extends FlxBasic {
    public static function getScript(key:String):Script {
        if(MusicBeatState.state.tempScripts.exists(key)){return MusicBeatState.state.tempScripts.get(key);}
        return ModSupport.staticScripts.get(key);
    }
    public static function importScript(file:String):Script {
        var new_sript = new Script();
        new_sript.exScript(SavedFiles.getText(file));
        if(new_sript == null){return null;}
        return new_sript;
    }

    public var parser = new hscript.Parser();
    public var interp = new hscript.Interp();
    public var program = null;
    public var source:String = "";

    public var Name:String;
    public var Mod:String;

    public override function new(){
        parser.allowTypes = true;
        super();

        preVariables();
    }

    public function loadScript(script:String):Void{
        try{
            source = script;
            this.program = parser.parseString(script);
        }catch(e){
            trace('[Script Error]: ${e.message}');
            Lib.application.window.alert(e.message, "Script Error!");
        }
    }

    public function getVariable(name:String):Dynamic{return interp.variables.get(name);}
    public function setVariable(name:String, toSet:Dynamic){interp.variables.set(name, toSet);}
    public function preVariables():Void {
        var nFunc = function(){};

        setVariable('create', nFunc);
        setVariable('preload', nFunc);
        
        setVariable('song_started', nFunc);
        setVariable('song_paused', nFunc);
        setVariable('song_ended', nFunc);
        
        setVariable('onClose', nFunc);
        setVariable('onFocus', nFunc);
        setVariable('onFocusLost', nFunc);
        
        setVariable('load_global_ui', nFunc);
        setVariable('load_solo_ui', nFunc);

        setVariable('preload_event', nFunc);
        
        setVariable('startSong', function(toEndFun:Void->Void){});
        setVariable('endSong', function(toEndFun:Void->Void){});
        
        setVariable('update', function(elapsed:Float) {});

        setVariable('beatHit', function(curBeat:Int) {});
        setVariable('stepHit', function(curStep:Int) {});

        setVariable("preset", function(name:String, func:Any){setVariable(name, func);});
        setVariable("getset", function(name:String){return getVariable(name);});

        setVariable('destroy', function(){this.destroy();});

        setVariable("pushGlobal", function(){states.MusicBeatState.state.tempScripts.set(this.Name, this);});

        setVariable('this', this);
		setVariable('getState', function(){return states.MusicBeatState.state;});
        setVariable('getScript', function(key:String):Script{return getScript(key);});
        setVariable('getModData', function(){return ModSupport.modDataScripts.get(Mod);});

        setVariable('Script_Calls', Script_Calls);
        setVariable('Stop_And_Break', Stop_And_Break);
        setVariable('Continue', Continue);
        setVariable('Break', Break);
        setVariable('Stop', Stop);
        
        setVariable("import",
            function(imp:String, ?val:String){
                var cl = Type.resolveClass(imp);
                var en = Type.resolveEnum(imp);
                if(cl == null && en == null){Lib.application.window.alert('This Lib Class/Enum [${imp}] is Null', "Null Import"); return;}
                if(en != null){ 
                    var nEnum = {};
                    for(c in en.getConstructors()){Reflect.setField(nEnum, c, en.createByName(c));}
                    setVariable(val != null ? val : imp, nEnum);
                }
                if(cl != null){setVariable(val != null ? val : imp, cl);}
            }
        );
    }
    
    public function execute():Void{if(program == null){trace('Null Program'); return;}interp.execute(program);}
    public function getFunction(name:String){
        if(program == null){trace('{${Name}}: Null Script'); return null;}
        if(!interp.variables.exists(name)){trace('{${Name}}: Null Function [${name}]'); return null;}
        return interp.variables.get(name);
    }
    public function exFunction(name:String, ?args:Array<Any>):Dynamic {
        if(program == null){trace('{${Name}}: Null Script'); return null;}
        if(!interp.variables.exists(name)){trace('{${Name}}: Null Function [${name}]'); return null;}

        var FUNCT = interp.variables.get(name);
        var toReturn = null;
        if(args != null){
            try{
                toReturn = Reflect.callMethod(null, FUNCT, args);
            }catch(e){
                trace('{${Name}}: [Function Error](${name}): ${e}');
            }
        }else{
            try{
                toReturn = FUNCT();
            }catch(e){
                trace('{${Name}}: [Function Error](${name}): ${e}');
            }
        }

        return toReturn;
    }
    
    public function exScript(script:String):Void{
        loadScript(script);
        execute();
    }

    public override function destroy(){
        if(states.MusicBeatState.state != null){states.MusicBeatState.state.tempScripts.remove(Name);}
        program = null;
        super.destroy();
    }
}