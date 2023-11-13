package states.editors;

import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIAssets;
import flixel.addons.ui.FlxUIButton;
import openfl.filters.ShaderFilter;
import flixel.sound.FlxSoundGroup;
import flixel.addons.ui.FlxUIGroup;
import openfl.events.IOErrorEvent;
import flixel.util.FlxStringUtil;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxArrayUtil;
import openfl.net.FileReference;
import flixel.addons.ui.FlxUI;
import flixel.sound.FlxSound;
import openfl.utils.ByteArray;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flash.geom.Rectangle;
import flixel.text.FlxText;
import openfl.events.Event;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import openfl.media.Sound;
import lime.ui.FileDialog;
import haxe.DynamicAccess;
import lime.utils.Assets;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxState;
import haxe.xml.Access;
import flixel.FlxG;
import haxe.Json;

import Song.SaverMaster;
import Character.AnimArray;
import Character.CharacterFile;
import FlxCustom.FlxCustomShader;
import FlxCustom.FlxCustomButton;
import FlxCustom.FlxUICustomList;
import FlxCustom.FlxUICustomButton;
import FlxCustom.FlxUICustomNumericStepper;

#if desktop
import Discord.DiscordClient;
import sys.FileSystem;
import sys.io.File;
#end

using SavedFiles;
using StringTools;

typedef StageJson = {
	var variables:Array<{Name:String, Value:Dynamic, Type:String}>;
    var objects:Array<{Name:String, Attributes:Array<{Name:String, Values:Dynamic}>, Values:Dynamic}>;
}
typedef StageObjectJson = {
    var variables:Array<{Name:String, PlaceHolder:Dynamic, Type:String}>;
    var load:Array<{type:String, instance:String}>;
	var imports:Dynamic;
    var variable:String;
    var source:String;
}

class StageEditorState extends MusicBeatState {
    public static var SCRIPT_SOURCE:StageScripManager;
    
    public var stage:Stage;
    public var canReload:Bool = false;
    private var reload:FlxText;

    var template_list:FlxUIGroup;
    var stage_objects_list:FlxUIGroup;
    var global_variable_gp:FlxUIGroup;
    var object_settings_gp:FlxUI;
    var current_object:StageObject;

    var OBJECTS:FlxUITabMenu;
    var MENU:FlxUITabMenu;
    var LAYERS:FlxUITabMenu;

    var camera_sprite:FlxSprite;

    var arrayFocus:Array<FlxUIInputText> = [];

    var camFollow:FlxObject;

    override function create(){
        if(SCRIPT_SOURCE == null){SCRIPT_SOURCE = new StageScripManager();}
        FlxG.sound.playMusic(Paths.music('break_song').getSound());

        #if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence('Editing Stage', '[Stage Editor]');
		MagicStuff.setWindowTitle('Editing...', 1);
		#end
        
        var bgGrid:FlxSprite = FlxGridOverlay.create(10, 10, FlxG.width, FlxG.height, true, 0xff4d4d4d, 0xff333333);
        bgGrid.cameras = [camGame];
        add(bgGrid);

        stage = new Stage("Stage", [
            ["Girlfriend", [540, 50], 1, false, "Default", "GF", 0],
            ["Daddy_Dearest", [100, 100], 1, true, "Default", "NORMAL", 0],
            ["Boyfriend", [770, 100], 1, false, "Default", "NORMAL", 0]
        ]);
        stage.loadStageByScriptSource(SCRIPT_SOURCE.export_source());
        stage.showCamPoints = true;
        stage.is_debug = true;
        stage.cameras = [camFGame];
        add(stage);
        
        for(char in stage.characterData){char.alpha = 0.5;}

        OBJECTS = new FlxUITabMenu(null, [{name: "1Objects", label: ''}], true);
        OBJECTS.resize(35, Std.int(FlxG.height));
        OBJECTS.camera = camHUD;
        addOBJECTSTABS();
        add(OBJECTS);
        
        LAYERS = new FlxUITabMenu(null, [{name: "1Layers", label: ''}], true);
        LAYERS.resize(50, Std.int(FlxG.height));
		LAYERS.x = FlxG.width - LAYERS.width;
        LAYERS.camera = camHUD;
        addLAYERSTABS();
        add(LAYERS);
        
        var menuTabs = [
            {name: "1Layers", label: 'Object Settings'},
            {name: "2Stage", label: 'Stage'},
        ];
        MENU = new FlxUITabMenu(null, menuTabs, true);
        MENU.resize(250, Std.int(FlxG.height));
		MENU.x = FlxG.width - LAYERS.width - MENU.width;
        MENU.camera = camHUD;
        addMENUTABS();
        add(MENU);

        camera_sprite = new FlxSprite().loadGraphic(Paths.image("camera_border").getGraphic());
        camera_sprite.scrollFactor.set(0,0);
        camera_sprite.cameras = [camFGame];
        camera_sprite.antialiasing = false;
        camera_sprite.alpha = 0.5;
        add(camera_sprite);

        reload = new FlxText(0,0,0,"You can Reload! [SPACE]", 16);
        reload.cameras = [camFHUD];
        reload.alpha = 0;
        add(reload);
        
        super.create();
        
        FlxG.mouse.visible = true;
        
		camFollow = new FlxObject(0, 0, 1, 1);
        camFollow.screenCenter();
        camFGame.follow(camFollow, LOCKON);
		add(camFollow);
    }

