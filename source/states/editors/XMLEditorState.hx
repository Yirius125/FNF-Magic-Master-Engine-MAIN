package states.editors;

import flixel.graphics.frames.FlxFramesCollection.FlxFrameCollectionType;
import flixel.graphics.frames.FlxAtlasFrames.TexturePackerObject;
import flixel.system.FlxAssets.FlxTexturePackerSource;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.display.FlxGridOverlay;
import openfl.events.IOErrorEvent;
import flixel.graphics.FlxGraphic;
import openfl.net.FileReference;
import flash.geom.Rectangle;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import openfl.events.Event;
import flixel.math.FlxRect;
import lime.ui.FileDialog;
import flixel.FlxSprite;
import haxe.xml.Access;
import openfl.Assets;
import haxe.Json;

import Script;
import FlxCustom.FlxUICustomList;
import FlxCustom.FlxCustomButton;
import FlxCustom.FlxUICustomButton;
import FlxCustom.FlxUIValueChanger;
import FlxCustom.FlxUICustomNumericStepper;

#if desktop
import Discord.DiscordClient;
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class XMLEditorState extends MusicBeatState {
    private static var _XML:Access;
    private static var _IMG:FlxGraphic;

    var tabFILE:FlxUITabMenu;
    var tabGHOST:FlxUITabMenu;
    var tabSPRITE:FlxUITabMenu;
    
    var point:FlxSprite;
    var camPoint:FlxSprite;
    var sizePoint:FlxSprite;

    var imgIcon:FlxSprite;
    var bSprite:FlxSprite;
    var eSprite:FlxSprite;
    
    var arrayFocus:Array<FlxUIInputText> = [];

    var camFollow:FlxObject;

    public static function editXML(?onConfirm:Class<FlxState>, ?onBack:Class<FlxState>){
        FlxG.sound.music.stop();
        MusicBeatState.switchState(new XMLEditorState(onConfirm, onBack));
    }

    override function create(){
        #if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence('Editing', '[XML Editor]');
		MagicStuff.setWindowTitle('On XML Editor', 1);
		#end
        FlxG.mouse.visible = true;

        var bgGrid:FlxSprite = FlxGridOverlay.create(10, 10, FlxG.width, FlxG.height, true, 0xff4d4d4d, 0xff333333);
        bgGrid.cameras = [camGame];
        add(bgGrid);

        //SPRITES
        bSprite = new FlxSprite();
        bSprite.alpha = 0.3;
        bSprite.color = FlxColor.GRAY;
        bSprite.cameras = [camFGame];
        
        eSprite = new FlxSprite();
        eSprite.cameras = [camFGame];

        imgIcon = new FlxSprite(5, 5);
        imgIcon.cameras = [camHUD];

        add(eSprite);
        add(bSprite);

        add(imgIcon);

        point = new FlxSprite(100, 50).makeGraphic(5, 5, FlxColor.WHITE);
        point.cameras = [camFGame];
        add(point);
        
        camPoint = new FlxSprite(0, 0).makeGraphic(5, 5, FlxColor.WHITE);
        camPoint.cameras = [camFGame];
        add(camPoint);

        sizePoint = new FlxSprite(0, 0).makeGraphic(5, 5, FlxColor.WHITE);
        sizePoint.cameras = [camFGame];
        add(sizePoint);

        tabFILE = new FlxUITabMenu(null, [{name: "Files", label: 'Files'}], true);
        tabFILE.resize(250, 130);
		tabFILE.x = FlxG.width - tabFILE.width;
        tabFILE.camera = camHUD;
        addFILETABS();
        
        tabGHOST = new FlxUITabMenu(null, [{name: "Ghost", label: 'Ghost'}], true);
        tabGHOST.resize(250, 100);
		tabGHOST.y = tabFILE.height;
		tabGHOST.x = tabFILE.x;
        tabGHOST.camera = camHUD;
        addGHOSTTABS();

        tabSPRITE = new FlxUITabMenu(null, [{name: "General", label: 'General'}], true);
        tabSPRITE.resize(250, FlxG.height - tabFILE.height - tabGHOST.height);
        tabSPRITE.y = tabGHOST.y + tabGHOST.height;
		tabSPRITE.x = tabFILE.x;
        tabSPRITE.camera = camHUD;
        addFRAMESTABS();

        add(tabFILE);
        add(tabGHOST);
        add(tabSPRITE);
        
		camFollow = new FlxObject(0, 0, 1, 1);
        camFollow.screenCenter();
        camFGame.follow(camFollow, LOCKON);
		add(camFollow); 

        super.create();
    }

    var pos = [[], []];
    override function update(elapsed:Float){
        var pMouse = FlxG.mouse.getPositionInCameraView(camFGame);

        bSprite.setPosition(point.x, point.y);
        eSprite.setPosition(point.x, point.y);

        camPoint.setPosition(eSprite.getGraphicMidpoint().x, eSprite.getGraphicMidpoint().y);
        sizePoint.setPosition(eSprite.x + eSprite.width, eSprite.y + eSprite.height);

        var arrayControlle = true;
        for(item in arrayFocus){if(item.hasFocus){arrayControlle = false;}}

        if(canControlle && arrayControlle){    
            if(FlxG.mouse.justPressedRight){pos = [[camFollow.x, camFollow.y],[pMouse.x, pMouse.y]];}
            if(FlxG.mouse.pressedRight){camFollow.setPosition(pos[0][0] + ((pos[1][0] - pMouse.x) * 1.0), pos[0][1] + ((pos[1][1] - pMouse.y) * 1.0));}

            if(FlxG.keys.pressed.SHIFT){
                if(FlxG.mouse.wheel != 0){camFGame.zoom += (FlxG.mouse.wheel * 0.1);} 
                
                if(FlxG.keys.justPressed.W){vchCurFrameHeight.change(true);}
                if(FlxG.keys.justPressed.A){vchCurFrameWidth.change(true);}
                if(FlxG.keys.justPressed.S){vchCurFrameHeight.change();}
                if(FlxG.keys.justPressed.D){vchCurFrameWidth.change();}
                
                if(FlxG.keys.justPressed.I){vchCurHeight.change(true);}
                if(FlxG.keys.justPressed.J){vchCurWidth.change(true);}
                if(FlxG.keys.justPressed.K){vchCurHeight.change();}
                if(FlxG.keys.justPressed.L){vchCurWidth.change();}
            }else{
                if(FlxG.mouse.wheel != 0){camFGame.zoom += (FlxG.mouse.wheel * 0.01);}

                if(FlxG.keys.justPressed.W){vchCurFrameY.change(true);}
                if(FlxG.keys.justPressed.A){vchCurFrameX.change(true);}
                if(FlxG.keys.justPressed.S){vchCurFrameY.change();}
                if(FlxG.keys.justPressed.D){vchCurFrameX.change();}
                
                if(FlxG.keys.justPressed.I){vchCurY.change(true);}
                if(FlxG.keys.justPressed.J){vchCurX.change(true);}
                if(FlxG.keys.justPressed.K){vchCurY.change();}
                if(FlxG.keys.justPressed.L){vchCurX.change();}
            }

            if(FlxG.mouse.justPressedMiddle){camFollow.screenCenter();}
        }
        
		super.update(elapsed);
    }

    private function getFile(_file:FlxUIInputText):Void{
        var fDialog = new FileDialog();
        fDialog.onSelect.add(function(str){_file.text = str;});
        fDialog.browse();
	}
    
    private function loadArchives():Void{
        #if sys
            if(txtIMAGE.text.length > 0){_IMG = FlxGraphic.fromBitmapData(BitmapData.fromFile(txtIMAGE.text));}
            if(txtXML.text.length > 0){
                _XML = new Access((Xml.parse(File.getContent(txtXML.text))).firstElement());
                for(elm in _XML.elements){
                    if(!elm.has.x){elm.att.x = "0";}
                    if(!elm.has.y){elm.att.y = "0";}
                    if(!elm.has.width){elm.att.width = "0";}
                    if(!elm.has.height){elm.att.height = "0";}
                    if(!elm.has.frameX){elm.att.frameX = "0";}
                    if(!elm.has.frameY){elm.att.frameY = "0";}
                    if(!elm.has.frameWidth){elm.att.frameWidth = "0";}
                    if(!elm.has.frameHeight){elm.att.frameHeight = "0";}
                }
            }
        #end
    }

    private function loadGhostSprites():Void {
        #if sys
            bSprite.frames = FlxAtlasFrames.fromSparrow(BitmapData.fromFile(txtIMAGE.text), File.getContent(txtXML.text));

            var animArr = getNamesArray(new Access((Xml.parse(File.getContent(txtXML.text))).firstElement()).elements);
            for(anim in animArr){bSprite.animation.addByPrefix(anim, anim);}
            clGCurAnim.setData(animArr);

            stpGCurFrame.value = 0;
        #end
    }
    private function loadNormalSprites():Void {
        loadESprite();
        
        imgIcon.loadGraphic(_IMG);
        imgIcon.setGraphicSize(Std.int(15 * FlxG.height / 100), Std.int(15 * FlxG.height / 100));
        imgIcon.updateHitbox();
        
        clCurAnim.setData(getNamesArray(_XML.elements));

        stpCurFrame.value = 0;
    }
    private function loadESprite():Void {
        var values:Array<Dynamic> = null;
        if(eSprite != null && eSprite.animation.curAnim != null){values = [eSprite.animation.curAnim.name, eSprite.animation.curAnim.curFrame];}
        if(_XML != null && _IMG != null){
            if(eSprite != null){eSprite.destroy();}
            eSprite = new FlxSprite();

            eSprite.frames = FlxAtlasFrames.fromSparrow(_IMG, _XML.x.toString());
            
            var animArr = getNamesArray(_XML.elements);
            for(anim in animArr){eSprite.animation.addByPrefix(anim, anim); eSprite.animation.play(anim); eSprite.animation.stop();}

            if(values != null){eSprite.animation.play(values[0], false, false, values[1]); eSprite.animation.stop();}
        }
    }

    public static function getNamesArray(arr:Iterator<Access>):Array<String>{
        var toReturn:Array<String> = new Array<String>();

        for(chr in arr){
            var toDel:String = "";
            for(i in 0...chr.att.name.length){if(i >= chr.att.name.length - 4){toDel = toDel + chr.att.name.charAt(i);}}
            var nChar = chr.att.name.replace(toDel, "");
            if(!toReturn.contains(nChar)){toReturn.push(nChar);}
        }

        return toReturn;
    }
    private function getAccess(?AnimName:String, ?Frame:Int, hasNull:Bool = false):Access{
        if(AnimName == null){AnimName = clCurAnim.getSelectedLabel();}
        if(Frame == null){Frame = Std.int(stpCurFrame.value);}

        var nFrames:String = Std.string(Frame);
        while(nFrames.length < 4){nFrames = "0" + nFrames;}

        var Name = AnimName + nFrames;

        var aElements:Access = _XML != null ? _XML : null;
        if(aElements != null && aElements.elements != null){
            for(i in aElements.elements){
                if(i.att.name == Name){
                    if(!i.has.x){i.att.x = "0";}
                    if(!i.has.y){i.att.y = "0";}
                    if(!i.has.width){i.att.width = "0";}
                    if(!i.has.height){i.att.height = "0";}
                    if(!i.has.frameX){i.att.frameX = "0";}
                    if(!i.has.frameY){i.att.frameY = "0";}
                    if(!i.has.frameWidth){i.att.frameWidth = "0";}
                    if(!i.has.frameHeight){i.att.frameHeight = "0";}
                    return i;
                }
            }
        }
        return hasNull ? null : new Access(Xml.parse('<SubTexture name="n0000" x="0" y="0" width="0" height="0" frameX="0" frameY="0" frameWidth="0" frameHeight="0"/>').firstElement());
    }

    public function playAnim(?AnimName:String, ?Frame:Int):Void{
        if(eSprite == null || eSprite.animation.curAnim == null){return;}
        
        if(AnimName == null){AnimName = eSprite.animation.curAnim.name;}
        if(Frame == null){Frame = eSprite.animation.curAnim.curFrame;}

        eSprite.animation.play(AnimName, true, false, Frame);
        eSprite.animation.stop();

        eSprite.updateHitbox();

        var sTexture:Access = getAccess(AnimName, Frame);
        lblCurX.text = 'X: [${sTexture.att.x}]';
        lblCurY.text = 'Y: [${sTexture.att.y}]';
        lblCurWidth.text = 'Width: [${sTexture.att.width}]';
        lblCurHeight.text = 'Height: [${sTexture.att.height}]';
        lblCurFrameX.text = 'FrameX: [${sTexture.att.frameX}]';
        lblCurFrameY.text = 'FrameY: [${sTexture.att.frameY}]';
        lblCurFrameWidth.text = 'FrameWidth: [${sTexture.att.frameWidth}]';
        lblCurFrameHeight.text = 'FrameHeight: [${sTexture.att.frameHeight}]';
    }
    public function playGhost(AnimName:String, Frame:Int):Void{
        bSprite.animation.play(AnimName, true, false, Frame);
        bSprite.animation.stop();
    }

    var _file:FileReference;
    private function save(){
		var data:String = _XML.x.toString();

		if((data != null) && (data.length > 0)){
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "newXML.xml");
		}
	}

	function onSaveComplete(_):Void{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

    var txtIMAGE:FlxUIInputText;
    var txtXML:FlxUIInputText;
    function addFILETABS():Void{
        var uiFile = new FlxUI(null, tabFILE);
        uiFile.name = "Files";

        var lblIMAGE = new FlxText(5, 5, 0, "IMAGE (File):", 8); uiFile.add(lblIMAGE);
        txtIMAGE = new FlxUIInputText(lblIMAGE.x + lblIMAGE.width + 5, lblIMAGE.y, Std.int(tabFILE.width - lblIMAGE.width - 50), "", 8); uiFile.add(txtIMAGE);
        txtIMAGE.name = "FILE_IMAGE";
        var btnImage:FlxButton = new FlxCustomButton(txtIMAGE.x + txtIMAGE.width + 5, txtIMAGE.y - 3, 30, null, "GET", null, null, function(){getFile(txtIMAGE);}); uiFile.add(btnImage);

        var lblXML = new FlxText(lblIMAGE.x, lblIMAGE.y + txtIMAGE.height + 10, 0, "XML (File):", 8); uiFile.add(lblXML);
        txtXML = new FlxUIInputText(lblXML.x + lblXML.width + 5, lblXML.y, Std.int(tabFILE.width - lblXML.width - 50), "", 8); uiFile.add(txtXML);
        txtXML.name = "FILE_XML";        
        var btnXML:FlxButton = new FlxCustomButton(txtXML.x + txtXML.width + 5, txtXML.y - 3, 30, null, "GET", null, null, function(){getFile(txtXML);}); uiFile.add(btnXML);

        var btnImport:FlxButton = new FlxCustomButton(lblXML.x, btnXML.y + btnXML.height + 5, Std.int(tabFILE.width / 2) - 7, null, "IMPORT", null, null, function(){loadArchives(); loadNormalSprites();}); uiFile.add(btnImport);
        var btnGhostImport:FlxButton = new FlxCustomButton(btnImport.x + btnImport.width + 5, btnImport.y, Std.int(tabFILE.width / 2) - 7, null, "IMPORT GHOST", null, null, function(){loadGhostSprites();}); uiFile.add(btnGhostImport);

        var btnSave:FlxButton = new FlxCustomButton(5, btnGhostImport.y + btnGhostImport.height + 7, Std.int(tabFILE.width) - 10, null, "Save XML", null, null, function(){save();}); uiFile.add(btnSave);

        tabFILE.addGroup(uiFile);
        tabFILE.scrollFactor.set();
        tabFILE.showTabId("Files");
    }

    var clGCurAnim:FlxUICustomList;
    var stpGCurFrame:FlxUINumericStepper = new FlxUINumericStepper();
    var chkGFlipX:FlxUICheckBox;
    var chkGFlipY:FlxUICheckBox;
    function addGHOSTTABS():Void {
        var uiGhost = new FlxUI(null, tabGHOST);
        uiGhost.name = "Ghost";

        clGCurAnim = new FlxUICustomList(5, 5, Std.int(tabGHOST.width - 10), [], function(){
            stpGCurFrame.value = 0;
            playGhost(clGCurAnim.getSelectedLabel(), Std.int(stpGCurFrame.value));
        }); uiGhost.add(clGCurAnim);

        var lblbGCurFrame = new FlxText(clGCurAnim.x, clGCurAnim.y + clGCurAnim.height + 7, 0, "[Current Frame]: ", 8); uiGhost.add(lblbGCurFrame);
        stpGCurFrame = new FlxUICustomNumericStepper(lblbGCurFrame.x + lblbGCurFrame.width, lblbGCurFrame.y, Std.int(tabGHOST.width - lblbGCurFrame.width) - 10, 1, 0, 0, 999); uiGhost.add(stpGCurFrame);
        stpGCurFrame.name = "GHOST_INDEX";

        chkGFlipX = new FlxUICheckBox(5, lblbGCurFrame.y + lblbGCurFrame.height + 7, null, null, "FlipX Ghost Image"); uiGhost.add(chkGFlipX);
        chkGFlipY = new FlxUICheckBox(chkGFlipX.x + chkGFlipX.width + 5, chkGFlipX.y, null, null, "FlipY Ghost Image"); uiGhost.add(chkGFlipY);

        tabGHOST.addGroup(uiGhost);
        tabGHOST.scrollFactor.set();
        tabGHOST.showTabId("Ghost");
    }

    var clCurAnim:FlxUICustomList;
    var stpCurFrame:FlxUINumericStepper = new FlxUINumericStepper();
    var chkFlipX:FlxUICheckBox;
    var chkFlipY:FlxUICheckBox;

    var chkSetToAllFrames:FlxUICheckBox;
    var chkSetToAllSprite:FlxUICheckBox;

    var lblCurX:FlxText;
    var vchCurX:FlxUIValueChanger;
    var lblCurY:FlxText;
    var vchCurY:FlxUIValueChanger;
    var lblCurWidth:FlxText;
    var vchCurWidth:FlxUIValueChanger;
    var lblCurHeight:FlxText;
    var vchCurHeight:FlxUIValueChanger;
    var lblCurFrameX:FlxText;
    var vchCurFrameX:FlxUIValueChanger;
    var lblCurFrameY:FlxText;
    var vchCurFrameY:FlxUIValueChanger;
    var lblCurFrameWidth:FlxText;
    var vchCurFrameWidth:FlxUIValueChanger;
    var lblCurFrameHeight:FlxText;
    var vchCurFrameHeight:FlxUIValueChanger;
    private function addFRAMESTABS():Void{
        var uiBase = new FlxUI(null, tabSPRITE);
        uiBase.name = "General";

        clCurAnim = new FlxUICustomList(5, 5, Std.int(tabSPRITE.width - 10), [], function(){
            stpCurFrame.value = 0;
            playAnim(clCurAnim.getSelectedLabel(), Std.int(stpCurFrame.value));
        }); uiBase.add(clCurAnim);
        clCurAnim.name = "BASE_CHANGE";

        var lblbCurFrame = new FlxText(clCurAnim.x, clCurAnim.y + clCurAnim.height + 7, 0, "[Current Frame]: ", 8); uiBase.add(lblbCurFrame);
        stpCurFrame = new FlxUICustomNumericStepper(lblbCurFrame.x + lblbCurFrame.width, lblbCurFrame.y, Std.int(tabSPRITE.width - lblbCurFrame.width) - 10, 1, 0, 0, 999); uiBase.add(stpCurFrame);
        stpCurFrame.name = "FRAME_INDEX";

        chkFlipX = new FlxUICheckBox(5, lblbCurFrame.y + lblbCurFrame.height + 5, null, null, "FlipX Image"); uiBase.add(chkFlipX);
        chkFlipY = new FlxUICheckBox(chkFlipX.x + chkFlipX.width + 5, chkFlipX.y, null, null, "FlipY Image"); uiBase.add(chkFlipY);

        chkSetToAllFrames = new FlxUICheckBox(chkFlipX.x, chkFlipX.y + chkFlipX.height + 10, null, null, "Change on All Frames", Std.int(tabSPRITE.width) - 10); uiBase.add(chkSetToAllFrames);
        chkSetToAllSprite = new FlxUICheckBox(chkSetToAllFrames.x, chkSetToAllFrames.y + chkSetToAllFrames.height + 10, null, null, "Change on All Sprite", Std.int(tabSPRITE.width) - 10); uiBase.add(chkSetToAllSprite);

        lblCurX = new FlxText(chkSetToAllSprite.x, chkSetToAllSprite.y + chkSetToAllSprite.height + 7, 0, "X: [0]"); uiBase.add(lblCurX);
        vchCurX = new FlxUIValueChanger(tabSPRITE.width - 105, lblCurX.y - 1, 100, function(value:Float){}); uiBase.add(vchCurX); vchCurX.name = "SPRITE_X";
        lblCurY = new FlxText(lblCurX.x, lblCurX.y + lblCurX.height + 3, 0, "Y: [0]"); uiBase.add(lblCurY);
        vchCurY = new FlxUIValueChanger(tabSPRITE.width - 105, lblCurY.y - 1, 100, function(value:Float){}); uiBase.add(vchCurY); vchCurY.name = "SPRITE_Y";
        
        lblCurWidth = new FlxText(lblCurY.x, lblCurY.y + lblCurY.height + 7, 0, "Width: [0]"); uiBase.add(lblCurWidth);
        vchCurWidth = new FlxUIValueChanger(tabSPRITE.width - 105, lblCurWidth.y - 1, 100, function(value:Float){}); uiBase.add(vchCurWidth); vchCurWidth.name = "SPRITE_WIDTH";
        lblCurHeight = new FlxText(lblCurWidth.x, lblCurWidth.y + lblCurWidth.height + 3, 0, "Height: [0]"); uiBase.add(lblCurHeight);
        vchCurHeight = new FlxUIValueChanger(tabSPRITE.width - 105, lblCurHeight.y - 1, 100, function(value:Float){}); uiBase.add(vchCurHeight); vchCurHeight.name = "SPRITE_HEIGHT";
        
        lblCurFrameX = new FlxText(lblCurHeight.x, lblCurHeight.y + lblCurHeight.height + 7, 0, "FrameX: [0]"); uiBase.add(lblCurFrameX);
        vchCurFrameX = new FlxUIValueChanger(tabSPRITE.width - 105, lblCurFrameX.y - 1, 100, function(value:Float){}); uiBase.add(vchCurFrameX); vchCurFrameX.name = "SPRITE_FRAMEX";
        lblCurFrameY = new FlxText(lblCurFrameX.x, lblCurFrameX.y + lblCurFrameX.height + 3, 0, "FrameY: [0]"); uiBase.add(lblCurFrameY);
        vchCurFrameY = new FlxUIValueChanger(tabSPRITE.width - 105, lblCurFrameY.y - 1, 100, function(value:Float){}); uiBase.add(vchCurFrameY); vchCurFrameY.name = "SPRITE_FRAMEY";
        
        lblCurFrameWidth = new FlxText(lblCurFrameY.x, lblCurFrameY.y + lblCurFrameY.height + 7, 0, "FrameWidth: [0]"); uiBase.add(lblCurFrameWidth);
        vchCurFrameWidth = new FlxUIValueChanger(tabSPRITE.width - 105, lblCurFrameWidth.y - 1, 100, function(value:Float){}); uiBase.add(vchCurFrameWidth); vchCurFrameWidth.name = "SPRITE_FRAMEWIDTH";
        lblCurFrameHeight = new FlxText(lblCurFrameWidth.x, lblCurFrameWidth.y + lblCurFrameWidth.height + 3, 0, "FrameHeight: [0]"); uiBase.add(lblCurFrameHeight);
        vchCurFrameHeight = new FlxUIValueChanger(tabSPRITE.width - 105, lblCurFrameHeight.y - 1, 100, function(value:Float){}); uiBase.add(vchCurFrameHeight); vchCurFrameHeight.name = "SPRITE_FRAMEHEIGHT";

        var btnSetFrameSize0 = new FlxUICustomButton(5, lblCurFrameHeight.y + lblCurFrameHeight.height + 5, Std.int(tabSPRITE.width) - 10, null, "Set FrameSize to 0", null, null, function(){
            if(eSprite == null || eSprite.animation.curAnim == null){return;}
            if(chkSetToAllSprite.checked){
                for(e in _XML.elements){
                    e.att.frameWidth = "0";
                    e.att.frameHeight = "0";
                }
                loadESprite(); playAnim();
                return;
            }
            if(chkSetToAllFrames.checked){
                for(i in 0...eSprite.animation.curAnim.frames.length){
                    getAccess(null, i).att.frameWidth = "0";
                    getAccess(null, i).att.frameHeight = "0";
                }
                loadESprite(); playAnim();
                return;
            }
            getAccess().att.frameWidth = "0";
            getAccess().att.frameHeight = "0";
            loadESprite(); playAnim();
        }); uiBase.add(btnSetFrameSize0);

        var btnSetFrameSize = new FlxUICustomButton(5, btnSetFrameSize0.y + btnSetFrameSize0.height + 5, Std.int(tabSPRITE.width) - 10, null, "Set FrameSize", null, null, function(){
            if(eSprite == null || eSprite.animation.curAnim == null){return;}
            if(chkSetToAllSprite.checked){
                for(e in _XML.elements){
                    e.att.frameWidth = e.att.width;
                    e.att.frameHeight = e.att.height;
                }
                loadESprite(); playAnim();
                return;
            }
            if(chkSetToAllFrames.checked){
                for(i in 0...eSprite.animation.curAnim.frames.length){
                    getAccess(null, i).att.frameWidth = getAccess(null, i).att.width;
                    getAccess(null, i).att.frameHeight = getAccess(null, i).att.height;
                }
                loadESprite(); playAnim();
                return;
            }
            getAccess().att.frameWidth = getAccess().att.width;
            getAccess().att.frameHeight = getAccess().att.height;
            loadESprite(); playAnim();
        }); uiBase.add(btnSetFrameSize);

        var lblFrameName = new FlxText(5, btnSetFrameSize.y + btnSetFrameSize.height + 10, Std.int(tabSPRITE.width) - 10, "[Frame Name]"); uiBase.add(lblFrameName);
        lblFrameName.alignment = CENTER;
        var txtFrameName = new FlxUIInputText(5, lblFrameName.y + lblFrameName.height, Std.int(tabSPRITE.width) - 10, ""); uiBase.add(txtFrameName);
        var btnAddFrame = new FlxUICustomButton(5, txtFrameName.y + txtFrameName.height + 3, Std.int(tabSPRITE.width / 2) - 7, null, "Create Frame", null, FlxColor.fromRGB(94, 255, 99), function(){
            
        }); uiBase.add(btnAddFrame);
        var btnDelFrame = new FlxUICustomButton(btnAddFrame.x + btnAddFrame.width + 5, btnAddFrame.y, Std.int(tabSPRITE.width / 2) - 7, null, "Delete Frame", null, FlxColor.fromRGB(255, 94, 94), function(){
            
        }); uiBase.add(btnDelFrame);


        tabSPRITE.addGroup(uiBase);
        tabSPRITE.scrollFactor.set();
        tabSPRITE.showTabId("General");
    }
    
    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>){
        if((sender is FlxUICheckBox)){
            var check:FlxUICheckBox = cast sender;
            var label = check.getLabel().text;

            switch(id){
                case FlxUICheckBox.CLICK_EVENT:{
                    switch(label){
                        default:{trace("[FlxUICheckBox]: Works!");}
                        case "FlipX Ghost Image":{bSprite.flipX = check.checked;}
                        case "FlipY Ghost Image":{bSprite.flipY = check.checked;}
                        case "FlipX Image":{eSprite.flipX = check.checked;}
                        case "FlipY Image":{eSprite.flipY = check.checked;}
                    }
                }
            }
        }else if((sender is FlxUIInputText)){
            var input:FlxUIInputText = cast sender;
            var wname = input.name;

            switch(id){
                case FlxUIInputText.CHANGE_EVENT:{
                    switch(wname){
                        default:{trace("[FlxUIInputText]: Works!");}
                    }
                }
            }
        }else if((sender is FlxUIDropDownMenu)){
            var drop:FlxUIDropDownMenu = cast sender;
            var wname = drop.name;

            switch(id){
                case FlxUIDropDownMenu.CLICK_EVENT:{
                    switch(wname){
                        default:{trace("[FlxUIDropDownMenu]: Works!");}
                    }
                }
            }
        }else if((sender is FlxUINumericStepper)){
            var nums:FlxUINumericStepper = cast sender;
            var wname = nums.name;

            switch(id){
                case FlxUINumericStepper.CHANGE_EVENT:{
                    switch(wname){
                        default:{trace("[FlxUINumericStepper]: Works!");}
                        case "FRAME_INDEX":{
                            if(eSprite == null || eSprite.animation.curAnim == null){return;}

                            if(Std.int(nums.value) < 0){nums.value = eSprite.animation.curAnim.frames.length - 1;}
                            if(Std.int(nums.value) >= eSprite.animation.curAnim.frames.length){nums.value = 0;}

                            playAnim(clCurAnim.getSelectedLabel(), Std.int(nums.value));
                        }
                        case "GHOST_INDEX":{
                            if(bSprite == null || bSprite.animation.curAnim == null){return;}

                            if(Std.int(nums.value) < 0){nums.value = bSprite.animation.curAnim.frames.length - 1;}
                            if(Std.int(nums.value) >= bSprite.animation.curAnim.frames.length){nums.value = 0;}

                            playGhost(clGCurAnim.getSelectedLabel(), Std.int(nums.value));
                        }
                    }
                }
            }        
        }else if((sender is FlxUIValueChanger)){
            var nums:FlxUIValueChanger = cast sender;
            var wname = nums.name;

            var chValue:Int = Std.int(nums.value);
            if(data){chValue = -Std.int(nums.value);}
                
            switch(id){
                case FlxUIValueChanger.CHANGE_EVENT:{
                    switch(wname){
                        case "SPRITE_X":{
                            if(eSprite == null || eSprite.animation.curAnim == null){return;}
                            if(chkSetToAllSprite.checked){
                                for(e in _XML.elements){e.att.x = Std.string(Std.parseInt(e.att.x) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            if(chkSetToAllFrames.checked){
                                for(i in 0...eSprite.animation.curAnim.frames.length){getAccess(null, i).att.x = Std.string(Std.parseInt(getAccess(null, i).att.x) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            getAccess().att.x = Std.string(Std.parseInt(getAccess().att.x) - chValue);
                            loadESprite(); playAnim();
                        }
                        case "SPRITE_Y":{
                            if(eSprite == null || eSprite.animation.curAnim == null){return;}
                            if(chkSetToAllSprite.checked){
                                for(e in _XML.elements){e.att.y = Std.string(Std.parseInt(e.att.y) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            if(chkSetToAllFrames.checked){
                                for(i in 0...eSprite.animation.curAnim.frames.length){getAccess(null, i).att.y = Std.string(Std.parseInt(getAccess(null, i).att.y) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            getAccess().att.y = Std.string(Std.parseInt(getAccess().att.y) - chValue);
                            loadESprite(); playAnim();
                        }
                        case "SPRITE_WIDTH":{
                            if(eSprite == null || eSprite.animation.curAnim == null){return;}
                            if(chkSetToAllSprite.checked){
                                for(e in _XML.elements){e.att.width = Std.string(Std.parseInt(e.att.width) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            if(chkSetToAllFrames.checked){
                                for(i in 0...eSprite.animation.curAnim.frames.length){getAccess(null, i).att.width = Std.string(Std.parseInt(getAccess(null, i).att.width) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            getAccess().att.width = Std.string(Std.parseInt(getAccess().att.width) - chValue);
                            loadESprite(); playAnim();
                        }
                        case "SPRITE_HEIGHT":{
                            if(eSprite == null || eSprite.animation.curAnim == null){return;}
                            if(chkSetToAllSprite.checked){
                                for(e in _XML.elements){e.att.height = Std.string(Std.parseInt(e.att.height) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            if(chkSetToAllFrames.checked){
                                for(i in 0...eSprite.animation.curAnim.frames.length){getAccess(null, i).att.height = Std.string(Std.parseInt(getAccess(null, i).att.height) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            getAccess().att.height = Std.string(Std.parseInt(getAccess().att.height) - chValue);
                            loadESprite(); playAnim();
                        }
                        case "SPRITE_FRAMEX":{
                            if(eSprite == null || eSprite.animation.curAnim == null){return;}
                            if(chkSetToAllSprite.checked){
                                for(e in _XML.elements){e.att.frameX = Std.string(Std.parseInt(e.att.frameX) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            if(chkSetToAllFrames.checked){
                                for(i in 0...eSprite.animation.curAnim.frames.length){getAccess(null, i).att.frameX = Std.string(Std.parseInt(getAccess(null, i).att.frameX) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            getAccess().att.frameX = Std.string(Std.parseInt(getAccess().att.frameX) - chValue);
                            loadESprite(); playAnim();
                        }
                        case "SPRITE_FRAMEY":{
                            if(eSprite == null || eSprite.animation.curAnim == null){return;}
                            if(chkSetToAllSprite.checked){
                                for(e in _XML.elements){e.att.frameY = Std.string(Std.parseInt(e.att.frameY) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            if(chkSetToAllFrames.checked){
                                for(i in 0...eSprite.animation.curAnim.frames.length){getAccess(null, i).att.frameY = Std.string(Std.parseInt(getAccess(null, i).att.frameY) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            getAccess().att.frameY = Std.string(Std.parseInt(getAccess().att.frameY) - chValue);
                            loadESprite(); playAnim();
                        }
                        case "SPRITE_FRAMEWIDTH":{
                            if(eSprite == null || eSprite.animation.curAnim == null){return;}
                            if(chkSetToAllSprite.checked){
                                for(e in _XML.elements){e.att.frameWidth = Std.string(Std.parseInt(e.att.frameWidth) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            if(chkSetToAllFrames.checked){
                                for(i in 0...eSprite.animation.curAnim.frames.length){getAccess(null, i).att.frameWidth = Std.string(Std.parseInt(getAccess(null, i).att.frameWidth) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            getAccess().att.frameWidth = Std.string(Std.parseInt(getAccess().att.frameWidth) - chValue);
                            loadESprite(); playAnim();
                        }
                        case "SPRITE_FRAMEHEIGHT":{
                            if(eSprite == null || eSprite.animation.curAnim == null){return;}
                            if(chkSetToAllSprite.checked){
                                for(e in _XML.elements){e.att.frameHeight = Std.string(Std.parseInt(e.att.frameHeight) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            if(chkSetToAllFrames.checked){
                                for(i in 0...eSprite.animation.curAnim.frames.length){getAccess(null, i).att.frameHeight = Std.string(Std.parseInt(getAccess(null, i).att.frameHeight) - chValue);}
                                loadESprite(); playAnim();
                                return;
                            }
                            getAccess().att.frameHeight = Std.string(Std.parseInt(getAccess().att.frameHeight) - chValue);
                            loadESprite(); playAnim();
                        }
                    }
                }
            }
        }else if((sender is FlxUICustomList)){
            var nums:FlxUICustomList = cast sender;
            var wname = nums.name;
            
            switch(id){
                case FlxUICustomList.CHANGE_EVENT:{
                    switch(wname){
                    }
                }
            }
        }
    }

    public static function getCustomisableSparrowAtlas(Source:FlxGraphicAsset, Description:String):FlxAtlasFrames {
        var graphic:FlxGraphic = FlxG.bitmap.add(Source);
		if(graphic == null){return null;}

		if(graphic == null || Description == null){return null;}

		frames = new FlxAtlasFrames(graphic);

		if(Assets.exists(Description)){Description = Assets.getText(Description);}

		var data:Access = new Access(Xml.parse(Description).firstElement());

		for(texture in data.nodes.SubTexture){
			var name = texture.att.name;
			var trimmed = texture.has.frameX;
			var rotated = (texture.has.rotated && texture.att.rotated == "true");
			var flipX = (texture.has.flipX && texture.att.flipX == "true");
			var flipY = (texture.has.flipY && texture.att.flipY == "true");

			var rect = FlxRect.get(Std.parseFloat(texture.att.x), Std.parseFloat(texture.att.y), Std.parseFloat(texture.att.width),
				Std.parseFloat(texture.att.height));

			var size = if (trimmed)
			{
				new Rectangle(Std.parseInt(texture.att.frameX), Std.parseInt(texture.att.frameY), Std.parseInt(texture.att.frameWidth),
					Std.parseInt(texture.att.frameHeight));
			}
			else
			{
				new Rectangle(0, 0, rect.width, rect.height);
			}

			var angle = rotated ? FlxFrameAngle.ANGLE_NEG_90 : FlxFrameAngle.ANGLE_0;

			var offset = FlxPoint.get(-size.left, -size.top);
			var sourceSize = FlxPoint.get(size.width, size.height);

			if (rotated && !trimmed)
				sourceSize.set(size.height, size.width);

			frames.addAtlasFrame(rect, sourceSize, offset, name, angle, flipX, flipY);
		}

		return frames;
    }
}