package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;

#if (desktop && sys)
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class PreSettings {
    public static var CURRENT_SETTINGS:Map<String, Map<String, Dynamic>> = [];
    public static var PRESETTINGS:Map<String, Map<String, Dynamic>> = [];
    public static final DEFAULTSETTINGS:Map<String, Map<String, Dynamic>> = [
        "Game Settings" => [
            "Miss Sounds" => true,
            "Mute on Miss" => true,
            "Language" => [0, ["English", "Español"]],
            "Note Offset" => 0,
            "Scroll Speed Type" => [0, ["Scale", "Force", "Disabled"]],
            "ScrollSpeed" => 1
        ],
        "Visual Settings" => [
            "Type HUD" => [0, ["MagicHUD", "Original", "Minimized", "Detailed", "OnlyNotes"]],
            "Note Skin" => [0, ["Arrows", "Circles", "Bars", "Haxe"]],
            "Splash Skin" => [0, ["Magic Splash"]],
            "Type Scroll" => [0, ["UpScroll", "DownScroll"]],
            "Default Strum Position" => [0, ["Middle", "Right", "Left"]],
            "Type Middle Scroll" => [0, ["None", "OnlyPlayer", "FadeOthers"]],
            "Type Camera" => [1, ["Static", "MoveToSing"]],
            "Type Light Strums" => [0, ["All", "OnlyMyStrum", "OnlyOtherStrums", "None"]],
            "Type Splash" => [0, ["OnSick", "None"]],
            "Bumping Camera" => true
        ],
        "Graphic Settings" => [
            "FrameRate" => 60,
            "Antialiasing" => true,
            "Background Animated" => true,
            "Only Notes" => false
        ],
        "Other Settings" => [
            "Visible Fps / Memory" => true,
            "Allow FlashingLights" => true,
            "Allow Violence" => true,
            "Allow Gore" => true,
            "Allow NotSafeForWork" => true
        ],
        "Cheating Settings" => [
            "Damage Multiplier" => 1,
            "Healing Multiplier" => 1,
            "Type Mode" => [0, ["Normal", "Practice", "BotPlay"]],
        ]
    ];
    public static function init():Void {
        PRESETTINGS = DEFAULTSETTINGS.copy();
    }

    public static function loadSettings(){
        CURRENT_SETTINGS = FlxG.save.data.PRESETTINGS;
        
        if(CURRENT_SETTINGS == null){CURRENT_SETTINGS = PRESETTINGS;}
        
        for(key in PRESETTINGS.keys()){
            if(!CURRENT_SETTINGS.exists(key)){
                CURRENT_SETTINGS.set(key, PRESETTINGS.get(key));
            }else{
                for(ikey in PRESETTINGS.get(key).keys()){
                    if(!CURRENT_SETTINGS.get(key).exists(ikey)){
                        CURRENT_SETTINGS.get(key).set(ikey, PRESETTINGS.get(key).get(ikey));
                    }else{
                        CURRENT_SETTINGS.get(key).get(ikey)[1] = PRESETTINGS.get(key).get(ikey)[1];
                    }
                }
            }
        }

        for(key in CURRENT_SETTINGS.keys()){
            if(!PRESETTINGS.exists(key)){
                CURRENT_SETTINGS.remove(key);
            }else{
                for(ikey in CURRENT_SETTINGS.get(key).keys()){
                    if(!PRESETTINGS.get(key).exists(ikey)){
                        CURRENT_SETTINGS.get(key).remove(ikey);
                    }
                }
            }
        }

        var toLang:Array<String> = [];
        for(a in Paths.readDirectory('assets/lang')){toLang.push(a.split("/").pop().replace(".json", "").replace("lang_", ""));}
        CURRENT_SETTINGS.get("Game Settings").get("Language")[1] = toLang;
        
        #if sys
        var toNote:Array<String> = [];
        for(a in Paths.readDirectory('assets/notes')){if(!FileSystem.isDirectory(a)){continue;} if(a.split("/").pop() == "Default"){continue;} toNote.push(a.split("/").pop());}
        CURRENT_SETTINGS.get("Visual Settings").get("Note Skin")[1] = toNote;
        #end

		if(PreSettings.getPreSetting("FrameRate", "Graphic Settings") > FlxG.drawFramerate){
			FlxG.updateFramerate = PreSettings.getPreSetting("FrameRate", "Graphic Settings");
			FlxG.drawFramerate = PreSettings.getPreSetting("FrameRate", "Graphic Settings");
		}else{
			FlxG.drawFramerate = PreSettings.getPreSetting("FrameRate", "Graphic Settings");
			FlxG.updateFramerate = PreSettings.getPreSetting("FrameRate", "Graphic Settings");
		}

        Main.Info.visible = PreSettings.getPreSetting("Visible Fps / Memory", "Other Settings");
        
        trace("PreSettings Loaded");
    }

    public static function saveSettings(){
        FlxG.save.data.PRESETTINGS = CURRENT_SETTINGS;
        FlxG.save.flush();
        
		if(PreSettings.getPreSetting("FrameRate", "Graphic Settings") > FlxG.drawFramerate){
			FlxG.updateFramerate = PreSettings.getPreSetting("FrameRate", "Graphic Settings");
			FlxG.drawFramerate = PreSettings.getPreSetting("FrameRate", "Graphic Settings");
		}else{
			FlxG.drawFramerate = PreSettings.getPreSetting("FrameRate", "Graphic Settings");
			FlxG.updateFramerate = PreSettings.getPreSetting("FrameRate", "Graphic Settings");
		}

        Main.Info.visible = PreSettings.getPreSetting("Visible Fps / Memory", "Other Settings");

		trace("PreSettings Saved Successfully!");
    }

    public static function resetSettings(){
        FlxG.save.data.PRESETTINGS = PRESETTINGS;
        FlxG.save.flush();
        loadSettings();
        trace("Options Reset Successfully!");
    }

    public static function getPreSetting(setting:String, category:String):Dynamic {
        var toReturn = CURRENT_SETTINGS.get(category).get(setting);
        if((toReturn is Array)){return toReturn[1][toReturn[0]];}
        return toReturn;
    }
    public static function getArrayPreSetting(setting:String, category:String):Array<String> {
        return CURRENT_SETTINGS.get(category).get(setting)[1];
    }

    public static function changePreSetting(setting:String, category:String, value:Int = 0){
        var check = CURRENT_SETTINGS.get(category).get(setting);
        if((check is Array)){
            check[0] += value;

            if(check[0] < 0){check[0] = check[1].length - 1;}
            if(check[0] >= check[1].length){check[0] = 0;}
        }
        else if((check is Bool)){check = !check;}
        else{check += value;}

        CURRENT_SETTINGS.get(category).set(setting, check);
    }

    public static function delPreSetting(setting:String, category:String){CURRENT_SETTINGS.get(category).remove(setting);}
    public static function addCategory(setting:String, options:Map<String, Dynamic>){PRESETTINGS.set(setting, options);}
    public static function delCategory(setting:String){PRESETTINGS.remove(setting);}
    public static function addArrayOption(option:String, setting:String, category:String){
        if(!CURRENT_SETTINGS.exists(category)){return;}
        if(!CURRENT_SETTINGS.get(category).exists(setting)){return;}
        if(!CURRENT_SETTINGS.get(category).get(setting)[1].contains(setting)){return;}
        CURRENT_SETTINGS.get(category).get(setting)[1].push(option);
    }
}