    override function destroy() {
        FlxG.sound.music.stop();
        super.destroy();
    }

    var pos = [[], []];
    override function update(elapsed:Float){
        var pMouse = FlxG.mouse.getPositionInCameraView(camFGame);

        var arrayControlle = true;
        for(item in arrayFocus){if(item.hasFocus){arrayControlle = false;}}

        if(canControlle && arrayControlle){    
            if(FlxG.mouse.justPressedRight){pos = [[camFollow.x, camFollow.y],[pMouse.x, pMouse.y]];}
            if(FlxG.mouse.pressedRight){camFollow.setPosition(pos[0][0] + ((pos[1][0] - pMouse.x) * 1.0), pos[0][1] + ((pos[1][1] - pMouse.y) * 1.0));}

            if(FlxG.mouse.overlaps(OBJECTS)){
                if((FlxG.mouse.wheel > 0 && template_list.y < FlxG.height - 40) || (FlxG.mouse.wheel < 0 && template_list.y + template_list.height > 45)){
                    template_list.y += FlxG.mouse.wheel * 5;
                }
            }else if(FlxG.mouse.overlaps(LAYERS)){
                if((FlxG.mouse.wheel > 0 && stage_objects_list.y < FlxG.height - 40) || (FlxG.mouse.wheel < 0 && stage_objects_list.y + stage_objects_list.height > 45)){
                    stage_objects_list.y += FlxG.mouse.wheel * 5;
                }
            }else if(FlxG.mouse.overlaps(MENU)){
                if((FlxG.mouse.wheel > 0 && object_settings_gp.y < FlxG.height - 40) || (FlxG.mouse.wheel < 0 && object_settings_gp.y + object_settings_gp.height > 45)){
                    object_settings_gp.y += FlxG.mouse.wheel * 5;
                }
            }else{
                if(FlxG.keys.pressed.SHIFT){
                    if(FlxG.mouse.justPressedMiddle){camFGame.zoom = stage.zoom;}
                    if(FlxG.mouse.wheel != 0){camFGame.zoom += (FlxG.mouse.wheel * 0.1);}
                }else{
                    if(FlxG.mouse.justPressedMiddle){camFollow.screenCenter();}
                    if(FlxG.mouse.wheel != 0){camFGame.zoom += (FlxG.mouse.wheel * 0.01);}
                }
            }

            if(canReload && FlxG.keys.justPressed.SPACE){reloadStage();}
        }

        if(canReload){
            reload.setPosition(FlxG.mouse.screenX - (reload.width / 2), FlxG.mouse.screenY - reload.height);
            reload.alpha = canReload ? 1 : 0;
        }        
        
        super.update(elapsed);
    
    }

    public function reloadStage():Void {
        stage.loadStageByScriptSource(SCRIPT_SOURCE.export_source());
        canReload = false;
        reload.alpha = 0;

        camera_sprite.scale.x = camera_sprite.scale.y = camHUD.zoom / stage.zoom;
        camera_sprite.screenCenter();
    }

    public function reload_templates():Void {
        template_list.clear();

        var last_height:Float = 0;
        for(i in Paths.readDirectory('assets/data/stage_editor_objects')){
            if(i.contains(".")){continue;}
            var object_name:String = i.split("/").pop();
            var template_obj:FlxUIButton = new FlxUICustomButton(0, last_height,Std.int(OBJECTS.width - 10), Std.int(OBJECTS.width - 10), "", Paths.image('stage_editor_objects/${object_name}'), null, function(){
                SCRIPT_SOURCE.add_object(object_name);
                reload_stage_objects();
                canReload = true;
            });
            template_list.add(template_obj);

            last_height += template_obj.height + 5;
        }
    }

