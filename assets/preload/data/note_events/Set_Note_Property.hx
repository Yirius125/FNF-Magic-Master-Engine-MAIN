import("Note");
import("PreSettings");
import("Reflect");
import("Paths");
import("StringTools");

import("flixel.FlxG", "FlxG");

presset("defaultValues", 
    [
        {name:"Property",type:"String",value:""},
        {name:"Value",type:"String",value:""}
    ]
);

function execute(property:String, value:String){
    if(_note == null || property == "" ||value == ""){return;}
    Reflect.setProperty(_note, property, value);
}