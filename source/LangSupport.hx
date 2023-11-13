package;

import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.interfaces.IFlxUIClickable;
import flixel.addons.ui.interfaces.IEventGetter;
import flixel.addons.ui.interfaces.IFlxUIButton;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.addons.transition.TransitionData;
import flixel.addons.ui.interfaces.IResizable;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxStringUtil;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxGradient;
import flixel.system.FlxAssets;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flash.geom.Rectangle;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import haxe.DynamicAccess;
import flixel.FlxSprite;
import flixel.FlxG;
import haxe.Json;

#if (desktop && sys)
import sys.FileSystem;
import sys.io.File;
#end

using SavedFiles;
using StringTools;

class LangSupport {
    public static function getLangs():Array<String> {
        var toReturn:Array<String> = [];
        for(path in Paths.readDirectory('assets/lang/')){
            if(!path.endsWith(".json")){continue;}
            toReturn.push(path.split("_")[1].replace(".json", ""));
        }
        return toReturn;
    }

    public static var Language:String = "English";
    private static var LANG:DynamicAccess<Dynamic>;

    public static function init():Void {
        var savedLang:String = PreSettings.getPreSetting("Language", "Game Settings");
        if(savedLang == null){savedLang = Language;}

        setLang(savedLang);
    }

    public static function setLang(_lang:String):Void {
        Language = _lang; if(!Paths.exists(Paths.getPath('lang/lang_${Language}.json', TEXT, null, null))){Language = 'English';}

        var new_lang:DynamicAccess<Dynamic> = {};
        for(langFile in Paths.readFile('assets/lang/lang_${Language}.json')){
            var file_content:Dynamic = langFile.getJson();
            for(key in Reflect.fields(file_content)){
                if(new_lang.exists(key)){continue;}
                new_lang.set(key, Reflect.getProperty(file_content, key));
            }
        }

        LANG = new_lang;
        FlxG.save.data.language = Language;
    }

    public static function getForcedText(key:String):String {
        var toReturn:String = LANG.get(key);
        if(toReturn == null){toReturn = key;}
        return toReturn;
    }
    public static function getText(key:String):Dynamic {
        var toReturn:Dynamic = LANG.get(key);
        if(toReturn == null){toReturn = key;}
        return toReturn;
    }
}