    public function reload_stage_objects():Void {
        stage_objects_list.clear();
        
        SCRIPT_SOURCE.objects.sort((a, b) -> (a.ID - b.ID));

        var last_height:Float = 0;
        for(_object in SCRIPT_SOURCE.objects){
            var template_obj:FlxUIButton = new FlxUICustomButton(0, last_height, Std.int(LAYERS.width - 10), Std.int(LAYERS.width - 10), "", Paths.image('stage_editor_objects/${_object.name}'), null, function(){loadObjectSettings(_object);});
            template_obj.alpha = 0.5;
            stage_objects_list.add(template_obj);

            last_height += template_obj.height + 5;
        }

        if(current_object == null){return;}
        if(stage_objects_list.members.length < current_object.ID){return;}
        if(stage_objects_list.members[current_object.ID] == null){return;}
        stage_objects_list.members[current_object.ID].alpha = 1;
    }

    public function loadVariableSettings():Void {
        global_variable_gp.clear();

        var last_height:Float = 0;
        for(i in 0...SCRIPT_SOURCE.variables.length){
            var cur_var:Dynamic = SCRIPT_SOURCE.variables[i];

            var txtVariableName = new FlxUIInputText(0, last_height, Std.int(MENU.width - 30), cur_var.Name, 8, 0x000000);
            txtVariableName.name = 'global_variable:${i}:id';
            arrayFocus.push(txtVariableName);
            global_variable_gp.add(txtVariableName);

            var btnDeleteVariable = new FlxUICustomButton(txtVariableName.width, last_height, 20, 15, "-", 0xff3d3d, function(){
                SCRIPT_SOURCE.variables.remove(SCRIPT_SOURCE.variables[i]);
                loadVariableSettings();
                canReload = true;
            }); global_variable_gp.add(btnDeleteVariable);

            last_height += txtVariableName.height;

            switch(cur_var.Type){
                default:{
                    var chkCurrent_Variable = new FlxUICheckBox(0, last_height, null, null, cur_var.Name);
                    chkCurrent_Variable.checked = cur_var.Value;
                    chkCurrent_Variable.name = 'global_variable:${i}';
                    global_variable_gp.add(chkCurrent_Variable);
                    last_height += chkCurrent_Variable.height + 5;
                }
                case 'Float':{
                    var stpCurrent_Variable = new FlxUICustomNumericStepper(0, last_height, Std.int(MENU.width - 10), 0.1, cur_var.Value, -99999, 99999, 3);
                    stpCurrent_Variable.name = 'global_variable:${i}';
                    @:privateAccess arrayFocus.push(cast stpCurrent_Variable.text_field);
                    global_variable_gp.add(stpCurrent_Variable);
                    last_height += stpCurrent_Variable.height + 5;
                }
                case 'Int':{
                    var stpCurrent_Variable = new FlxUICustomNumericStepper(0, last_height, Std.int(MENU.width - 10), 1, cur_var.Value);
                    stpCurrent_Variable.name = 'global_variable:${i}';
                    @:privateAccess arrayFocus.push(cast stpCurrent_Variable.text_field);
                    global_variable_gp.add(stpCurrent_Variable);
                    last_height += stpCurrent_Variable.height + 5;
                }
                case 'String':{
                    var txtCurrent_Variable = new FlxUIInputText(0, last_height, Std.int(MENU.width - 10), cur_var.Value.replace('"', ''), 8);
                    txtCurrent_Variable.name = 'global_variable:${i}:string';
                    arrayFocus.push(txtCurrent_Variable);
                    global_variable_gp.add(txtCurrent_Variable); 
                    last_height += txtCurrent_Variable.height + 5;
                }
                case 'Array':{
                    var data:String = ""; try{data = Json.stringify(cur_var.Value);}catch(e){trace(e); data = "[]";}
                    var txtCurrent_Variable = new FlxUIInputText(0, last_height, Std.int(MENU.width - 10), data, 8);
                    txtCurrent_Variable.name = 'global_variable:${i}:array';
                    arrayFocus.push(txtCurrent_Variable);
                    global_variable_gp.add(txtCurrent_Variable);
                    last_height += txtCurrent_Variable.height + 5;
                }
            }
        }
    }

