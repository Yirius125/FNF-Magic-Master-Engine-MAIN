import("flixel.FlxG", "FlxG");

import("Note");
import("Paths");
import("Reflect");
import("StringTools");
import("PreSettings");

preset("defaultValues", 
    [
        {name:"Property",type:"String",value:""},
        {name:"Value",type:"String",value:""}
    ]
);

function execute(property:String, value:Dynamic){
    if(_note == null || property == "" || value == ""){return;}
    Reflect.setProperty(_note, property, value);
}