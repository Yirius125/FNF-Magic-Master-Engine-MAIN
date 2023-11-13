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
import openfl.utils.AssetType;
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
import flixel.FlxState;
import flixel.FlxG;
import haxe.Json;

import flixel.addons.ui.*;

#if desktop
import Discord.DiscordClient;
import sys.FileSystem;
import sys.io.File;
#end

import FlxCustom.FlxCustomShader;
import FlxCustom.FlxUICustomButton;
import ModSupport.Mod;

using SavedFiles;
using StringTools;

class ModListState extends MusicBeatState {
    public static var isFirst:Bool = true;

    private var ModsList:FlxTypedGroup<ItemMod>;
    private var index:Int = 0;

    private var btnToggleAll:FlxUIButton;
    private var btnEnableAll:FlxUIButton;
    private var btnDisableAll:FlxUIButton;
    private var btnReady:FlxUIButton;

    private var toNext:String;

	override public function create():Void {
        if(!isFirst){for(s in ModSupport.modDataScripts){s.exFunction("onExit");}}
        isFirst = false;

        if(FlxG.sound.music != null){FlxG.sound.music.stop();}

        if(onConfirm != null){toNext = onConfirm; onConfirm = null;}

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBG').getGraphic());
        bg.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height)); bg.screenCenter();
        bg.color = 0xff77ffd6;
        add(bg);

        ModsList = new FlxTypedGroup<ItemMod>();
        var i:Int = 0;
        for(mod in ModSupport.MODS){
            var modCard:ItemMod = new ItemMod(mod);
            modCard.onButton = function(){changeIndex();}
            modCard.ID = i; modCard.x = 10;

            ModsList.add(modCard);
            i++;
        }
        add(ModsList);

        changeIndex();
        
        var hud_up:FlxSprite = new FlxSprite(0,-5).loadGraphic(Paths.image("upBar").getGraphic()); add(hud_up);
        var hud_down:FlxSprite = new FlxSprite().loadGraphic(Paths.image("downBar").getGraphic()); hud_down.y = FlxG.height - hud_down.height; add(hud_down);

        btnToggleAll = new FlxUICustomButton(100, 620, 100, 100, '', Paths.image("toggle_button"), null, function(){for(i in ModsList.members){i.setToggleEnableMod();}}); 
        add(btnToggleAll);

        btnEnableAll = new FlxUICustomButton(400, 620, 100, 100, '', Paths.image("on_button"), null, function(){for(i in ModsList.members){i.setToggleEnableMod(true);}}); 
        add(btnEnableAll);

        btnDisableAll = new FlxUICustomButton(700, 620, 100, 100, '', Paths.image("off_button"), null, function(){for(i in ModsList.members){i.setToggleEnableMod(false);}});
        add(btnDisableAll);
        
        btnReady = new FlxUICustomButton(1050, 560, 170, 170, '', Paths.image("accept_button"), null, onReady);
        add(btnReady);
        
        var lblModList = new Alphabet(10,20,LangSupport.getText("mod_list")); add(lblModList);

		super.create();
        
        FlxG.mouse.visible = true;
	}

	override function update(elapsed:Float){        
        super.update(elapsed);

        if(FlxG.keys.justPressed.UP){changeIndex(-1);}
        if(FlxG.keys.justPressed.DOWN){changeIndex(1);}
        if(FlxG.mouse.wheel > 0){changeIndex(-1);}
        if(FlxG.mouse.wheel < 0){changeIndex(1);}

        if(FlxG.mouse.justPressedRight){for(c in ModsList){if(FlxG.mouse.overlaps(c) && c.ID != index){index = c.ID; changeIndex();}}}

        var selectedCard = ModsList.members[index];
        MagicStuff.sortMembersByY(cast ModsList, (FlxG.height / 2) - (selectedCard.height / 2), index, 10, 0.5);
	}

    public function changeIndex(change:Int = 0){
        rePositionItems();

        index += change;

        if(index < 0){index = ModsList.length - 1;}
        if(index >= ModsList.length){index = 0;}

        for(i in 0...ModsList.length){
            var modCard:ItemMod = ModsList.members[i];

            modCard._selected = false;
            modCard.showTabId("4ModUnSelected");
        }
        
        ModsList.members[index]._selected = true;
        ModsList.members[index].showTabId("1ModName");
        
        #if desktop MagicStuff.setWindowTitle('Checking Mods > ${ModsList.members[index].refMod.name} [${ModsList.members[index].refMod.enabled ? "O" : "X"}] <'); DiscordClient.changePresence('> ${ModsList.members[index].refMod.name} [${ModsList.members[index].refMod.enabled ? "✓": "X"}] <', '[Checking Mods]'); #end
    }
    
    public function rePositionItems():Void{
        for(i in 0...ModSupport.MODS.length){
            if(ModsList.members[i].refMod != ModSupport.MODS[i]){
                for(ii in 0...ModsList.members.length){
                    if(ModsList.members[ii].refMod == ModSupport.MODS[i]){
                        ModsList.members[i].ID = ii;
                        ModsList.members[ii].ID = i;
                        break;
                    }
                }
            }
        }

        ModsList.members.sort((a, b) -> Std.int(a.ID - b.ID));
    }

    public function onReady():Void {
        MagicStuff.reload_data();
        MusicBeatState.loadState(toNext, [], []);
    }
}