    function loadObjectSettings(?_object:StageObject):Void {
        current_object = _object;
        object_settings_gp.clear();
        var last_menu_height:Float = 10;

        for(b in stage_objects_list){b.alpha = 0.5;}

        if(current_object == null){return;}
        if(stage_objects_list.members[current_object.ID] == null){return;}

        stage_objects_list.members[current_object.ID].alpha = 1;

        var lblTtlObject = new FlxText(5, last_menu_height, Std.int(MENU.width - 10), Paths.getFileName(_object.name), 16); object_settings_gp.add(lblTtlObject); lblTtlObject.alignment = CENTER; last_menu_height += lblTtlObject.height + 10;

        var btnDeleteObject = new FlxUICustomButton(5, last_menu_height, Std.int(MENU.width - 10), null, "Delete Object", 0xf0ff4a4a, function(){
            SCRIPT_SOURCE.objects.remove(_object);
            for(i in 0...SCRIPT_SOURCE.objects.length){SCRIPT_SOURCE.objects[i].ID = i;}
            reload_stage_objects();
            loadObjectSettings();
            canReload = true;
        }); object_settings_gp.add(btnDeleteObject); last_menu_height += btnDeleteObject.height + 10;

        var btnMoveUp = new FlxUICustomButton(5, last_menu_height, Std.int((MENU.width - 10) / 2), null, "Move up", null, function(){
            if(SCRIPT_SOURCE.objects.length <= 1){return;}
            
            var new_id:Int = _object.ID - 1; if(new_id < 0){new_id = SCRIPT_SOURCE.objects.length - 1;}
            
            SCRIPT_SOURCE.objects[new_id].ID = _object.ID;
            _object.ID = new_id;
            
            reload_stage_objects();

            canReload = true;
        }); object_settings_gp.add(btnMoveUp);

        var btnMoveDown = new FlxUICustomButton(5 + btnMoveUp.width + 3, last_menu_height, Std.int((MENU.width - 10) / 2), null, "Move Down", null, function(){
            if(SCRIPT_SOURCE.objects.length <= 1){return;}

            var new_id:Int = _object.ID + 1; if(new_id >= SCRIPT_SOURCE.objects.length){new_id = 0;}
            
            SCRIPT_SOURCE.objects[new_id].ID = _object.ID;
            _object.ID = new_id;
            
            reload_stage_objects();
            
            canReload = true;
        }); object_settings_gp.add(btnMoveDown); last_menu_height += btnMoveUp.height + 10;

        var clAttList = new FlxUICustomList(5, last_menu_height, Std.int(MENU.width - 55), _object.get_attributes()); object_settings_gp.add(clAttList);
        var btnAddAtt = new FlxUICustomButton(5 + clAttList.width + 5, last_menu_height, 20, null, "+", null, 0x93ff79, function(){
            _object.add_attribute(clAttList.getSelectedLabel());
            loadObjectSettings(_object);
            canReload = true;
        }); object_settings_gp.add(btnAddAtt);
        var btnDelAtt = new FlxUICustomButton(10 + clAttList.width + btnAddAtt.width, last_menu_height, 20, null, "-", null, 0xff4747, function(){
            _object.del_attribute(clAttList.getSelectedLabel());
            loadObjectSettings(_object);
            canReload = true;
        }); object_settings_gp.add(btnDelAtt);
        last_menu_height += clAttList.height + 10;

        for(cur_var in _object.get_variables()){                    
            switch(cur_var.Type){
                default:{
                    var chkCurrent_Variable = new FlxUICheckBox(5, last_menu_height, null, null, Paths.getFileName(cur_var.Name));
                    chkCurrent_Variable.checked = _object.get_value(cur_var.Name);
                    chkCurrent_Variable.name = 'current_variable:${cur_var.Name}';
                    object_settings_gp.add(chkCurrent_Variable); last_menu_height += chkCurrent_Variable.height + 5;
                }
                case 'Float':{
                    var lblName_Object = new FlxText(5, last_menu_height, Std.int(MENU.width - 10), '${Paths.getFileName(cur_var.Name)}: ', 10); lblName_Object.alignment = CENTER; object_settings_gp.add(lblName_Object); last_menu_height += lblName_Object.height + 5;
                    var stpCurrent_Variable = new FlxUICustomNumericStepper(5, last_menu_height, Std.int(MENU.width - 10), 0.1, _object.get_value(cur_var.Name), -99999, 99999, 3);
                    stpCurrent_Variable.name = 'current_variable:${cur_var.Name}';
                    @:privateAccess arrayFocus.push(cast stpCurrent_Variable.text_field);
                    object_settings_gp.add(stpCurrent_Variable); last_menu_height += stpCurrent_Variable.height + 5;
                }
                case 'Int':{
                    var lblName_Object = new FlxText(5, last_menu_height, Std.int(MENU.width - 10), '${Paths.getFileName(cur_var.Name)}: ', 10); lblName_Object.alignment = CENTER; object_settings_gp.add(lblName_Object); last_menu_height += lblName_Object.height + 5;
                    var stpCurrent_Variable = new FlxUICustomNumericStepper(5, last_menu_height, Std.int(MENU.width - 10), 1, _object.get_value(cur_var.Name));
                    stpCurrent_Variable.name = 'current_variable:${cur_var.Name}';
                    @:privateAccess arrayFocus.push(cast stpCurrent_Variable.text_field);
                    object_settings_gp.add(stpCurrent_Variable); last_menu_height += stpCurrent_Variable.height + 5;
                }
                case 'String':{
                    var lblName_Object = new FlxText(5, last_menu_height, Std.int(MENU.width - 10), '${Paths.getFileName(cur_var.Name)}: ', 10); lblName_Object.alignment = CENTER; object_settings_gp.add(lblName_Object); last_menu_height += lblName_Object.height + 5;
                    var txtCurrent_Variable = new FlxUIInputText(5, last_menu_height, Std.int(MENU.width - 10), _object.get_value(cur_var.Name), 10);
                    txtCurrent_Variable.name = 'current_variable:${cur_var.Name}:string';
                    arrayFocus.push(txtCurrent_Variable);
                    object_settings_gp.add(txtCurrent_Variable); last_menu_height += txtCurrent_Variable.height + 5;
                }
                case 'Array':{
                    var lblName_Object = new FlxText(5, last_menu_height, Std.int(MENU.width - 10), '${Paths.getFileName(cur_var.Name)}: ', 10); lblName_Object.alignment = CENTER; object_settings_gp.add(lblName_Object); last_menu_height += lblName_Object.height + 5;
                    var txtCurrent_Variable = new FlxUIInputText(5, last_menu_height, Std.int(MENU.width - 10), Json.stringify(_object.get_value(cur_var.Name)), 10);
                    txtCurrent_Variable.name = 'current_variable:${cur_var.Name}:array';
                    arrayFocus.push(txtCurrent_Variable);
                    object_settings_gp.add(txtCurrent_Variable); last_menu_height += txtCurrent_Variable.height + 5;
                }
            }
        }

        MENU.showTabId("1Layers");
    }

