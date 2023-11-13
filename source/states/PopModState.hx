package states;

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

import FlxCustom.FlxUICustomButton;

using SavedFiles;
using StringTools;

class PopModState extends MusicBeatState {
    private var toNext:String;

    override public function create():Void{
        if(onConfirm != null){toNext = onConfirm; onConfirm = null;}else{toNext = "states.TitleState";}

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBG').getGraphic());
        bg.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height)); bg.screenCenter();
        bg.color = 0xff7dffd8;
        add(bg);
        
        var lblAdvice_1:Alphabet = new Alphabet(0,0,LangSupport.getText('mod_advert')); add(lblAdvice_1);
        lblAdvice_1.screenCenter(); lblAdvice_1.y -= 120;
        
        var btnNo = new FlxUICustomButton(0, 0, 80, 80, "", Paths.image("tach"), null, function(){
            MagicStuff.reload_data();
            MusicBeatState.loadState(toNext, [], []);
        });
        btnNo.antialiasing = true;
        btnNo.screenCenter(); btnNo.y += 25; btnNo.x -= btnNo.width; add(btnNo);

        var btnYes = new FlxUICustomButton(0, 0, 100, 100, "", Paths.image("like"), null, function(){MusicBeatState.switchState("states.ModListState", [TitleState, null]);});
        btnYes.antialiasing = true;
        btnYes.screenCenter(); btnYes.y += 25; btnYes.x += btnYes.width; add(btnYes);

        super.create();
        
        FlxG.mouse.visible = true;
    }
}