class ItemMod extends FlxUITabMenu {
    public var refMod:Mod;
    public var mScript:Script;

    public var _selected:Bool = false;

    public var _btnToggle:FlxUICustomButton;
    public var _btnMoveUp:FlxUICustomButton;
    public var _btnMoveDown:FlxUICustomButton;

    public var openSize:FlxPoint;
    public var closedSize:FlxPoint;
    public var delay:Float = 0.3;

    public var onButton:Void -> Void = function(){};
    
    public function new(mod:Mod){
        this.refMod = mod;
 
        mScript = new Script();
        mScript.setVariable("getInstance", function(){return this;});
        mScript.setVariable("mod", refMod);

        var script_path = '${refMod.path}/itemMod.hx';
        if(Paths.exists(script_path)){
            mScript.exScript(script_path.getText());
        }else{
            mScript.exScript(Paths.getPath('data/item_mod_template.hx', TEXT, null, null).getText());
        }

        var back_ = new FlxUI9SliceSprite(0, 0, Paths.image("custom_default_chrome_flat", null, refMod.name).getGraphic(), new Rectangle(0, 0, 100, 100), [20, 20, 78, 78], FlxUI9SliceSprite.TILE_BOTH);

        super(back_, null, []);
        resize(Std.int(FlxG.width - 20), 300);

        openSize = new FlxPoint(FlxG.width - 20, 300);
        closedSize = new FlxPoint(FlxG.width - 20, 75);
              
        mScript.exFunction("create");

        _btnToggle = new FlxUICustomButton(0,0,80,20,"", Paths.image(!refMod.enabled ? "disable_button" : "enabled_button", null, refMod.name), null, function(){setToggleEnableMod(); onButton();});
        _btnToggle.setPosition(this.width - _btnToggle.width - 5, -(_btnToggle.height));
        _btnToggle.antialiasing = true;
        add(_btnToggle);
        
        _btnMoveUp = new FlxUICustomButton(0,5,30,15,"", Paths.image("up_button", null, refMod.name), null, function(){ModSupport.moveMod(this.ID, true); onButton();});
        _btnMoveUp.setPosition(_btnToggle.x - _btnMoveUp.width, -(_btnMoveUp.height));
        _btnMoveUp.antialiasing = true;
        add(_btnMoveUp);
        
        _btnMoveDown = new FlxUICustomButton(0,5,30,15,"", Paths.image("down_button", null, refMod.name), null, function(){ModSupport.moveMod(this.ID, false); onButton();});
        _btnMoveDown.setPosition(_btnMoveUp.x - _btnMoveDown.width, -(_btnMoveDown.height));
        _btnMoveDown.antialiasing = true;
        add(_btnMoveDown);

        setToggleEnableMod(refMod.enabled);

        calcBounds();
    }

    public function setToggleEnableMod(?set:Bool){
        if(set == null){set = !refMod.enabled;}

        refMod.enabled = set;

        _btnToggle.setButtonFrames(Paths.image(!refMod.enabled ? "disable_button" : "enabled_button", null, refMod.name));
    }

    override function update(elapsed:Float){
		super.update(elapsed);

        var curSize:FlxPoint = closedSize;
        if(_selected){
            curSize = openSize;
            if(this.selected_tab_id != "Selected"){this.showTabId("Selected");}
        }else if(this.selected_tab_id != "UnSelected"){
            this.showTabId("UnSelected");
        }
        if((this.width < curSize.x - 5 || this.width > curSize.x + 5) || (this.height < curSize.y - 5 || this.height > curSize.y + 5)){resize(FlxMath.lerp(this.width, curSize.x, delay), FlxMath.lerp(this.height, curSize.y, delay));}
	
        mScript.exFunction("update", [elapsed]);
    }

    override public function replaceBack(newBack:FlxSprite):Void {
        var i:Int = members.indexOf(_back);
        if(i != -1){
            var oldBack = _back;
            if((newBack is IResizable)){
                var ir:IResizable = cast newBack;
                ir.resize(oldBack.width, oldBack.height);
            }
            newBack.x = oldBack.x;
            newBack.y = oldBack.y;
            members[i] = newBack;
            _back = newBack;
            oldBack.destroy();
        }
    }
}