    private function addOBJECTSTABS(){
        var tabStage = new FlxUI(null, OBJECTS);
        tabStage.name = "1Objects";

        template_list = new FlxUIGroup(5, 10);
        reload_templates();
        tabStage.add(template_list);
        
        ////////////////////////////////////////////////////////////
        OBJECTS.addGroup(tabStage);
        ////////////////////////////////////////////////////////////

        OBJECTS.showTabId("1Objects");
    }

    var txtStage:FlxUIInputText;
    var clTypeValue:FlxUICustomList;
    private function addMENUTABS(){
        var tabMENU = new FlxUI(null, MENU);
        tabMENU.name = "2Stage";

        var lblStage = new FlxText(5, 15, 0, "STAGE:", 8); tabMENU.add(lblStage);
        txtStage = new FlxUIInputText(lblStage.x + lblStage.width + 5, lblStage.y, Std.int(MENU.width - lblStage.width - 20), 'Stage', 8); tabMENU.add(txtStage);
        arrayFocus.push(txtStage);
        txtStage.name = "STAGE_NAME";

        var btnExportStage:FlxButton = new FlxCustomButton(5, txtStage.y + txtStage.height + 5, Std.int((MENU.width / 2) - 10), null, "Export Stage (.hx)", null, null, function(){
            if(!canControlle){return;} canControlle = false;
            var stage_file = new SaverMaster([{name:'${txtStage.text}.hx', data: SCRIPT_SOURCE.export_source()}], {destroyOnComplete: true, onComplete: function(){canControlle = true;}});
            stage_file.saveFile();
        }); tabMENU.add(btnExportStage);
        var btnSaveStage:FlxButton = new FlxCustomButton(btnExportStage.x + btnExportStage.width + 10, btnExportStage.y, Std.int((MENU.width / 2) - 10), null, "Save Stage (.json)", null, null, function(){
            if(!canControlle){return;} canControlle = false;
            var stage_file = new SaverMaster([{name:'${txtStage.text}.json', data: SCRIPT_SOURCE.save_source()}], {destroyOnComplete: true, onComplete: function(){canControlle = true;}});
            stage_file.saveFile();
        }); tabMENU.add(btnSaveStage);

        var btnLoad:FlxButton = new FlxCustomButton(btnExportStage.x, btnExportStage.y + btnExportStage.height + 5, Std.int((MENU.width / 2) - 10), null, "Load Stage", null, null, function(){
            SCRIPT_SOURCE.setup_by_source(Paths.getPath('data/saved_stages/${txtStage.text}.json', TEXT, null, null).getJson());
            reload_stage_objects();
            loadVariableSettings();
            reloadStage();
        }); tabMENU.add(btnLoad);
        var btnImport:FlxButton = new FlxCustomButton(btnLoad.x + btnLoad.width + 10, btnLoad.y, Std.int((MENU.width / 2) - 10), null, "Import Stage", null, null, function(){
                getFile(function(str){
                    SCRIPT_SOURCE.setup_by_source(str.getJson());
                    reload_stage_objects();
                    loadVariableSettings();
                    reloadStage();
                });
        }); tabMENU.add(btnImport);

        var line0 = new FlxSprite(5, btnLoad.y + btnLoad.height + 5).makeGraphic(Std.int(MENU.width - 10), 2, FlxColor.BLACK); tabMENU.add(line0);

        var ttlGeneralVariables:FlxText = new FlxText(0, line0.y + 5, MENU.width, "GLOBAL STAGE VALUES", 16); ttlGeneralVariables.alignment = CENTER; tabMENU.add(ttlGeneralVariables);

        var btnPressetVariable = new FlxCustomButton(5, ttlGeneralVariables.y + ttlGeneralVariables.height + 5, Std.int((MENU.width) - 10), null, "Presset Variable", null, null, function(){
            var vari_value:Dynamic = false;
            switch(clTypeValue.getSelectedLabel()){
                case 'Float', 'Int':{vari_value = 0;}
                case 'String':{vari_value = "";}
                case 'Array':{vari_value = [];}
            }
            
            SCRIPT_SOURCE.variables.push({Name:"PlaceHolder", Value:vari_value, Type: clTypeValue.getSelectedLabel()});
            loadVariableSettings();
            canReload = true;
        }); tabMENU.add(btnPressetVariable);

        clTypeValue = new FlxUICustomList(5, btnPressetVariable.y + btnPressetVariable.height, Std.int(MENU.width - 10), ["Bool", "String", "Int", "Float", "Array"]);
        clTypeValue.setPrefix("Type: ");
        tabMENU.add(clTypeValue);
        
        global_variable_gp = new FlxUIGroup(5, clTypeValue.y + clTypeValue.height + 5);
        tabMENU.add(global_variable_gp);
        loadVariableSettings();

        ////////////////////////////////////////////////////////////
        MENU.addGroup(tabMENU);
        ////////////////////////////////////////////////////////////

        object_settings_gp = new FlxUI(null, MENU);
        object_settings_gp.name = "1Layers";

        ////////////////////////////////////////////////////////////
        MENU.addGroup(object_settings_gp);

        var lblPlaceHolder = new FlxText(5, 10, Std.int(MENU.width - 10), "Click on an Object to view its Properties", 16);
        object_settings_gp.add(lblPlaceHolder);
        ////////////////////////////////////////////////////////////

        MENU.showTabId("2Stage");
    }

