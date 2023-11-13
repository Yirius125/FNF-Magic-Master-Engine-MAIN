import("flixel.FlxG", "FlxG");

import("Note");
import("Paths");
import("Reflect");
import("StringTools");
import("PreSettings");


preset("defaultValues", 
    [
        {name:"Function",type:"String",value:""},
        {name:"Args",type:"Array",value:[]}
    ]
);

function execute(funct:String, args:Array<Dynamic>){
    if(_note == null || funct == "" || args.length <= 0){return;}
    Reflect.callMethod(_note, Reflect.field(_note, funct), args);
}