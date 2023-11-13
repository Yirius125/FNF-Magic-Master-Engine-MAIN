
import("flixel.tweens.FlxTween", "FlxTween");
import("flixel.tweens.FlxEase", "FlxEase");

import("Note");
import("Paths");
import("Std");

preset("defaultValues", 
    [
        {name:"Scroll",type:"Float",value:3},
        {name:"Id",type:"Int",value:0}
    ]
);

function execute(scroll:Float, time:Float, id:Int):Void {
    if(time == null || time == 0){
        if(id != null){getState().strumsGroup.members[id].scrollSpeed = scroll;}
        else{for(s in getState().strumsGroup){s.scrollSpeed = scroll;}}
        
        return;
    }
    if(id != null){
        var curStrum = getState().strumsGroup.members[id];
        FlxTween.tween(curStrum, {scrollSpeed: scroll}, time, {ease: FlxEase.quadInOut});
    }
    else{
        for(s in getState().strumsGroup){
            FlxTween.tween(s, {scrollSpeed: scroll}, time, {ease: FlxEase.quadInOut});
        }
    }
}