    private function addLAYERSTABS():Void {
        var tabLAYER = new FlxUI(null, LAYERS);
        tabLAYER.name = "1Layers";

        stage_objects_list = new FlxUIGroup(5, 10);
        reload_stage_objects();
        tabLAYER.add(stage_objects_list);
        
        ////////////////////////////////////////////////////////////
        LAYERS.addGroup(tabLAYER);
        ////////////////////////////////////////////////////////////

        LAYERS.showTabId("1Layers");
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>){
        if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)){
            var input:FlxUIInputText = cast sender;
            var wname = input.name;
            if(wname.contains("current_variable")){
                var object_variable:String = wname.split(":")[1];
                var type_variable:String = wname.split(":")[2];

                switch(type_variable){
                    default:{
                        current_object.set_value(object_variable, input.text);
                    }
                    case "array":{
                        var data:Array<Dynamic> = [];
                        try{data = (cast Json.parse('{ "Events": ${input.text} }')).Events; input.color = FlxColor.BLACK;}catch(e){trace(e); input.color = FlxColor.RED;}
                        
                        current_object.set_value(object_variable, data);
                    }
                }

                canReload = true;
            }else if(wname.contains("global_variable")){
                var object_variable:Int = Std.parseInt(wname.split(":")[1]);
                var type_variable:String = wname.split(":")[2];

                switch(type_variable){
                    default:{SCRIPT_SOURCE.variables[object_variable].Value = '"${input.text}"';}
                    case "array":{
                        var data:Array<Dynamic> = [];
                        try{data = (cast Json.parse('{ "Events": ${input.text} }')).Events; input.color = FlxColor.BLACK;}catch(e){trace(e); input.color = FlxColor.RED;}
                        
                        SCRIPT_SOURCE.variables[object_variable].Value = data;
                    }
                    case "id":{SCRIPT_SOURCE.variables[object_variable].Name = input.text;}
                }

                canReload = true;
            }
        }else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)){
            var nums:FlxUINumericStepper = cast sender;
            var wname = nums.name;
            if(wname.contains("current_variable")){
                var object_variable:String = wname.split(":")[1];
                current_object.set_value(object_variable, nums.value);
                
                canReload = true;
            }else if(wname.contains("global_variable")){
                var object_variable:Int = Std.parseInt(wname.split(":")[1]);

                SCRIPT_SOURCE.variables[object_variable].Value = nums.value;

                canReload = true;
            }
        }else if(id == FlxUICheckBox.CLICK_EVENT){
            var check:FlxUICheckBox = cast sender;
            var wname = check.name;
            if(wname.contains("current_variable")){
                var object_variable:String = wname.split(":")[1];
                current_object.set_value(object_variable, check.checked);

                canReload = true;
            }else if(wname.contains("global_variable")){
                var object_variable:Int = Std.parseInt(wname.split(":")[1]);
                                
                SCRIPT_SOURCE.variables[object_variable].Value = check.checked;

                canReload = true;
            }
        }
    }
    
    var onReload:Bool = false;
    private function getFile(_onSelect:String->Void):Void {
        if(onReload){return;} onReload = true;

        var fDialog = new FileDialog();
        fDialog.onSelect.add(function(str){onReload = false; _onSelect(str);});
        fDialog.browse();
	}
}

class StageScripManager {
    public var objects:Array<StageObject> = [];
    public var variables:Array<Dynamic> = [];

    public function new(?src:StageJson):Void {
        if(src == null){return;}
        setup_by_source(src);
    }

    public function setup_by_source(new_source:StageJson):Void {
        objects = []; variables = [];        
        if(new_source == null){return;}

        variables = new_source.variables;

        for(obj in new_source.objects){
            var new_object:StageObject = new StageObject(obj.Name);
            new_object.values = obj.Values;

            for(att in obj.Attributes){
                new_object.add_attribute(att.Name);
                new_object.get_attribute(att.Name).values = att.Values;
            }

            objects.push(new_object);
            new_object.ID = objects.length - 1;
        }        
    }

    public function add_object(name:String){
        var new_object:StageObject = new StageObject(name);
        objects.push(new_object);
        new_object.ID = objects.length - 1;
    }
        
    public function export_source():String {
        var to_return:String = "";

        var total_imports:Dynamic = {};
        var total_load:Array<String> = [];
        var total_variables:Array<String> = [];
        
        for(obj in objects){
            total_variables.push(obj.get_variable());

            for(lod in obj.load){
                total_load.push('temp.push({type: "${lod.type}", instance: ${obj.parse_string(lod.instance)}});');
            }
            for(imp in Reflect.fields(obj.imports)){
                Reflect.setProperty(total_imports, imp, Reflect.getProperty(obj.imports, imp));
            }

            for(att in obj.attributes){
                for(lod in att.load){
                    total_load.push('temp.push({type: "${lod.type}", instance: ${obj.parse_string(lod.instance)}});');
                }
                for(att_imp in Reflect.fields(att.imports)){
                    Reflect.setProperty(total_imports, att_imp, Reflect.getProperty(att.imports, att_imp));
                }
            }
        }
        for(imp in Reflect.fields(total_imports)){
            to_return += 'import("${imp}", "${Reflect.getProperty(total_imports, imp)}");\n';
        }

        to_return += '\n';

        for(pre in variables){
            to_return += 'preset("${pre.Name}", ${pre.Value});\n';
        }

        to_return += '\n';

        for(v in total_variables){
            to_return += '${v}\n';
        }

        to_return += '\nfunction addToLoad(temp):Void {\n';
        
        for(v in total_load){
            to_return += '\t${v}\n';
        }

        to_return += '}\n';
        
        to_return += '\nfunction create():Void {\n';

        for(obj in objects){
            to_return += '${obj.build(1)}\n\n';
        }

        to_return += '}';

        return to_return;
    }

    public function save_source():String {
        var to_save:Dynamic = {
            variables: variables,
            objects: []
        };

        for(obj in objects){
            var to_add:Dynamic = {
                Name: obj.name,
                Attributes: [],
                Values: obj.values
            };

            for(att in obj.attributes){
                var to_att:Dynamic = {
                    Name: att.name,
                    Values: att.values
                };

                to_add.Attributes.push(to_att);
            }

            to_save.objects.push(to_add);
        }

        return Json.stringify(to_save,"\t");
    }
}

class StageObject {
    public var load:Array<{type:String, instance:String}> = [];
    public var attributes:Array<StageObject> = [];
    public var variables:Array<Dynamic> = [];
    public var variable:String = "";
    public var imports:Dynamic = {};
    public var values:Dynamic = {};
    public var source:String = "";
    public var name:String = "";

    public var ID:Int = 0;

    public function new(_name:String, ?_att:String):Void {
        set_object(_name, _att);
    }

    public function set_object(_name:String, ?_att:String):Void {
        this.name = _name;

        var obj_path:String = Paths.getPath('data/stage_editor_objects/${name}/${_att != null ? 'att-${_att}' : name}.json', TEXT, null, null);
        if(!Paths.exists(obj_path)){return;}
        var template_object:StageObjectJson = obj_path.getJson();

        this.variables = template_object.variables;
        this.variable = template_object.variable;
        this.imports = template_object.imports;
        this.source = template_object.source;
        this.load = template_object.load;

        for(v in this.variables){Reflect.setProperty(this.values, v.Name, v.PlaceHolder);}
    }

    public function get_value(value_name:String):Dynamic {
        if(Reflect.hasField(values, value_name)){return Reflect.getProperty(values, value_name);}
        for(att in attributes){if(!Reflect.hasField(att.values, value_name)){continue;} return Reflect.getProperty(att.values, value_name);}
        return null;
    }
    public function set_value(value_name:String, value_value:Dynamic):Void {
        if(Reflect.hasField(values, value_name)){Reflect.setProperty(values, value_name, value_value); return;}
        for(att in attributes){if(!Reflect.hasField(att.values, value_name)){continue;} Reflect.setProperty(att.values, value_name, value_value); return;}
    }

    public function get_variables():Array<Dynamic> {
        var to_return:Array<Dynamic> = [];
        for(v in variables){to_return.push(v);}
        for(a in attributes){for(va in a.variables){to_return.push(va);}}
        return to_return;
    }

    public function get_variable():String {
        var to_return:String = variable;
        var total_values:Dynamic = get_values();
        for(v in Reflect.fields(total_values)){to_return = to_return.replace('#${v}#', Reflect.getProperty(total_values, v));}
        
        return to_return;
    }

    public function get_attributes():Array<String> {
        var to_return:Array<String> = [];

        for(pos_att in Paths.readDirectory('assets/data/stage_editor_objects/${name}')){
            pos_att = pos_att.split("/").pop().replace(".json", "").replace("att-", "");
            if(pos_att == name){continue;}
            to_return.push(pos_att);
        }

        return to_return;
    }
    
    public function get_tild(cur_tild:Int):String {
        var to_return:String = '';
        for(i in 0...cur_tild){to_return += '\t';}
        return to_return;
    }

    public function build(cur_tild:Int = 0):String {
        var to_return:String = '${get_tild(cur_tild)}${source}', att_source:String = "";
        for(a in attributes){att_source += '${a.source}\n';}
        to_return = to_return.replace('@Attributes@', att_source);
        
        var total_values:Dynamic = get_values();
        for(v in Reflect.fields(total_values)){to_return = to_return.replace('#${v}#', Reflect.getProperty(total_values, v));}

        to_return = to_return.replace('\n', '\n${get_tild(cur_tild)}');

        return to_return;
    }

    public function parse_string(to_parse:String):String {
        var to_return:String = to_parse;
        var total_values:Dynamic = get_values();
        for(v in Reflect.fields(total_values)){to_return = to_return.replace('#${v}#', Reflect.getProperty(total_values, v));}
        return to_return;
    }
    public function get_values():Dynamic {
        var total_values:Dynamic = {};
        for(v in Reflect.fields(values)){Reflect.setProperty(total_values, v, Reflect.getProperty(values, v));}
        for(a in attributes){for(v in Reflect.fields(a.values)){Reflect.setProperty(total_values, v, Reflect.getProperty(a.values, v));}}
        return total_values;
    }

    public function add_attribute(att_name:String):Void {
        for(cur_att in attributes){
            if(cur_att.name != att_name){continue;}
            return;
        }

        var new_att:StageObject = new StageObject(name, att_name);
        new_att.name = att_name;
        attributes.push(new_att);
    }
    
    public function del_attribute(att_name:String):Void {
        for(cur_att in attributes){
            if(cur_att.name != att_name){continue;}
            attributes.remove(cur_att); break;
        }
    }

    public function get_attribute(att_name:String):Dynamic {
        for(att in attributes){
            if(att.name != att_name){continue;}
            return att;
        }
        return null;
    }
}