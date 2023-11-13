package states.editors;

import substates.editors.CharacterEditorSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUINumericStepper;
import substates.editors.SingEditorSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUITabMenu;
import states.PlayState.SongListData;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIGroup;
import flixel.sound.FlxSoundGroup;
import openfl.net.FileReference;
import substates.PopUpSubState;
import flixel.addons.ui.FlxUI;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.input.FlxInput;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import lime.ui.FileDialog;
import lime.utils.Assets;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxBasic;
import flixel.FlxG;
import haxe.Timer;
import openfl.Lib;
import haxe.Json;

import FlxCustom.FlxUICustomNumericStepper;
import FlxCustom.FlxUICustomButton;
import FlxCustom.FlxUICustomList;
import FlxCustom.FlxCustomButton;
import Conductor.BPMChangeEvent;
import Song.SwagGeneralSection;
import StrumLine.StaticNotes;
import Song.SwagSection;
import Song.SwagStrum;
import Song.SwagSong;
import Note.NoteData;
import StrumLine;
import Note;
import Song;

#if desktop
import Discord.DiscordClient;
import sys.FileSystem;
import sys.io.File;
#end

using SavedFiles;
using StringTools;

class ChartEditorState extends MusicBeatState {
    public static var _song:SwagSong;
    
    public var stage:Stage;

    public static var lastSection:Int = 0;
    var curSection:Int = 0;
    var curStrum:Int = 0;

	var tempBpm:Float = 0;

    var strumLineEvent:FlxSprite;
    var strumLine:FlxSprite;
    var strumStatics:FlxTypedGroup<StaticNotes>;

    var eveGrid:FlxSprite;
    var curGrid:FlxSprite;
    var focusStrum:FlxSprite;
    var cursor_Arrow:FlxSprite;

    var _saved:Alphabet;

    var backGroup:FlxTypedGroup<Dynamic>;
    var gridGroup:FlxTypedGroup<FlxSprite>;
    var stuffGroup:FlxTypedGroup<Dynamic>;
    
    public static var sHitsArray:Array<Bool> = [];
    var renderedEvents:FlxTypedGroup<StrumEvent>;
    var renderedSustains:FlxTypedGroup<Note>;
    var notesCanHit:Array<Array<Note>> = [];
    var renderedNotes:FlxTypedGroup<Note>;
    var sVoicesArray:Array<Bool> = [];
    var singArray:Array<Array<Int>> = [];
    
    var selNote:NoteData = Note.getNoteData();
    var selEvent:EventData = Note.getEventData();

    //var tabsUI:FlxUIMenuCustom;

    var genFollow:FlxObject;
    var backFollow:FlxObject;
    //-------

    var voices:FlxSoundGroup;
    var inst:FlxSound = new FlxSound();

    var DEFAULT_KEYSIZE:Int = 60;
    var KEYSIZE:Int = 60;

    var MENU:FlxUITabMenu;

    var arrayFocus:Array<FlxUIInputText> = [];
    var copySection:Array<Dynamic> = null;

    var lblSongInfo:FlxText;

    var saveTimer:Timer = new Timer(60000);

    override function destroy() {
        saveTimer.stop();
		super.destroy();
	}

    override function create(){
        if(FlxG.sound.music != null){FlxG.sound.music.stop();}

        if(_song == null){_song = states.PlayState.SONG;}
        if(_song == null){_song = Song.loadFromJson("Test-Normal-Normal");}

        saveTimer.run = autoSave;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence('[${_song.song}-${_song.category}-${_song.difficulty}]', '[Charting]');
		MagicStuff.setWindowTitle('Charting [${_song.song}-${_song.category}-${_song.difficulty}]', 1);
		#end

        curSection = lastSection;
		tempBpm = _song.bpm;
        
        stage = new Stage(_song.stage, _song.characters);
        stage.showCamPoints = true;
        stage.is_debug = true;
        stage.cameras = [camBHUD];
        add(stage);

        backGroup = new FlxTypedGroup<Dynamic>(); backGroup.cameras = [camHUD]; add(backGroup);
        gridGroup = new FlxTypedGroup<FlxSprite>(); gridGroup.cameras = [camHUD]; add(gridGroup);
        focusStrum = new FlxSprite().makeGraphic(KEYSIZE, KEYSIZE, FlxColor.YELLOW); focusStrum.cameras = [camHUD]; focusStrum.alpha = 0.3; add(focusStrum);
        strumStatics = new FlxTypedGroup<StaticNotes>(); strumStatics.cameras = [camHUD]; add(strumStatics);
        stuffGroup = new FlxTypedGroup<Dynamic>(); stuffGroup.cameras = [camHUD]; add(stuffGroup);

        renderedSustains = new FlxTypedGroup<Note>(); renderedSustains.cameras = [camHUD]; add(renderedSustains);
        renderedNotes = new FlxTypedGroup<Note>(); renderedNotes.cameras = [camHUD]; add(renderedNotes);
        renderedEvents = new FlxTypedGroup<StrumEvent>(); renderedEvents.cameras = [camHUD]; add(renderedEvents);

        cursor_Arrow = new FlxSprite().makeGraphic(KEYSIZE,KEYSIZE);
        cursor_Arrow.cameras = [camHUD];
        add(cursor_Arrow);

        strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width), 4);
        strumLine.cameras = [camHUD];
		//strumLine.visible = false;
		add(strumLine);
        
        strumLineEvent = new FlxSprite(0, 50).makeGraphic(KEYSIZE, 4);
        strumLineEvent.cameras = [camHUD];
		add(strumLineEvent);

        var menuTabs = [
            {name: "1Settings", label: 'Settings'},
            {name: "2Event", label: 'Event'},
            {name: "3Note", label: 'Note'},
            {name: "4Section", label: 'Section'},
            {name: "5Song", label: 'Song'}
        ];
        MENU = new FlxUITabMenu(null, menuTabs, true);
        MENU.resize(300, Std.int(FlxG.height) - 180);
		MENU.x = FlxG.width - MENU.width;
        MENU.camera = camFHUD;
        addMENUTABS();        
        add(MENU);

        lblSongInfo = new FlxText(0, 50, 300, "", 16);
        lblSongInfo.scrollFactor.set();
        lblSongInfo.camera = camFHUD;
        add(lblSongInfo);

        voices = new FlxSoundGroup();
        loadAudio(_song.song, _song.category);
        conductor.changeBPM(_song.bpm);
		conductor.mapBPMChanges(_song);

        _saved = new Alphabet(0,0,[{scale:0.3,bold:true,text:"Song Saved"}]);
        _saved.alpha = 0;
        _saved.cameras = [camFHUD];
        add(_saved);

        super.create();

        FlxG.mouse.visible = true;
        
        //camBHUD.alpha = 0;
        camBHUD.zoom = 0.5;

        backFollow = new FlxObject(0, 0, 1, 1);
        backFollow.screenCenter();
		camBHUD.follow(backFollow, LOCKON, 0.04);

        genFollow = new FlxObject(0, 0, 1, 1);
        FlxG.camera.follow(genFollow, LOCKON);
        camHUD.follow(genFollow, LOCKON);
        camBHUD.zoom = stage.zoom;
        
		changeSection(lastSection);
        changeStrum();
    }
    
    function updateSection():Void {
        //trace(_song.characters);
        sHitsArray.resize(_song.sectionStrums.length);
        
		if(_song.generalSection[curSection].changeBPM && _song.generalSection[curSection].bpm > 0){
			conductor.changeBPM(_song.generalSection[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
        }else{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for(i in 0...curSection){if(_song.generalSection[i].changeBPM){daBPM = _song.generalSection[i].bpm;}}
			conductor.changeBPM(daBPM);
		}
        for(i in 0..._song.sectionStrums.length){
            var s = _song.sectionStrums[i];
            if(s.notes[curSection].changeSing){
                singArray[i] = s.notes[curSection].charToSing;
            }else{
                singArray[i] = s.charToSing;
                for(ii in 0...curSection){if(s.notes[ii].changeSing){singArray[i] = s.notes[ii].charToSing;}}
            }
        }

        reloadChartGrid();
                
        renderedEvents.clear();
        var eventsInfo:Array<Dynamic> = _song.events.copy();
        if(eventsInfo != null){
            for(e in eventsInfo){
                var eData:EventData = Note.getEventData(e);
                if(eData.strumTime < sectionStartTime()){continue;}
                if(eData.strumTime > sectionStartTime(1)){continue;}

                var isSelected:Bool = Note.compNotes(eData, selEvent, false);
        
                var note:StrumEvent = new StrumEvent(eData.strumTime, conductor, eData.isExternal, eData.isBroken);
                setupNote(note, -1);
                note.alpha = isSelected || inst.playing ? 1 : 0.5;
    
                renderedEvents.add(note);
            }
        }

        notesCanHit = [];
        renderedNotes.clear();
        renderedSustains.clear();
        for(ii in 0..._song.sectionStrums.length){
            notesCanHit.push([]);

            var sectionInfo:Array<Dynamic> = _song.sectionStrums[ii].notes[curSection].sectionNotes.copy();
            for(n in sectionInfo){if(n[1] < 0 || n[1] >= _song.sectionStrums[ii].keys){sectionInfo.remove(n);}}
            
            var cSection = _song.sectionStrums[ii];
            for(n in sectionInfo){
                var nData:NoteData = Note.getNoteData(n);
                var isSelected:Bool = Note.compNotes(nData, selNote);
        
                var note:Note = new Note(nData, _song.sectionStrums[ii].keys, null, cSection.noteStyle);
                setupNote(note, ii);
                note.alpha = isSelected || inst.playing ? 1 : 0.5;

                if(note.otherData.length > 0){
                    var iconEvent:StrumEvent = new StrumEvent(nData.strumTime, conductor);
                    iconEvent.setPosition(note.x, note.y);
                    iconEvent.note_size.set(Std.int(KEYSIZE / 3), Std.int(KEYSIZE / 3));
                    iconEvent.alpha = note.alpha;
                    renderedEvents.add(iconEvent);
                }
                        
                renderedNotes.add(note);
                if(note.strumTime > conductor.songPosition || inst.playing){notesCanHit[ii].push(note);}
        
                if(nData.sustainLength <= 0){continue;}
        
                if(nData.multiHits > 0){
                    var totalHits:Int = nData.multiHits + 1;
                    var hits:Int = nData.multiHits;
                    var curHits:Int = 1;
                    note.noteHits = 0;
                    nData.multiHits = 0;
        
                    while(hits > 0){
                        var newStrumTime = nData.strumTime + (nData.sustainLength * curHits);
                        var nSData:NoteData = Note.getNoteData(Note.convNoteData(nData));
                        nSData.strumTime = newStrumTime;
        
                        var hitNote:Note = new Note(nSData, _song.sectionStrums[ii].keys, null, cSection.noteStyle);
                        setupNote(hitNote, ii);
                        hitNote.alpha = isSelected || inst.playing ? 1 : 0.5;
                        
                        renderedNotes.add(hitNote);
                        if(hitNote.strumTime > conductor.songPosition || inst.playing){notesCanHit[ii].push(hitNote);}
        
                        hits--;
                        curHits++;
                    }
                }else{
                    var cSusNote:Int = Math.floor(nData.sustainLength / (conductor.stepCrochet / 4) + 1);

                    var nSData:NoteData = Note.getNoteData(Note.convNoteData(nData));
                    nSData.strumTime += (conductor.stepCrochet / 2);
                    var nSustain:Note = new Note(nSData, _song.sectionStrums[ii].keys, null, cSection.noteStyle);
                    nSustain.typeNote = "Sustain";
                    nSustain.typeHit = "Hold";
                    note.nextNote = nSustain;
                    setupNote(nSustain, ii);
                    nSustain.alpha = isSelected || inst.playing ? 0.5 : 0.3;
                    renderedSustains.add(nSustain);
                    if(nSustain.strumTime > conductor.songPosition || inst.playing){notesCanHit[ii].push(nSustain);}
                    
                    var nEData:NoteData = Note.getNoteData(Note.convNoteData(nData));
                    nEData.strumTime += ((conductor.stepCrochet / 4) * (cSusNote + 2));
                    var nSustainEnd:Note = new Note(nEData, _song.sectionStrums[ii].keys, null, cSection.noteStyle);
                    nSustainEnd.typeNote = "Sustain";
                    nSustainEnd.typeHit = "Hold";
                    nSustain.nextNote = nSustainEnd;
                    setupNote(nSustainEnd, ii);
                    nSustainEnd.alpha = isSelected || inst.playing ? 0.5 : 0.3;
                    renderedSustains.add(nSustainEnd);
                    if(nSustainEnd.strumTime > conductor.songPosition || inst.playing){notesCanHit[ii].push(nSustainEnd);}
                }
            }
        }
        
        updateValues();
    }
    
    var s_Characters:Array<Dynamic> = [];
    function updateStage():Void {
        if(stage.curStage == _song.stage && s_Characters == _song.characters){return;}
        s_Characters = _song.characters.copy();

        stage.loadStage(_song.stage);
        stage.setCharacters(_song.characters);
        camBHUD.zoom = stage.zoom;
    }

    var g_STRUMS:Int = 0; var g_KEYSIZE:Int = 0; var g_STEPSLENGTH:Int = 0; var g_STRUMKEYS:Array<Int> = [];
    function reloadChartGrid(force:Bool = false):Void {
        var toChange:Bool = force;

        g_STRUMKEYS.resize(_song.sectionStrums.length);
        for(i in 0...g_STRUMKEYS.length){if(_song.sectionStrums[i].keys != g_STRUMKEYS[i]){toChange = true; break;}}
        if(_song.generalSection[curSection].lengthInSteps != g_STEPSLENGTH){toChange = true;}
        if(g_STRUMS != _song.sectionStrums.length){toChange = true;}
        if(KEYSIZE != g_KEYSIZE){toChange = true;}
        
        if(!toChange){return;}

        while(gridGroup.members.length > _song.sectionStrums.length + 1){gridGroup.remove(gridGroup.members[gridGroup.members.length - 1], true);}
        while(gridGroup.members.length < _song.sectionStrums.length + 1){gridGroup.add(new FlxSprite());}
        
        if(chkHideStrums.checked){strumStatics.clear();}else{
            while(strumStatics.members.length > _song.sectionStrums.length){strumStatics.remove(strumStatics.members[strumStatics.members.length - 1], true);}
            while(strumStatics.members.length < _song.sectionStrums.length){strumStatics.add(new StaticNotes(0,0));}
        }

        singArray = [];
        backGroup.clear();
        stuffGroup.clear();
        
        var lastWidth:Float = 0;
        var daLehgthSteps:Int = _song.generalSection[curSection].lengthInSteps;

        // EVENT GRID STRUFF
        var evGrid = gridGroup.members[0];
        evGrid = FlxGridOverlay.create(KEYSIZE, Std.int(KEYSIZE / 2), KEYSIZE, KEYSIZE * daLehgthSteps, true, 0xff4d4d4d, 0xff333333);
        evGrid.x -= KEYSIZE * 1.5;
        if(inst.playing){evGrid.alpha = 0.5;} 
        gridGroup.members[0] = evGrid;

        eveGrid = gridGroup.members[0];
        strumLineEvent.makeGraphic(KEYSIZE, 4); strumLineEvent.x = eveGrid.x;

        var line_1 = new FlxSprite(evGrid.x - 1,0).makeGraphic(2, FlxG.height, FlxColor.BLACK); line_1.scrollFactor.set(1, 0); stuffGroup.add(line_1);
        var eBack = new FlxSprite(evGrid.x,0).makeGraphic(KEYSIZE, FlxG.height, FlxColor.BLACK); eBack.alpha = 0.5; eBack.scrollFactor.set(1, 0); backGroup.add(eBack);
        var line_2 = new FlxSprite(evGrid.x + KEYSIZE - 1,0).makeGraphic(2, FlxG.height, FlxColor.BLACK); line_2.scrollFactor.set(1, 0); stuffGroup.add(line_2);

        var line_3 = new FlxSprite(-1, 0).makeGraphic(2, FlxG.height, FlxColor.BLACK); line_3.scrollFactor.set(1, 0); stuffGroup.add(line_3);
        for(i in 0..._song.sectionStrums.length){
            var daGrid = gridGroup.members[i + 1];
            var daKeys:Int = _song.sectionStrums[i].keys;
            singArray.push(_song.sectionStrums[i].charToSing);

            if(daGrid != null && daGrid.width == daKeys * KEYSIZE && !toChange){continue;}

            daGrid = FlxGridOverlay.create(KEYSIZE, KEYSIZE, KEYSIZE * daKeys, KEYSIZE * daLehgthSteps, true, 0xffe7e6e6, 0xffd9d5d5);
            if(i != curStrum || inst.playing){daGrid.alpha = 0.5;}
            daGrid.x = lastWidth; daGrid.ID = i;

            if(!chkHideStrums.checked){
                var curStatics = strumStatics.members[i];
                curStatics.style = _song.sectionStrums[i].noteStyle;
                curStatics.changeKeyNumber(daKeys, Std.int(KEYSIZE * daKeys), true, true);
                for(c in curStatics.statics){c.autoStatic = true;}
                curStatics.x = lastWidth;
            }

            lastWidth += daGrid.width;

            var new_line = new FlxSprite(lastWidth - 1, 0).makeGraphic(2, FlxG.height, FlxColor.BLACK); new_line.scrollFactor.set(1, 0); stuffGroup.add(new_line);

            gridGroup.members[i + 1] = daGrid;
        }

        var genBack = new FlxSprite().makeGraphic(Std.int(lastWidth), FlxG.height, FlxColor.BLACK); genBack.alpha = 0.5; genBack.scrollFactor.set(1, 0); backGroup.add(genBack);
                
        g_STRUMS = _song.sectionStrums.length; g_KEYSIZE = KEYSIZE; g_STEPSLENGTH = daLehgthSteps; for(i in 0...g_STRUMKEYS.length){g_STRUMKEYS[i] = _song.sectionStrums[i].keys;}
    }

    var pressedNotes:Array<NoteData> = [];
    override function update(elapsed:Float){
        curStep = recalculateSteps();
        
        if(inst.time < 0) {
			inst.pause();
			inst.time = 0;
		}else if(inst.time > inst.length) {
			inst.pause();
			inst.time = 0;
			changeSection();
		}

        conductor.songPosition = inst.time;

        if(_song.generalSection[curSection] != null){strumLine.y = getYfromStrum((conductor.songPosition - sectionStartTime()));}
        for(strums in strumStatics){strums.y = strumLine.y;} strumLineEvent.y = strumLine.y;

        if(_song.generalSection[curSection + 1] == null){addGenSection();}
        for(i in 0..._song.sectionStrums.length){if(_song.sectionStrums[i].notes[curSection + 1] == null){addSection(i, _song.generalSection[curSection].lengthInSteps, _song.sectionStrums[i].keys);}}

        if(Math.ceil(strumLine.y) >= curGrid.height){changeSection(curSection + 1, false);}
        if(strumLine.y <= -10){changeSection(curSection - 1, false);}
    
        FlxG.watch.addQuick('daBeat', curBeat);
        FlxG.watch.addQuick('daStep', curStep);

        lblSongInfo.text = 
        "Time: " + Std.string(FlxMath.roundDecimal(conductor.songPosition / 1000, 2)) + " / " + Std.string(FlxMath.roundDecimal(inst.length / 1000, 2)) +
		"\n\nSection: " + curSection +
		"\nBeat: " + curBeat +
		"\nStep: " + curStep;

        if(inst.playing){
            Character.setCameraToCharacter(stage.getCharacterById(Character.getFocusCharID(_song, curSection)), backFollow, stage);

            for(i in 0...notesCanHit.length){
                for(n in notesCanHit[i]){
                    if(n.strumTime > conductor.songPosition){continue;}
                    notesCanHit[i].remove(n);

                    if(n.hitMiss){continue;}
                    if(!chkHideStrums.checked){strumStatics.members[i].playById((n.noteData % _song.sectionStrums[i].keys), "confirm", true);}
                    if(!chkMuteHitSounds.checked && sHitsArray[i] && n.typeHit != "Hold"){FlxG.sound.play(Paths.sound("CLAP").getSound());}

                    var song_animation:String = n.singAnimation;
                    if(_song.sectionStrums[i].notes[curSection].altAnim){song_animation += '-alt';}

                    for(ii in singArray[i]){
                        if(stage.getCharacterById(ii) == null){continue;}
                        stage.getCharacterById(ii).singAnim(song_animation, true);
                    }
                }
            }
        }else{
            Character.setCameraToCharacter(stage.getCharacterById(Character.getFocusCharID(_song, curSection, curStrum)), backFollow, stage);
        }

        var arrayControlle = true;
        for(item in arrayFocus){if(item.hasFocus){arrayControlle = false;}}

        if(canControlle && arrayControlle){
		    _song.bpm = tempBpm;

            if(!inst.playing){
                if(!chkHideChart.checked && FlxG.mouse.overlaps(eveGrid)){
                    cursor_Arrow.alpha = 0.5;

                    cursor_Arrow.x = eveGrid.x;
                    cursor_Arrow.y = Math.floor(FlxG.mouse.y / (KEYSIZE / 2)) * (KEYSIZE / 2);
                    if(FlxG.keys.pressed.SHIFT){cursor_Arrow.y = FlxG.mouse.y;}
                    
                    if(FlxG.mouse.justPressed){
                        if(FlxG.keys.pressed.CONTROL){reloadSelectedEvent();}
                        else{checkToAddEvent();}
                    }
                }else if(!chkHideChart.checked && FlxG.mouse.overlaps(curGrid)){
                    cursor_Arrow.alpha = 0.5;
                    
                    cursor_Arrow.x = Math.floor(FlxG.mouse.x / KEYSIZE) * KEYSIZE;        
                    cursor_Arrow.y = Math.floor(FlxG.mouse.y / (KEYSIZE / 2)) * (KEYSIZE / 2);
                    if(FlxG.keys.pressed.SHIFT){cursor_Arrow.y = FlxG.mouse.y;}
        
                    if(FlxG.mouse.justPressed){
                        if(FlxG.keys.pressed.CONTROL){reloadSelectedNote();}
                        else{checkToAddNote();}
                    }
                }else{cursor_Arrow.alpha = 0;}
            }

            if(FlxG.keys.justPressed.SPACE){changePause(inst.playing);}
            if(FlxG.keys.anyJustPressed([UP, DOWN, W, S, R, E, Q]) || FlxG.mouse.wheel != 0 && inst.playing){changePause(true);}

            if(FlxG.keys.justPressed.R){
                if(FlxG.keys.pressed.CONTROL){KEYSIZE = DEFAULT_KEYSIZE; cursor_Arrow.setGraphicSize(KEYSIZE,KEYSIZE); cursor_Arrow.updateHitbox(); updateSection();}
                else if(FlxG.keys.pressed.SHIFT){resetSection(true);}
                else{resetSection();}
            }

            if(FlxG.mouse.wheel != 0){
                if(FlxG.keys.pressed.CONTROL){KEYSIZE += Std.int(FlxG.mouse.wheel * (KEYSIZE / 5)); cursor_Arrow.setGraphicSize(KEYSIZE,KEYSIZE); cursor_Arrow.updateHitbox(); updateSection();}
                else if(FlxG.keys.pressed.SHIFT){inst.time -= (FlxG.mouse.wheel * conductor.stepCrochet * 0.5);}
                else{inst.time -= (FlxG.mouse.wheel * conductor.stepCrochet * 1);}
            }
    
            if(!FlxG.keys.pressed.SHIFT){    
                if(FlxG.keys.justPressed.E){changeNoteSustain(1);}
                if(FlxG.keys.justPressed.Q){changeNoteSustain(-1);}
    
                if(!inst.playing){
                    if(FlxG.keys.anyPressed([UP, W])){
                        var daTime:Float = conductor.stepCrochet * 0.1;
                        inst.time -= daTime;
                    }
                    if(FlxG.keys.anyPressed([DOWN, S])){
                        var daTime:Float = conductor.stepCrochet * 0.1;
                        inst.time += daTime;
                    }
                }
        
                if(FlxG.keys.anyJustPressed([LEFT, A])){changeSection(curSection - 1);}
                if(FlxG.keys.anyJustPressed([RIGHT, D])){changeSection(curSection + 1);}
            }else{    
                if(FlxG.keys.justPressed.E){changeNoteHits(1);}
                if(FlxG.keys.justPressed.Q){changeNoteHits(-1);}
        
                if(!inst.playing){
                    if(FlxG.keys.anyPressed([UP, W])){
                        var daTime:Float = conductor.stepCrochet * 0.05;
                        inst.time -= daTime;
                    }
                    if(FlxG.keys.anyPressed([DOWN, S])){
                        var daTime:Float = conductor.stepCrochet * 0.05;
                        inst.time += daTime;
                    }
                }
        
                if(FlxG.keys.anyJustPressed([LEFT, A])){changeStrum(-1);}
                if(FlxG.keys.anyJustPressed([RIGHT, D])){changeStrum(1);}
            }
    
            if(FlxG.mouse.justPressed){
                if(FlxG.mouse.overlaps(gridGroup) && !FlxG.mouse.overlaps(MENU)){
                    for(g in gridGroup){
                        if(gridGroup.members[0] == g){continue;}
                        if(!FlxG.mouse.overlaps(g)){continue;}
                        if(g.ID == curStrum){continue;}
                        changeStrum(g.ID, true);
                        break;
                    }
                }
            }
            
            if(principal_controls.checkAction("Menu_Accept", JUST_PRESSED) && onConfirm == null){
                FlxG.save.data.autosave = _song;
                lastSection = curSection;
                SongListData.loadAndPlaySong(_song);
            }
        }

        var fgrid:FlxSprite = gridGroup.members[_song.generalSection[curSection].strumToFocus + 1];
        focusStrum.setPosition(FlxMath.lerp(focusStrum.x, fgrid.x, 0.5), fgrid.y);
        if(focusStrum.width != fgrid.width || focusStrum.height != fgrid.height){focusStrum.makeGraphic(Std.int(FlxMath.lerp(focusStrum.width, fgrid.width, 0.5)), Std.int(FlxMath.lerp(focusStrum.height, fgrid.height, 0.5)), FlxColor.YELLOW);}

        strumLine.x = curGrid.x;
        genFollow.setPosition(FlxMath.lerp(genFollow.x, curGrid.x + (curGrid.width / 2) + (MENU.width / 2), 0.50), strumLine.y);
        super.update(elapsed);
    }

    function changePause(toPause:Bool):Void {
        updateSection();

        if(toPause){
            inst.pause();
            for(voice in voices.sounds){voice.pause();}
        }else{
            inst.play(false, inst.time);
            for(voice in voices.sounds){voice.play(false, inst.time);}
        }
        for(voice in voices.sounds){voice.time = inst.time;}

        if(inst.playing){
            eveGrid.alpha = 0.5;
            cursor_Arrow.alpha = 0;
            for(grid in gridGroup){grid.alpha = 0.5;}
        }else{
            eveGrid.alpha = 1;
            cursor_Arrow.alpha = 0.5;
            MagicStuff.doToMember(cast gridGroup, curStrum + 1, function(grid){grid.alpha = 1;}, function(grid){grid.alpha = 0.5;});
        }

    }

    function updateNoteValues():Void {
        if(selNote != null){
            stpStrumLine.value = selNote.strumTime;
            stpNoteLength.value = selNote.sustainLength;
            stpNoteHits.value = selNote.multiHits;
            clNotePressets.setLabel(selNote.preset, true);
            var event_list:Array<String> = []; for(e in selNote.eventData){event_list.push(e[0]);} clNoteEventList.setData(event_list);
            clNoteEventList.setLabel(clNoteEventList.getSelectedLabel(), false, true);
        }else{
            stpStrumLine.value = 0;
            stpNoteLength.value = 0;
            stpNoteHits.value = 0;
            clNotePressets.setLabel("Default", true);
            clNoteEventList.setData([]); clNoteEventList.setLabel(clNoteEventList.getSelectedLabel(), false, true);
        }

        if(selEvent != null){
            stpEventStrumLine.value = selEvent.strumTime;
            var event_list:Array<String> = []; for(e in selEvent.eventData){event_list.push(e[0]);} clEventListEvents.setData(event_list);
            clEventListEvents.setLabel(clEventListEvents.getSelectedLabel(), false, true);
            btnChangeEventFile.label.text = selEvent.isExternal ? "Global Event" : "Local Event";
            if(selEvent.isExternal){
                btnBrokeExternalEvent.active = true;
                btnBrokeExternalEvent.alpha = 1;
                btnBrokeExternalEvent.label.text = selEvent.isBroken ? "Event Broken" : "Event Active";
            }else{
                btnBrokeExternalEvent.active = false;
                btnBrokeExternalEvent.alpha = 0.5;
                btnBrokeExternalEvent.label.text = "Event is Local";
            }
        }else{
            stpEventStrumLine.value = 0;
            clEventListEvents.setData([]); clEventListEvents.setLabel(clEventListEvents.getSelectedLabel(), false, true);
        }
    }

    function updateValues():Void {
        var arrChars = []; for(c in _song.characters){arrChars.push(c[0]);}
        
        if(_song.sectionStrums.length == 2){stpSwapSec.value = curStrum == 1 ? 0 : 1;}

        clEventListToNote.setData(Note.getNoteEvents(true,_song.stage));
        clEventListToEvents.setData(Note.getNoteEvents(_song.stage));

        if(voices.sounds.length <= 1){chkMuteVocal.kill();}else{chkMuteVocal.revive();}
        chkMuteVocal.checked = sVoicesArray[curStrum];
        chkDoHits.checked = sHitsArray[curStrum];
        
        if(_song.sectionStrums[curStrum] != null){
            chkPlayable.checked = _song.sectionStrums[curStrum].isPlayable;
            stpSrmKeys.value = _song.sectionStrums[curStrum].keys;
            clNoteStyle.setLabel(_song.sectionStrums[curStrum].noteStyle, true);
        }

        if(_song.sectionStrums[curStrum].notes[curSection] != null){
            chkALT.checked = _song.sectionStrums[curStrum].notes[curSection].altAnim;
        }

        if(_song.generalSection[curSection] != null){
            stpSecBPM.value = _song.generalSection[curSection].bpm;
            chkBPM.checked = _song.generalSection[curSection].changeBPM;
            stpLength.value = _song.generalSection[curSection].lengthInSteps;
            stpSecStrum.value = _song.generalSection[curSection].strumToFocus;
    
            var arrGenChars = [];
            for(c in _song.sectionStrums[_song.generalSection[curSection].strumToFocus].charToSing){arrGenChars.push(arrChars[c]);}
            clGenFocusChar.setData(arrGenChars);    
        }
    }

    override function stepHit(){super.stepHit();}
    override function beatHit(){super.beatHit();}

    function setupNote(note:Dynamic, ?grid:Int):Void {
        note.note_size.set(KEYSIZE,KEYSIZE);
        if(note.typeNote == "Switch"){note.note_size.set(KEYSIZE , KEYSIZE / 4);}

        note.onDebug = true;
        note.y = Math.floor(getYfromStrum((note.strumTime - sectionStartTime())));
        note.x = gridGroup.members[grid + 1].x;
        if(!(note is StrumEvent)){note.x += Math.floor(note.noteData * KEYSIZE);}
    }

    function changeStrum(value:Int = 0, force:Bool = false):Void{
        curStrum = !force ? curStrum + value : value;

        if(curStrum >= _song.sectionStrums.length){curStrum = _song.sectionStrums.length - 1;}
        if(curStrum < 0){curStrum = 0;}

        curGrid = gridGroup.members[curStrum + 1];
        if(curGrid == null){return;}
        
        if(!inst.playing){
            for(g in gridGroup){g.alpha = 0.5;}
            curGrid.alpha = 1;
        }

        if(strumLine.width != Std.int(curGrid.width)){strumLine.makeGraphic(Std.int(curGrid.width), 4);}
        
        updateValues();
    }

    
    function loadSong(daSong:String, cat:String, diff:String) {
        resetSection(true);

        daSong = Song.fileSong(daSong, cat, diff);
        _song = Song.loadFromJson(daSong);

		MusicBeatState.loadState("states.editors.ChartEditorState", [this.onBack, this.onConfirm], [[{type:"SONG",instance:_song}], false]);
    }

    function loadAudio(daSong:String, cat:String):Void {
		if(inst != null){inst.stop();}

        inst = new FlxSound().loadEmbedded(Paths.inst(daSong, cat).getSound());
        FlxG.sound.list.add(inst);

        sVoicesArray = [];
        voices.sounds = [];
        if(_song.hasVoices){
            for(i in 0..._song.sectionStrums.length){
				if(_song.sectionStrums[i].charToSing.length <= 0){continue;}
				if(_song.characters.length <= _song.sectionStrums[i].charToSing[0]){continue;}
				var voice_path:String = Paths.voice(i, _song.characters[_song.sectionStrums[i].charToSing[0]][0], daSong, cat);
                if(!Paths.exists(voice_path)){continue;}
                var voice = new FlxSound().loadEmbedded(voice_path.getSound());
                FlxG.sound.list.add(voice);
                sVoicesArray.push(false);
                voices.add(voice);
            }
        }

		inst.onComplete = function(){
			voices.pause();
			inst.pause();
			inst.time = 0;
            for(voice in voices.sounds){voice.time = 0;}
			changeSection();
		};
	}

    function recalculateSteps():Int{
        var lastChange:BPMChangeEvent = {
            stepTime: 0,
            songTime: 0,
            bpm: 0
        }

        for(i in 0...conductor.bpmChangeMap.length){
            if(inst.time > conductor.bpmChangeMap[i].songTime){
                lastChange = conductor.bpmChangeMap[i];
            }
        }
    
        curStep = lastChange.stepTime + Math.floor((inst.time - lastChange.songTime) / conductor.stepCrochet);
        updateBeat();
    
        return curStep;
    }

    function resetSection(songBeginning:Bool = false):Void{
        updateSection();
    
        inst.pause();
        for(voice in voices.sounds){voice.pause();}
    
        // Basically old shit from changeSection???
        inst.time = sectionStartTime();
    
        if(songBeginning){
            inst.time = 0;
            curSection = 0;
        }
    
        for(voice in voices.sounds){voice.time = inst.time;}
        updateCurStep(); updateSection();
    }

    function changeNoteSustain(value:Int):Void{
        updateSelectedNote(function(curNote){
            curNote.sustainLength += conductor.stepCrochet * value;
            curNote.sustainLength = Math.max(curNote.sustainLength, 0);
    
            if(curNote.sustainLength <= 0 && curNote.multiHits > 0){curNote.multiHits = 0;}
        });
    }

    function changeNoteHits(value:Int):Void{
        updateSelectedNote(function(curNote){
            curNote.multiHits += value;
            curNote.multiHits = Std.int(Math.max(curNote.multiHits, 0));
            
            if(curNote.multiHits > 0 && curNote.sustainLength <= 0){changeNoteSustain(1);}
        });
    }

    function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void{
		if(_song.generalSection[sec] == null){trace("Null Section"); return;}
        
        curSection = sec;
        updateSection();

		if(updateMusic){
			inst.pause();
			voices.pause();

			inst.time = sectionStartTime();
            for(voice in voices.sounds){voice.time = inst.time;}
			updateCurStep();
		}
	}

    private function addGenSection(lengthInSteps:Int = 16):Void{
        var genSec:SwagGeneralSection = {
            bpm: _song.bpm,
            changeBPM: false,
    
            lengthInSteps: lengthInSteps,
    
            strumToFocus: _song.generalSection[curSection].strumToFocus,
            charToFocus: _song.generalSection[curSection].charToFocus
        };

        _song.generalSection.push(genSec);
    }

    private function addSection(strum:Int = 0, lengthInSteps:Int = 16, keys:Int = 4):Void{
        var sec:SwagSection = {
            charToSing: _song.sectionStrums[strum].charToSing,
            changeSing: false,
    
            altAnim: false,
    
            sectionNotes: []
        };

        _song.sectionStrums[strum].notes.push(sec);
    }

    private function getSwagEvent(event:Array<Dynamic>):Array<Dynamic> {
        if(_song.events == null){return null;}
        for(e in _song.events){if(Note.compNotes(Note.getEventData(event), Note.getEventData(e), false)){return e;}}
        return null;
    }
    private function getSwagNote(note:Array<Dynamic>, ?strum:Int):Array<Dynamic> {
        if(strum == null){strum = curStrum;}
        if(_song.sectionStrums[strum] == null || _song.sectionStrums[strum].notes[curSection] == null || _song.sectionStrums[strum].notes[curSection].sectionNotes == null){return null;}
        for(n in _song.sectionStrums[strum].notes[curSection].sectionNotes){if(Note.compNotes(Note.getNoteData(note), Note.getNoteData(n))){return n;}}
        return null;
    }
    
    private function updateSelectedEvent(func:EventData->Void, nuFunc:Void->Void = null, updateValues:Bool = true):Void {
        var e = getSwagEvent(Note.convEventData(selEvent));
        if(e == null){
            if(nuFunc != null){nuFunc();}
        }else{
            var curEvent:EventData = Note.getEventData(e);
            func(curEvent);        
            Note.set_note(e, Note.convEventData(curEvent));
            selEvent = Note.getEventData(Note.convEventData(curEvent));
        }

        if(updateValues){updateNoteValues(); updateSection();}
    }
    private function updateSelectedNote(func:NoteData->Void, nuFunc:Void->Void = null, updateValues:Bool = true):Void {
        var n = getSwagNote(Note.convNoteData(selNote));
        if(n == null){
            if(nuFunc != null){nuFunc();}
        }else{
            var curNote:NoteData = Note.getNoteData(n);    
            func(curNote);            
            Note.set_note(n, Note.convNoteData(curNote));
            selNote = curNote;
        }

        if(updateValues){updateNoteValues(); updateSection();}
    }

    private function reloadSelectedEvent():Void {
        selEvent.strumTime = getStrumTime(cursor_Arrow.y) + sectionStartTime();
        for(e in _song.events.copy()){if(Note.compNotes(selEvent, Note.getEventData(e), false)){selEvent = Note.getEventData(e); break;}}
        updateNoteValues(); updateSection();
    }
    private function reloadSelectedNote():Void {
        selNote.strumTime = getStrumTime(cursor_Arrow.y) + sectionStartTime();
        selNote.keyData = Math.floor((FlxG.mouse.x - curGrid.x) / KEYSIZE) % _song.sectionStrums[curStrum].keys;
        for(n in _song.sectionStrums[curStrum].notes[curSection].sectionNotes.copy()){if(Note.compNotes(selNote, Note.getNoteData(n))){selNote = Note.getNoteData(n); break;}}
        updateNoteValues(); updateSection();
    }

    private function checkToAddEvent():Void{
        var _event:EventData = Note.getEventData();
        _event.strumTime = getStrumTime(cursor_Arrow.y) + sectionStartTime();

        for(e in _song.events){
            if(!Note.compNotes(_event, Note.getEventData(e), false)){continue;}
            _song.events.remove(e);
            updateNoteValues(); updateSection();
            return;
        }

        _song.events.push(Note.convEventData(_event));
        selEvent = Note.getEventData(Note.convEventData(_event));
        updateNoteValues();
        updateSection();
    }
    private function checkToAddNote(isRelease:Bool = false):Void{
        var _note:NoteData = Note.getNoteData();
        _note.strumTime = getStrumTime(cursor_Arrow.y) + sectionStartTime();
        _note.keyData = Math.floor((FlxG.mouse.x - curGrid.x) / KEYSIZE) % _song.sectionStrums[curStrum].keys;

        for(n in _song.sectionStrums[curStrum].notes[curSection].sectionNotes){
            if(!Note.compNotes(_note, Note.getNoteData(n))){continue;}
            _song.sectionStrums[curStrum].notes[curSection].sectionNotes.remove(n);
            updateNoteValues(); updateSection();
            return;
        }

        _song.sectionStrums[curStrum].notes[curSection].sectionNotes.push(Note.convNoteData(_note));
        selNote = _note;
        updateNoteValues();
        updateSection();
    }

    function getYfromStrum(strumTime:Float):Float {    
        if(curGrid != null){return FlxMath.remapToRange(strumTime, 0, _song.generalSection[curSection].lengthInSteps * conductor.stepCrochet, curGrid.y, curGrid.y + curGrid.height);}
        return 0;
    }

    function getStrumTime(yPos:Float):Float{
        if(curGrid != null){return FlxMath.remapToRange(yPos, curGrid.y, curGrid.y + curGrid.height, 0, _song.generalSection[curSection].lengthInSteps * conductor.stepCrochet);}
        return 0;
    }

    function sectionStartTime(newSection:Int = 0):Float {
        var daBPM:Float = _song.bpm;
        var daPos:Float = 0;
        for(i in 0...(curSection + newSection)){
            if(_song.generalSection[i] != null && _song.generalSection[i].changeBPM){
                daBPM = _song.generalSection[i].bpm;
            }
            daPos += 4 * (1000 * 60 / daBPM);
        }

        return daPos;
    }

    function copyLastSection(?sectionNum:Int = 1){
        var daSec = FlxMath.maxInt(curSection, sectionNum);
    
        for(strum in 0..._song.sectionStrums.length){
            for(note in _song.sectionStrums[strum].notes[daSec - sectionNum].sectionNotes){
                var curNote:NoteData = Note.getNoteData(note);
                curNote.strumTime = curNote.strumTime + conductor.stepCrochet * (_song.generalSection[daSec].lengthInSteps * sectionNum);
                if(getSwagNote(Note.convNoteData(curNote), strum) == null){_song.sectionStrums[strum].notes[daSec].sectionNotes.push(Note.convNoteData(curNote));}
            }
        }        
    
        updateSection();
    }

    function copyLastStrum(?sectionNum:Int = 1, ?strum:Int = 0){
        var daSec = FlxMath.maxInt(curSection, sectionNum);
    
        for(note in _song.sectionStrums[strum].notes[daSec - sectionNum].sectionNotes){
            var curNote:NoteData = Note.getNoteData(note);
            curNote.strumTime = curNote.strumTime + conductor.stepCrochet * (_song.generalSection[daSec].lengthInSteps * sectionNum);
            if(getSwagNote(Note.convNoteData(curNote), curStrum) == null){_song.sectionStrums[curStrum].notes[daSec].sectionNotes.push(Note.convNoteData(curNote));}
        }
    
        updateSection();
    }

    function mirrorNotes(?strum:Int = null){
        if(strum == null){strum = curStrum;}

        var secNotes:Array<Dynamic> = _song.sectionStrums[strum].notes[curSection].sectionNotes;
        var keyLength:Int = _song.sectionStrums[strum].keys;

        for(i in 0...secNotes.length){
            var curNote:NoteData = Note.getNoteData(secNotes[i]);
            curNote.keyData = keyLength - curNote.keyData - 1;
            secNotes[i] = Note.convNoteData(curNote);
        }

        _song.sectionStrums[strum].notes[curSection].sectionNotes = secNotes;

        updateSection();
    }

    function syncNotes(){
        var allSection:Array<Dynamic> = [];
        for(section in _song.sectionStrums){
            for(n in section.notes[curSection].sectionNotes){
                var hasNote:Bool = false;
                for(na in allSection){if(Note.compNotes(Note.getNoteData(na), Note.getNoteData(n))){hasNote = true; break;}}
                if(!hasNote){allSection.push(n);}
            }
        }
        
        for(section in _song.sectionStrums){section.notes[curSection].sectionNotes = allSection.copy();}

        updateSection();
    }

    private function getFile(_onSelect:String->Void):Void{
        var fDialog = new FileDialog();
        fDialog.onSelect.add(function(str){_onSelect(str);});
        fDialog.browse();
	}

    var sub_menu:FlxUITabMenu;
    var txtSong:FlxUIInputText;
    var txtCat:FlxUIInputText;
    var txtDiff:FlxUIInputText;
    var txtStage:FlxUIInputText;
    var txtStyle:FlxUIInputText;
    var stpPlayer:FlxUINumericStepper;
    var stpBPM:FlxUINumericStepper;
    var stpSpeed:FlxUINumericStepper;
    var stpSecBPM:FlxUINumericStepper;
    var stpLength:FlxUINumericStepper;
    var stpSecStrum:FlxUINumericStepper;
    var stpSrmKeys:FlxUINumericStepper;
    var stpLastSec:FlxUINumericStepper;
    var stpSwapSec:FlxUINumericStepper;
    var stpStrumLine:FlxUINumericStepper;
    var stpEventStrumLine:FlxUINumericStepper;
    var stpNoteLength:FlxUINumericStepper;
    var stpNoteHits:FlxUINumericStepper;
    var chkALT:FlxUICheckBox;
    var chkBPM:FlxUICheckBox;
    var chkHasVoices:FlxUICheckBox;
    var chkHideChart:FlxUICheckBox;
    var chkHideStrums:FlxUICheckBox;
    var chkMuteInst:FlxUICheckBox;
    var chkMuteVoices:FlxUICheckBox;
    var chkMuteVocal:FlxUICheckBox;
    var chkDoHits:FlxUICheckBox;
    var chkPlayable:FlxUICheckBox;
    var chkMuteHitSounds:FlxUICheckBox;
    var clEventListToNote:FlxUICustomList;
    var clNoteEventList:FlxUICustomList;
    var clNotePressets:FlxUICustomList;
    var clNoteCondFunc:FlxUICustomList;
    var clEventListToEvents:FlxUICustomList;
    var clEventListEvents:FlxUICustomList;
    var clNoteStyle:FlxUICustomList;
    var clGenFocusChar:FlxUICustomList;
    var btnChangeEventFile:FlxUIButton;
    var btnBrokeExternalEvent:FlxUIButton;
    var note_event_sett_group:FlxUIGroup;
    var event_sett_group:FlxUIGroup;
    function addMENUTABS():Void{
        var tabMENU = new FlxUI(null, MENU);
        tabMENU.name = "5Song";

        chkHasVoices = new FlxUICheckBox(25, 15, null, null, "\nSong has Voices?", 100); tabMENU.add(chkHasVoices);
        chkHasVoices.checked = _song.hasVoices;
        
        var btnReload = new FlxUICustomButton(chkHasVoices.x + chkHasVoices.width + 30, chkHasVoices.y, Std.int((MENU.width / 4)), null, "Reload Audio", null, null, function(){loadAudio(_song.song, _song.category);}); tabMENU.add(btnReload);

        var btnSave:FlxButton = new FlxCustomButton(30, chkHasVoices.y + chkHasVoices.height + 20, Std.int((MENU.width / 3)), null, "Save Song", null, null, function(){
            canAutoSave = false; canControlle = false;
            Song.save_song(Song.fileSong(_song.song,_song.category,_song.difficulty), _song, {saveAs: true, onComplete: function(){canAutoSave = true; canControlle = true;}});
        }); tabMENU.add(btnSave);

        var btnLoad:FlxButton = new FlxCustomButton(btnSave.x + btnSave.width + 30, btnSave.y, Std.int(MENU.width / 3), null, "Load Song", null, null, function(){loadSong(_song.song, _song.category, _song.difficulty);}); tabMENU.add(btnLoad);

        var btnImport:FlxButton = new FlxCustomButton(btnSave.x, btnSave.y + btnSave.height + 10, Std.int((MENU.width / 3)), null, "Import Chart", null, null, function(){
            getFile(function(str){
                var song_data:SwagSong = cast Song.convert_song(Song.fileSong(_song.song, _song.category, _song.difficulty), str.getText().trim());
                Song.parseJSONshit(song_data);

                _song = song_data;
                
                updateSection();
            });
        }); tabMENU.add(btnImport);

        var btnAutoSave:FlxButton = new FlxCustomButton(btnImport.x + btnImport.width + 30, btnImport.y, Std.int((MENU.width / 3)), null, "Load Auto Save", null, null, function(){
            if(FlxG.save.data.autosave == null){return;}
            
            _song = FlxG.save.data.autosave;
            Song.parseJSONshit(_song);

            FlxG.switchState(new states.LoadingState(new ChartEditorState(this.onBack, this.onConfirm), [{type:"SONG",instance:_song}], false));
        }); tabMENU.add(btnAutoSave);

        var lblSong = new FlxText(25, btnImport.y + btnImport.height + 15, 0, "SONG:", 8); tabMENU.add(lblSong);
        txtSong = new FlxUIInputText(lblSong.x + lblSong.width + 5, lblSong.y, Std.int(MENU.width - lblSong.width - 50), Paths.getFileName(_song.song), 8); tabMENU.add(txtSong);
        arrayFocus.push(txtSong);
        txtSong.name = "SONG_NAME";

        var lblCat = new FlxText(25, txtSong.y + txtSong.height + 8, 0, "CATEGORY:", 8); tabMENU.add(lblCat);
        txtCat = new FlxUIInputText(lblCat.x + lblCat.width + 5, lblCat.y, Std.int(MENU.width - lblCat.width - 50), _song.category, 8); tabMENU.add(txtCat);
        arrayFocus.push(txtCat);
        txtCat.name = "SONG_CATEGORY";

        var lblDiff = new FlxText(25, txtCat.y + txtCat.height + 8, 0, "DIFFICULTY:", 8); tabMENU.add(lblDiff);
        txtDiff = new FlxUIInputText(lblDiff.x + lblDiff.width + 5, lblDiff.y, Std.int(MENU.width - lblDiff.width - 50), _song.difficulty, 8); tabMENU.add(txtDiff);
        arrayFocus.push(txtDiff);
        txtDiff.name = "SONG_DIFFICULTY";
        
        var lblPlayer = new FlxText(25, lblDiff.y + lblDiff.height + 15, 0, "Player: ", 8); tabMENU.add(lblPlayer);
        stpPlayer = new FlxUINumericStepper(lblPlayer.x, lblPlayer.y + lblPlayer.height, 1, _song.single_player, 0, 999); tabMENU.add(stpPlayer);
            @:privateAccess arrayFocus.push(cast stpPlayer.text_field);
        stpPlayer.name = "SONG_Player";

        var lblSpeed = new FlxText(stpPlayer.x + stpPlayer.width + 32, lblPlayer.y, 0, "Scroll Speed: ", 8); tabMENU.add(lblSpeed);
        stpSpeed = new FlxUINumericStepper(lblSpeed.x, lblSpeed.y + lblSpeed.height, 0.1, _song.speed, 0.1, 10, 1); tabMENU.add(stpSpeed);
            @:privateAccess arrayFocus.push(cast stpSpeed.text_field);
        stpSpeed.name = "SONG_Speed";
        
        var lblBPM = new FlxText(stpSpeed.x + stpSpeed.width + 32, lblSpeed.y, 0, "BPM: ", 8); tabMENU.add(lblBPM);
        stpBPM = new FlxUINumericStepper(lblBPM.x, lblBPM.y + lblBPM.height, 1, _song.bpm, 5, 999); tabMENU.add(stpBPM);
            @:privateAccess arrayFocus.push(cast stpBPM.text_field);
        stpBPM.name = "SONG_BPM";
        
        chkMuteInst = new FlxUICheckBox(25, stpPlayer.y + stpPlayer.height + 10, null, null, "Mute Inst", 50); tabMENU.add(chkMuteInst);
        chkMuteVoices = new FlxUICheckBox(chkMuteInst.x + chkMuteInst.width + 15, chkMuteInst.y, null, null, "Mute Voices", 60); tabMENU.add(chkMuteVoices);
        chkMuteHitSounds = new FlxUICheckBox(chkMuteVoices.x + chkMuteVoices.width + 15, chkMuteInst.y, null, null, "Mute HitSounds", 60); tabMENU.add(chkMuteHitSounds);

        var lblStage = new FlxText(30, chkMuteInst.y + chkMuteInst.height + 20, 0, "Stage: ", 8);  tabMENU.add(lblStage);
        txtStage = new FlxUIInputText(lblStage.x + lblStage.width, lblStage.y, Std.int(MENU.width - lblStage.width - 70), _song.stage, 8); tabMENU.add(txtStage);
        arrayFocus.push(txtStage);
        txtStage.name = "SONG_STAGE";

        var lblStyle = new FlxText(30, lblStage.y + lblStage.height + 8, 0, "Style: ", 8);  tabMENU.add(lblStyle);
        txtStyle = new FlxUIInputText(lblStyle.x + lblStyle.width, lblStyle.y, Std.int(MENU.width - lblStyle.width - 70), _song.uiStyle, 8); tabMENU.add(txtStyle);
        arrayFocus.push(txtStyle);
        txtStyle.name = "SONG_STYLE";

        // Characters SubMenu --------------------
        sub_menu = new FlxUITabMenu(null, [], true);
		sub_menu.y = lblStyle.y + lblStyle.height + 15;
        sub_menu.resize(300, 75);
        tabMENU.add(sub_menu);
        
        var subTabChars = new FlxUI(null, sub_menu);
        subTabChars.name = "FNF_Characters";
        sub_menu.addGroup(subTabChars);

        var lblGf = new FlxText(25, 5, 0, "Girlfriend:", 8); subTabChars.add(lblGf);
        var txtGf = new FlxUIInputText(lblGf.x + lblGf.width + 5, 5, Std.int(MENU.width - lblGf.width - 60), _song.characters.length >= 1 ? _song.characters[0][0] : "Girlfriend", 8); subTabChars.add(txtGf);
        arrayFocus.push(txtGf); txtGf.name = "CHAR_GF";

        var lblOpp = new FlxText(25, 30, 0, "Opponent:", 8); subTabChars.add(lblOpp);
        var txtOpp = new FlxUIInputText(lblGf.x + lblGf.width + 5, 30, Std.int(MENU.width - lblOpp.width - 60), _song.characters.length >= 2 ? _song.characters[1][0] : "Daddy_Dearest", 8); subTabChars.add(txtOpp);
        arrayFocus.push(txtOpp); txtOpp.name = "CHAR_OPP";

        var lblBf = new FlxText(25, 55, 0, "Boyfriend:", 8); subTabChars.add(lblBf);
        var txtBf = new FlxUIInputText(lblGf.x + lblGf.width + 5, 55, Std.int(MENU.width - lblBf.width - 60), _song.characters.length >= 3 ? _song.characters[2][0] : "Boyfriend", 8); subTabChars.add(txtBf);
        arrayFocus.push(txtBf); txtBf.name = "CHAR_BF";

        sub_menu.showTabId("FNF_Characters");
        // Characters SubMenu --------------------

        var btnCustomCharacters:FlxButton = new FlxCustomButton(25, lblBf.y + lblBf.height + 20, Std.int(MENU.width - 50), null, "Customize your Characters", null, null, function(){
            persistentUpdate = false; canControlle = false;
            loadSubState("substates.editors.CharacterEditorSubState", [_song, stage, function(){
                persistentUpdate = true; canControlle = true;
                if(_song.characters.length != 3){
                    sub_menu.kill();
                }else{
                    sub_menu.revive();
                    txtGf.text = _song.characters[0][0];
                    txtOpp.text = _song.characters[1][0];
                    txtBf.text = _song.characters[2][0];
                }

                for(s in _song.sectionStrums){
                    for(c in s.charToSing){if(c >= _song.characters.length){s.charToSing.remove(c);}}
                    for(ss in s.notes){for(c in ss.charToSing){if(c >= _song.characters.length){ss.charToSing.remove(c);}}}
                }
            }]);
        }); tabMENU.add(btnCustomCharacters);

        var btnAddStrum:FlxButton = new FlxCustomButton(25, btnCustomCharacters.y + btnCustomCharacters.height + 15, Std.int(MENU.width / 2 - 35), null, "Add Strum", null, null, function(){
            var nStrum:SwagStrum = {
                isPlayable: true,
                keys: 4,
                noteStyle: "Default",
                charToSing: [0],
                notes: [
                    {
                        charToSing: [0],
                        changeSing: false,

                        altAnim: false,

                        sectionNotes: []
                    }
                ]
            };

            _song.sectionStrums.push(nStrum);

            for(i in 0...curSection){addSection(_song.sectionStrums.length - 1, _song.generalSection[i].lengthInSteps);}

            updateSection();
        }); tabMENU.add(btnAddStrum);

        var btnDelStrum:FlxButton = new FlxCustomButton(btnAddStrum.x + btnAddStrum.width + 30, btnAddStrum.y, Std.int(MENU.width / 2 - 35), null, "Delete Strum", null, FlxColor.RED, function(){
            if(_song.sectionStrums.length <= 1){return;}
            persistentUpdate = false; canControlle = false;
            loadSubState("substates.PopUpSubState", ["Do you want to Delete the Current Strum?", function(){
                _song.sectionStrums.remove(_song.sectionStrums[curStrum]);
                changeStrum(-1);            
                for(section in _song.generalSection){if(section.strumToFocus >= _song.sectionStrums.length){section.strumToFocus = _song.sectionStrums.length - 1;}}
                updateSection();                
            }, function(){Timer.delay(function(){persistentUpdate = true; canControlle = true;}, 500);}]);
        }); tabMENU.add(btnDelStrum); btnDelStrum.label.color = FlxColor.WHITE;
        btnDelStrum.x = btnCustomCharacters.x + btnCustomCharacters.width - btnDelStrum.width;

        var btnClearSong:FlxButton = new FlxCustomButton(5, MENU.height - 10, Std.int((MENU.width - 10)), null, "Clear Song Notes", null, FlxColor.RED, function(){
            persistentUpdate = false; canControlle = false;
            loadSubState("substates.PopUpSubState", ["Do you want to Delete all Notes of the Song?", function(){
                for(i in _song.sectionStrums){for(ii in i.notes){ii.sectionNotes = [];}}
                updateSection();              
            }, function(){Timer.delay(function(){persistentUpdate = true; canControlle = true;}, 500);}]);
        }); tabMENU.add(btnClearSong);
        var btnClearSongStrum:FlxButton = new FlxCustomButton(5, btnClearSong.y + btnClearSong.height + 10, Std.int((MENU.width - 10)), null, "Clear Current Strum Notes", null, FlxColor.RED, function(){
            if(_song.sectionStrums[curStrum] == null){return;}
            persistentUpdate = false; canControlle = false;
            loadSubState("substates.PopUpSubState", ["Do you want to Delete all Notes of the Strum?", function(){
                for(i in _song.sectionStrums[curStrum].notes){i.sectionNotes = [];}
                updateSection();
            }, function(){Timer.delay(function(){persistentUpdate = true; canControlle = true;}, 500);}]);
        }); tabMENU.add(btnClearSongStrum);
        var btnClearSongEvents:FlxButton = new FlxCustomButton(5, btnClearSongStrum.y + btnClearSongStrum.height + 10, Std.int((MENU.width - 10)), null, "Clear Song Events", null, FlxColor.RED, function(){
            persistentUpdate = false; canControlle = false;
            loadSubState("substates.PopUpSubState", ["Do you want to Delete all Events of the Song?", function(){
                _song.events = [];
                updateSection();
            }, function(){Timer.delay(function(){persistentUpdate = true; canControlle = true;}, 500);}]);
        }); tabMENU.add(btnClearSongEvents);
        btnClearSong.label.color = FlxColor.WHITE; btnClearSongStrum.label.color = FlxColor.WHITE; btnClearSongEvents.label.color = FlxColor.WHITE;

        MENU.addGroup(tabMENU);

        //=========================================================================================================================

        var tabSTRUM = new FlxUI(null, MENU);
        tabSTRUM.name = "4Section";

        var lblStrumSec = new FlxText(5, 5, MENU.width - 10, "Strum Section"); tabSTRUM.add(lblStrumSec);
        lblStrumSec.alignment = CENTER;

        var lblKeys = new FlxText(25, lblStrumSec.y + lblStrumSec.height + 15, 0, "Strum Keys: ", 8); tabSTRUM.add(lblKeys);
        stpSrmKeys = new FlxUINumericStepper(lblKeys.x + lblKeys.width, lblKeys.y, 1, _song.sectionStrums[curStrum].keys, 1, 10); tabSTRUM.add(stpSrmKeys);
            @:privateAccess arrayFocus.push(cast stpSrmKeys.text_field);
        stpSrmKeys.name = "STRUM_KEYS";

        chkPlayable = new FlxUICheckBox(170, lblKeys.y, null, null, "Is Playable"); tabSTRUM.add(chkPlayable);
        chkPlayable.checked = _song.sectionStrums[curStrum].isPlayable;

        clNoteStyle = new FlxUICustomList(25, lblKeys.y + lblKeys.height + 15, Std.int(MENU.width) - 50, Note.getNoteStyles(), function(){
            if(_song.sectionStrums[curStrum] == null){return;}
            _song.sectionStrums[curStrum].noteStyle = clNoteStyle.getSelectedLabel();
            updateSection(); reloadChartGrid(true);
        }); tabSTRUM.add(clNoteStyle);
        clNoteStyle.setPrefix('Note Style: ');
        
        chkALT = new FlxUICheckBox(25, clNoteStyle.y + clNoteStyle.height + 20, null, null, "\nChange Strum ALT"); tabSTRUM.add(chkALT);
        chkALT.checked = _song.sectionStrums[curStrum].notes[curSection].altAnim;

        var btnCSing:FlxButton = new FlxCustomButton(150, chkALT.y, 120, null, "Sing Characters", null, null, function(){
            persistentUpdate = false; canControlle = false;
            loadSubState("substates.editors.SingEditorSubState", [_song, stage, curStrum, curSection, function(){
                persistentUpdate = true; canControlle = true;
            }]);
        }); tabSTRUM.add(btnCSing);

        chkMuteVocal = new FlxUICheckBox(25, chkALT.y + chkALT.height + 20, null, null, "Mute Strum Voice", 80); tabSTRUM.add(chkMuteVocal);
        chkDoHits = new FlxUICheckBox(150, chkMuteVocal.y, null, null, "\nActive HitSounds", 100); tabSTRUM.add(chkDoHits);

        var nLine = new FlxSprite(5, chkMuteVocal.y + chkMuteVocal.height + 15).makeGraphic(Std.int(MENU.width - 10), 2, FlxColor.BLACK); tabSTRUM.add(nLine);

        var lblGenSec = new FlxText(5, nLine.y + 5, MENU.width - 10, "General Section"); tabSTRUM.add(lblGenSec);
        lblGenSec.alignment = CENTER;

        chkBPM = new FlxUICheckBox(25, lblGenSec.y + lblGenSec.height + 15, null, null, "Change BPM", 100); tabSTRUM.add(chkBPM);
		chkBPM.checked = _song.generalSection[curSection].changeBPM;
        var lblBPM = new FlxText(chkBPM.x + chkBPM.width + 15, chkBPM.y, 0, "BPM: ", 8); tabSTRUM.add(lblBPM);
        stpSecBPM = new FlxUINumericStepper(lblBPM.x + lblBPM.width, lblBPM.y, 1, _song.bpm, 5, 999); tabSTRUM.add(stpSecBPM);
            @:privateAccess arrayFocus.push(cast stpSecBPM.text_field);
        stpSecBPM.name = "GENERALSEC_BPM";

        var lblStrum = new FlxText(25, chkBPM.y + chkBPM.height + 18, 0, "Strum to Focus: ", 8); tabSTRUM.add(lblStrum);
        stpSecStrum = new FlxUINumericStepper(lblStrum.x + lblStrum.width, lblStrum.y, 1, _song.generalSection[curSection].strumToFocus, 0, 999); tabSTRUM.add(stpSecStrum);
            @:privateAccess arrayFocus.push(cast stpSecStrum.text_field);
        stpSecStrum.name = "GENERALSEC_STRUMTOFOCUS";

        clGenFocusChar = new FlxUICustomList(lblStrum.x, lblStrum.y + lblStrum.height, Std.int(lblStrum.width + stpSecStrum.width), [], function(){
            _song.generalSection[curSection].charToFocus = clGenFocusChar.getSelectedIndex();
        }, null, _song.generalSection[curSection].charToFocus);  tabSTRUM.add(clGenFocusChar);

        var lblLength = new FlxText(25, clGenFocusChar.y + clGenFocusChar.height + 15, 0, "Section Length (In steps): ", 8); tabSTRUM.add(lblLength);
        stpLength = new FlxUINumericStepper(lblLength.x + lblLength.width, lblLength.y, 4, _song.generalSection[curSection].lengthInSteps, 4, 32, 0); tabSTRUM.add(stpLength);
            @:privateAccess arrayFocus.push(cast stpLength.text_field);
        stpLength.name = "GENERALSEC_LENGTH";

        var btnCopy:FlxButton = new FlxCustomButton(25, lblLength.y + lblLength.height + 15, Std.int((MENU.width / 3) - 10), null, "Copy Section", null, null, function(){
            copySection = [curSection, []];
            for(i in 0..._song.sectionStrums.length){
                copySection[1].push([]);
                for(n in _song.sectionStrums[i].notes[curSection].sectionNotes){
                    var curNote:NoteData = Note.getNoteData(n);
                    curNote.strumTime -= sectionStartTime();
                    copySection[1][i].push(Note.convNoteData(curNote));
                }
            }
        }); tabSTRUM.add(btnCopy);

        var btnPaste:FlxButton = new FlxCustomButton(btnCopy.x + btnCopy.width + 25, btnCopy.y, Std.int((MENU.width / 3) - 6), null, "Paste Section", null, null, function(){
            if(copySection == null || copySection[1] == null){return;}
            for(i in 0..._song.sectionStrums.length){
                if(copySection[1][i] == null){continue;}

                var secNotes:Array<Dynamic> = copySection[1][i].copy();
                for(n in secNotes){
                    var curNote:NoteData = Note.getNoteData(n);
                    curNote.strumTime += sectionStartTime();

                    if(getSwagNote(Note.convNoteData(curNote), i) == null){_song.sectionStrums[i].notes[curSection].sectionNotes.push(Note.convNoteData(curNote));}
                }
            }
            updateSection();
        }); tabSTRUM.add(btnPaste);

        var btnLastSec:FlxButton = new FlxCustomButton(25, btnCopy.y + btnCopy.height + 15, Std.int((MENU.width / 2) - 20), null, "Paste Last Section", null, null, function(){
            copyLastSection(Std.int(stpLastSec.value));
        }); tabSTRUM.add(btnLastSec);
        stpLastSec = new FlxUINumericStepper(btnLastSec.x + btnLastSec.width + 10, btnLastSec.y + 3, 1, 0, -999, 999); tabSTRUM.add(stpLastSec);
            @:privateAccess arrayFocus.push(cast stpLastSec.text_field);
        
        var btnMirror:FlxButton = new FlxCustomButton(25, btnLastSec.y + btnLastSec.height + 15, 100, null, "Mirror Section", null, null, function(){for(i in 0..._song.sectionStrums.length){mirrorNotes(i);}}); tabSTRUM.add(btnMirror);
        var btnSync:FlxButton = new FlxCustomButton(btnMirror.x + btnMirror.width + 15, btnMirror.y, 130, null, "Synchronize Notes", null, null, function(){syncNotes();}); tabSTRUM.add(btnSync);
        var btnSwapStrum:FlxButton = new FlxCustomButton(25, btnMirror.y + btnMirror.height + 15, Std.int((MENU.width / 2) - 3), null, "Swap Strum", null, null, function(){
            var sec1 = _song.sectionStrums[curStrum].notes[curSection].sectionNotes;
            var sec2 = _song.sectionStrums[Std.int(stpSwapSec.value)].notes[curSection].sectionNotes;

            _song.sectionStrums[curStrum].notes[curSection].sectionNotes = sec2;
            _song.sectionStrums[Std.int(stpSwapSec.value)].notes[curSection].sectionNotes = sec1;

            updateSection();
        }); tabSTRUM.add(btnSwapStrum);
        stpSwapSec = new FlxUINumericStepper(btnSwapStrum.x + btnSwapStrum.width + 5, btnSwapStrum.y + 3, 1, 0, 0, 999); tabSTRUM.add(stpSwapSec);
            @:privateAccess arrayFocus.push(cast stpSwapSec.text_field);
        stpSwapSec.name = "Strums_Length";

        var chkDEvents = new FlxUICheckBox(25, btnSwapStrum.y + btnSwapStrum.height + 15, null, null, "Events", 50); tabSTRUM.add(chkDEvents);
        var chkDNotes = new FlxUICheckBox(100, chkDEvents.y, null, null, "Notes", 50); tabSTRUM.add(chkDNotes);
        var chkDStrum = new FlxUICheckBox(175, chkDEvents.y, null, null, "Only Strum", 80); tabSTRUM.add(chkDStrum);

        var btnDelAllSec:FlxButton = new FlxCustomButton(5, chkDEvents.y + chkDEvents.height + 15, 250, null, "Clear Section", null, FlxColor.RED, function(){
            if(chkDNotes.checked){
                if(chkDStrum.checked){
                    _song.sectionStrums[curStrum].notes[curSection].sectionNotes = [];
                }else{
                    for(strum in _song.sectionStrums){strum.notes[curSection].sectionNotes = [];}
                }
            }
            if(chkDEvents.checked){
                for(e in _song.events){
                    var eData:EventData = Note.getEventData(e);
                    if(eData.strumTime < sectionStartTime()){continue;}
                    if(eData.strumTime > sectionStartTime(1)){continue;}
                    _song.events.remove(e);
                }
            }
            updateSection();
        }); tabSTRUM.add(btnDelAllSec); btnDelAllSec.label.color = FlxColor.WHITE;
        btnDelAllSec.x = MENU.width - btnDelAllSec.width - 25;
        
        MENU.addGroup(tabSTRUM);

        //===========================================================================================================================

        var tabNOTE = new FlxUI(null, MENU);
        tabNOTE.name = "3Note";

        var lblStrumLine = new FlxText(25, 15, 0, "StrumTime: ", 8); tabNOTE.add(lblStrumLine);
        stpStrumLine = new FlxUICustomNumericStepper(lblStrumLine.x + lblStrumLine.width, lblStrumLine.y, 120, conductor.stepCrochet * 0.5, 0, 0, 999999, 2); tabNOTE.add(stpStrumLine);
            @:privateAccess arrayFocus.push(cast stpStrumLine.text_field);
        stpStrumLine.name = "NOTE_STRUMTIME";

        var lblNoteLength = new FlxText(25, lblStrumLine.y + lblStrumLine.height + 10, 0, "Note Length: ", 8); tabNOTE.add(lblNoteLength);
        stpNoteLength = new FlxUICustomNumericStepper(lblNoteLength.x + lblNoteLength.width, lblNoteLength.y, 120, conductor.stepCrochet, 0, 0, 999999, 2); tabNOTE.add(stpNoteLength);
            @:privateAccess arrayFocus.push(cast stpNoteLength.text_field);
        stpNoteLength.name = "NOTE_LENGTH";

        var lblNoteHits = new FlxText(25, lblNoteLength.y + lblNoteLength.height + 10, 0, "Note Hits: ", 8); tabNOTE.add(lblNoteHits);
        stpNoteHits = new FlxUINumericStepper(lblNoteHits.x + lblNoteHits.width, lblNoteHits.y, 1, 0, 0, 999); tabNOTE.add(stpNoteHits);
            @:privateAccess arrayFocus.push(cast stpNoteHits.text_field);
        stpNoteHits.name = "NOTE_HITS";

        clNotePressets = new FlxUICustomList(5, lblNoteHits.y + lblNoteHits.height + 5, Std.int(MENU.width - 10), Note.getNotePressets(), function(){
            updateSelectedNote(
                function(curNote){curNote.preset = clNotePressets.getSelectedLabel();},
                function(){selNote.preset = clNotePressets.getSelectedLabel();}
            );
        }); tabNOTE.add(clNotePressets);
        clNotePressets.setPrefix("Note Presset: ["); clNotePressets.setSuffix("]");
        
        clEventListToNote = new FlxUICustomList(clNotePressets.x, clNotePressets.y + clNotePressets.height + 15, Std.int(MENU.width - 35), Note.getNoteEvents(true)); tabNOTE.add(clEventListToNote);
        clEventListToNote.setPrefix("Event List: ["); clEventListToNote.setSuffix("]");

        var btnAddEventToNote = new FlxUICustomButton(clEventListToNote.x + clEventListToNote.width + 5, clEventListToNote.y, 20, null, "+", null, null, function(){
            updateSelectedNote(
                function(curNote){
                    this.pushTempScript(clEventListToNote.getSelectedLabel());
                    var default_list:Array<Dynamic> = [];
                    for(setting in cast(tempScripts.get(clEventListToNote.getSelectedLabel()).getVariable("defaultValues"),Array<Dynamic>)){default_list.push(setting.value);}
                    curNote.eventData.push([clEventListToNote.getSelectedLabel(), default_list, "OnHit"]);
                }
            );
            clNoteEventList.setIndex(selNote.eventData.length - 1);
        }); tabNOTE.add(btnAddEventToNote);
        
        clNoteEventList = new FlxUICustomList(clEventListToNote.x, clEventListToNote.y + clEventListToNote.height + 5, Std.int(MENU.width) - 35, [], function(){
            updateSelectedNote(
                function(curNote){                
                    clNoteEventList.setSuffix('] (${clNoteEventList.getSelectedIndex() + 1}/${curNote.eventData.length})');
                    clNoteCondFunc.setLabel(curNote.eventData[clNoteEventList.getSelectedIndex()][2]);
                    loadNoteEventSettings(clNoteEventList.getSelectedLabel());
                    //try{txtNoteEventValues.text = Json.stringify(curNote.eventData[clNoteEventList.getSelectedIndex()][1]);}catch(e){trace(e); txtNoteEventValues.text = "[]";}
                },
                function(){
                    clNoteEventList.setData([]);
                    clNoteEventList.setSuffix('] (0/0)');
                    loadNoteEventSettings();
                    //txtNoteEventValues.text = "[]";
                }, false
            );
        }); tabNOTE.add(clNoteEventList);
        clNoteEventList.setPrefix("Current Event: ["); clNoteEventList.setSuffix("]");
        
        var btnDelEventToNote = new FlxUICustomButton(clNoteEventList.x + clNoteEventList.width + 5, clNoteEventList.y, 20, null, "-", null, null, function(){
            updateSelectedNote(function(curNote){
                if(curNote.eventData.length <= 0){return;}
                curNote.eventData.remove(curNote.eventData[clNoteEventList.getSelectedIndex()]);
            });
            clNoteEventList.setIndex(selNote.eventData.length - 1);
        }); tabNOTE.add(btnDelEventToNote);

        clNoteCondFunc = new FlxUICustomList(5, clNoteEventList.y + clNoteEventList.height + 5, Std.int(MENU.width - 10), ["OnHit", "OnMiss", "OnCreate"], function(){
            updateSelectedNote(function(curNote){
                if(curNote.eventData.length <= 0){return;}
                curNote.eventData[clNoteEventList.getSelectedIndex()][2] = clNoteCondFunc.getSelectedLabel();
            }, false);
        }); tabNOTE.add(clNoteCondFunc);
        clNoteCondFunc.setPrefix("Condition ("); clNoteCondFunc.setSuffix(")");

        note_event_sett_group = new FlxUIGroup(5, clNoteCondFunc.y + clNoteCondFunc.height + 5); tabNOTE.add(note_event_sett_group);
        note_event_sett_group.width = Std.int(MENU.width - 10);

        MENU.addGroup(tabNOTE);

        //===========================================================================================================================

        var tabEVENT = new FlxUI(null, MENU);
        tabEVENT.name = "2Event";
        
        var lblEventStrumLine = new FlxText(25, 15, 0, "StrumTime: ", 8); tabEVENT.add(lblEventStrumLine);
        stpEventStrumLine = new FlxUICustomNumericStepper(lblEventStrumLine.x + lblEventStrumLine.width, lblEventStrumLine.y, 120, conductor.stepCrochet * 0.5, 0, 0, 999999, 2); tabEVENT.add(stpEventStrumLine);
            @:privateAccess arrayFocus.push(cast stpEventStrumLine.text_field);
        stpEventStrumLine.name = "EVENT_STRUMTIME";

        clEventListToEvents = new FlxUICustomList(25, lblEventStrumLine.y + lblEventStrumLine.height + 10, Std.int(MENU.width - 65), Note.getNoteEvents()); tabEVENT.add(clEventListToEvents);
        clEventListToEvents.setPrefix("Event List: ["); clEventListToEvents.setSuffix("]");

        var btnAddEventToEvents = new FlxUICustomButton(clEventListToEvents.x + clEventListToEvents.width + 5, clEventListToEvents.y, 20, null, "+", null, null, function(){
            updateSelectedEvent(
                function(curEvent){
                    this.pushTempScript(clEventListToEvents.getSelectedLabel());
                    var default_list:Array<Dynamic> = [];
                    for(setting in cast(tempScripts.get(clEventListToEvents.getSelectedLabel()).getVariable("defaultValues"),Array<Dynamic>)){default_list.push(setting.value);}
                    curEvent.eventData.push([clEventListToEvents.getSelectedLabel(), default_list]);
                }
            );
        }); tabEVENT.add(btnAddEventToEvents);
        
        clEventListEvents = new FlxUICustomList(25, clEventListToEvents.y + clEventListToEvents.height + 5, Std.int(MENU.width) - 65, [], function(){
            updateSelectedEvent(
                function(curEvent){                
                    clEventListEvents.setSuffix('] (${clEventListEvents.getSelectedIndex() + 1}/${curEvent.eventData.length})');
                    //try{txtCurEventValues.text = Json.stringify(curEvent.eventData[clEventListEvents.getSelectedIndex()][1]);}catch(e){trace(e); txtCurEventValues.text = "";}
                    loadEventSettings(clEventListEvents.getSelectedLabel());
                },
                function(){
                    clEventListEvents.setData([]);
                    clEventListEvents.setSuffix('] (0/0)');
                    //txtCurEventValues.text = "[]";
                    loadEventSettings();
                }, false
            );
        }); tabEVENT.add(clEventListEvents);
        clEventListEvents.setPrefix("Current Event: ["); clEventListEvents.setSuffix("]");
        
        var btnDelEventToNote = new FlxUICustomButton(clEventListEvents.x + clEventListEvents.width + 5, clEventListEvents.y, 20, null, "-", null, null, function(){
            updateSelectedEvent(
                function(curEvent){
                    if(curEvent.eventData.length <= 0){return;}
                    curEvent.eventData.remove(curEvent.eventData[clEventListEvents.getSelectedIndex()]);
                }
            );
        }); tabEVENT.add(btnDelEventToNote);

        btnChangeEventFile = new FlxUICustomButton(5, clEventListEvents.y + clEventListEvents.height + 5, Std.int(MENU.width) - 120, null, 'Local Event', null, null, function(){
            updateSelectedEvent(function(curEvent){curEvent.isExternal = !curEvent.isExternal;});
        }); tabEVENT.add(btnChangeEventFile);

        btnBrokeExternalEvent = new FlxUICustomButton(btnChangeEventFile.x + btnChangeEventFile.width + 5, btnChangeEventFile.y, 100, null, 'Broke Ex Event', null, null, function(){
            updateSelectedEvent(function(curEvent){curEvent.isBroken = !curEvent.isBroken;});
        }); tabEVENT.add(btnBrokeExternalEvent);

        event_sett_group = new FlxUIGroup(5, btnChangeEventFile.y + btnChangeEventFile.height + 5); tabEVENT.add(event_sett_group);
        event_sett_group.width = Std.int(MENU.width - 10);

        MENU.addGroup(tabEVENT);

        //===========================================================================================================================
        
        var tabSETTINGS = new FlxUI(null, MENU);
        tabSETTINGS.name = "1Settings";

        chkHideChart = new FlxUICheckBox(25, 25, null, null, "Hide Chart", 100); tabSETTINGS.add(chkHideChart);
        chkHideStrums = new FlxUICheckBox(25, chkHideChart.y + chkHideChart.height + 5, null, null, "Hide Strums", 100); tabSETTINGS.add(chkHideStrums);

        MENU.addGroup(tabSETTINGS);

        //===========================================================================================================================
        
        MENU.scrollFactor.set();
        MENU.showTabId("5Song");

        if(_song.characters.length != 3){sub_menu.kill();}
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>){
        if(id == FlxUICheckBox.CLICK_EVENT){
            var check:FlxUICheckBox = cast sender;
			var wname = check.getLabel().text;

            if(check.name.startsWith("note_event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedNote(
                    function(curNote){
                        curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = check.checked;
                    }, null, false
                );

                return;
            }else if(check.name.startsWith("event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedEvent(
                    function(curEvent){
                        curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = check.checked;
                    }, null, false
                );

                return;
            }

			switch(wname){
                case "Is Playable":{_song.sectionStrums[curStrum].isPlayable = check.checked;}
                case "\nActive HitSounds":{sHitsArray[curStrum] = check.checked;}
                case "Mute Strum Voice":{sVoicesArray[curStrum] = check.checked;}
                case "Mute Inst":{inst.volume = check.checked ? 0 : 1;}
                case "Hide Strums":{reloadChartGrid(true);} 
                case "Hide Chart":{
                    camHUD.visible = !check.checked;
                    camFHUD.alpha = !check.checked ? 1 : 0.5;
                }
				case 'Change BPM':{
                    _song.generalSection[curSection].changeBPM = check.checked;
					FlxG.log.add('BPM Changed to: ' + check.checked);
                    updateSection();
                }
				case "\nChange Strum ALT":{
                    _song.sectionStrums[curStrum].notes[curSection].altAnim = check.checked;
                }
                case "Change Characters to Sing":{
                    _song.sectionStrums[curStrum].notes[curSection].changeSing = check.checked;
                }
                case "Change Chars":{
                    _song.sectionStrums[curStrum].notes[curSection].changeSing = check.checked;
                    updateSection();
                }
                case "Song has Voices?":{
                    inst.pause();
                    for(voice in voices.sounds){voice.pause();}
                    
                    _song.hasVoices = check.checked;
                    loadAudio(_song.song, _song.category);
                    reloadChartGrid(true);
                }
			}

            if(wname == "Mute Strum Voice" || wname == "Mute Voices"){
                for(i in 0...voices.sounds.length){voices.sounds[i].volume = !sVoicesArray[i] && !chkMuteVoices.checked ? 1 : 0;}
            }
		}else if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)){
            var input:FlxUIInputText = cast sender;
            var wname = input.name;

            if(wname.startsWith("note_event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);
                var type:String = wname.split(":")[2];

                updateSelectedNote(
                    function(curNote){
                        switch(type){
                            case "string":{curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = input.text;}
                            case "array":{
                                var pString:String = '{ "Events": ${input.text} }';
                                var rString:Array<Dynamic> = [];
                                try{rString = (cast Json.parse(pString)).Events; input.color = FlxColor.BLACK;}catch(e){trace(e); input.color = FlxColor.RED;}

                                curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = rString;
                            }
                        }
                    }, null, false
                );

                return;
            }else if(wname.startsWith("event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);
                var type:String = wname.split(":")[2];

                updateSelectedEvent(
                    function(curEvent){
                        switch(type){
                            case "string":{curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = input.text;}
                            case "array":{
                                var pString:String = '{ "Events": ${input.text} }';
                                var rString:Array<Dynamic> = [];
                                try{rString = (cast Json.parse(pString)).Events; input.color = FlxColor.BLACK;}catch(e){trace(e); input.color = FlxColor.RED;}

                                curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = rString;
                            }
                        }
                    }, null, false
                );

                return;
            }

            switch(wname){
                case "SONG_NAME":{_song.song = Paths.getFileName(input.text, true);}
                case "SONG_CATEGORY":{_song.category = input.text;}
                case "SONG_DIFFICULTY":{_song.difficulty = input.text;}
                case "SONG_STYLE":{_song.uiStyle = input.text;}
                case "SONG_STAGE":{_song.stage = input.text; updateStage();}
                case "NOTE_EVENT":{
                    if(getSwagNote(Note.convNoteData(selNote)) == null){input.color = FlxColor.GRAY; return;}

                    var pString:String = '{ "Events": ${input.text} }';
                    var rString:Array<Dynamic> = [];
                    try{rString = (cast Json.parse(pString)).Events; input.color = FlxColor.BLACK;}catch(e){trace(e); input.color = FlxColor.RED;}

                    updateSelectedNote(function(curNote){
                        if(curNote.eventData[clNoteEventList.getSelectedIndex()] == null){return;}
                        curNote.eventData[clNoteEventList.getSelectedIndex()][1] = rString;
                    }, false);
                }
                case "EVENTS_EVENT":{
                    if(getSwagEvent(Note.convEventData(selEvent)) == null){input.color = FlxColor.GRAY; return;}
                    
                    var pString:String = '{ "Events": ${input.text} }';
                    var rString:Array<Dynamic> = [];
                    try{rString = (cast Json.parse(pString)).Events; input.color = FlxColor.BLACK;}catch(e){trace(e); input.color = FlxColor.RED;}

                    updateSelectedEvent(function(curEvent){
                        if(curEvent.eventData[clEventListEvents.getSelectedIndex()] == null){return;}
                        curEvent.eventData[clEventListEvents.getSelectedIndex()][1] = rString;
                    }, false);
                }
                case "CHAR_GF":{if(input == null || _song.characters.length < 1 || _song.characters[0].length < 1){return;} _song.characters[0][0] = input.text; updateStage();}
                case "CHAR_OPP":{if(input == null || _song.characters.length < 2 || _song.characters[1].length < 1){return;} _song.characters[1][0] = input.text; updateStage();}
                case "CHAR_BF":{if(input == null || _song.characters.length < 3 || _song.characters[2].length < 1){return;} _song.characters[2][0] = input.text; updateStage();}
            }
        }else if(id == FlxUIDropDownMenu.CLICK_EVENT && (sender is FlxUIDropDownMenu)){
            var drop:FlxUIDropDownMenu = cast sender;
            var wname = drop.name;
            switch(wname){
                default:{}
            }
        }else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)){
            var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;

            if(wname.startsWith("note_event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedNote(
                    function(curNote){
                        curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = nums.value;
                    }, null, false
                );

                return;
            }else if(wname.startsWith("event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedEvent(
                    function(curEvent){
                        curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = nums.value;
                    }, null, false
                );

                return;
            }

            switch(wname){
                case "SONG_Player":{
                    if(nums.value < 0){nums.value = 0;}
                    if(nums.value >= _song.sectionStrums.length){nums.value = _song.sectionStrums.length - 1;}

                    _song.single_player = Std.int(nums.value);
                }
                case "NOTE_STRUMTIME":{
                    updateSelectedNote(function(curNote){curNote.strumTime = nums.value;});
                }
                case "EVENT_STRUMTIME":{
                    updateSelectedEvent(function(curEvent){curEvent.strumTime = nums.value;});
                }
                case "NOTE_LENGTH":{
                    updateSelectedNote(function(curNote){
                        if(nums.value <= 0){curNote.multiHits = 0;}
                        curNote.sustainLength = nums.value;
                    });
                }
                case "SONG_Speed":{_song.speed = nums.value;}
                case "SONG_BPM":{
                    tempBpm = nums.value;
                    
				    conductor.mapBPMChanges(_song);
				    conductor.changeBPM(nums.value);
                    
                    updateSection();
                }
                case "GENERALSEC_BPM":{
                    _song.generalSection[curSection].bpm = nums.value;
                    updateSection();
                }
                case "GENERALSEC_LENGTH":{
                    _song.generalSection[curSection].lengthInSteps = Std.int(nums.value);
                    updateSection();
                }
                case "GENERALSEC_STRUMTOFOCUS":{
                    if(nums.value < 0){nums.value = 0;}
                    if(nums.value >= _song.sectionStrums.length){nums.value = _song.sectionStrums.length - 1;}

                    _song.generalSection[curSection].strumToFocus = Std.int(nums.value);
                    updateSection();
                }
                case "NOTE_HITS":{
                    updateSelectedNote(function(curNote){
                        curNote.multiHits = Std.int(nums.value);
                        if(curNote.sustainLength <= 0 && curNote.multiHits >= 0){curNote.sustainLength = conductor.stepCrochet;}
                    });
                }
                case "STRUM_KEYS":{
                    _song.sectionStrums[curStrum].keys = Std.int(nums.value);
                    updateSection();
                }
                case "Strums_Length":{
                    if(nums.value < 0){nums.value = 0;}
                    if(nums.value >= _song.sectionStrums.length){nums.value = _song.sectionStrums.length - 1;}
                }
            }
        }else if(id == FlxUICustomList.CHANGE_EVENT && (sender is FlxUICustomList)){
            var nums:FlxUICustomList = cast sender;
            var wname = nums.name;

            if(wname.startsWith("note_event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedNote(
                    function(curNote){
                        curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = nums.getSelectedLabel();
                    }, null, false
                );

                return;
            }else if(wname.startsWith("event_arg")){
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedEvent(
                    function(curEvent){
                        if(curEvent.eventData == null){return;}
                        if(curEvent.eventData.length <= clEventListEvents.getSelectedIndex()){return;}
                        curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = nums.getSelectedLabel();
                    }, null, false
                );

                return;
            }

            switch(wname){
                default:{}
            }
        }
    }

    var canAutoSave:Bool = true;
    private function autoSave():Void {
        if(!canAutoSave){trace("Auto Save Disabled!"); return;}
        FlxG.save.data.autosave = _song;
		FlxG.save.flush();
        trace("Auto Saved!!!");
    }

    private function loadNoteEventSettings(?event:String):Void {
        note_event_sett_group.clear();   

        if(event == null){return;}
        
        this.pushTempScript(event);
        var setting_list:Array<Dynamic> = tempScripts.get(event).getVariable("defaultValues");

        var last_height:Float = 0;

        for(i in 0...setting_list.length){
            var setting:Dynamic = setting_list[i];
            var event_value:Dynamic = selNote.eventData[clNoteEventList.getSelectedIndex()][1][i];

            switch(setting.type){
                default:{
                    var chkCurrent_Variable = new FlxUICheckBox(0, last_height, null, null, setting.name);
                    chkCurrent_Variable.checked = event_value == true || event_value == "true";
                    chkCurrent_Variable.name = 'note_event_arg:${i}';
                    note_event_sett_group.add(chkCurrent_Variable);
                    last_height += chkCurrent_Variable.height + 5;
                }
                case 'Float':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); note_event_sett_group.add(lblArgName);
                    var stpCurrent_Variable = new FlxUICustomNumericStepper(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), 0.1, Std.parseFloat(event_value), -999, 999, 3);
                    stpCurrent_Variable.name = 'note_event_arg:${i}';
                    @:privateAccess arrayFocus.push(cast stpCurrent_Variable.text_field);
                    note_event_sett_group.add(stpCurrent_Variable);
                    last_height += lblArgName.height + 5;
                }
                case 'Int':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); note_event_sett_group.add(lblArgName);
                    var stpCurrent_Variable = new FlxUICustomNumericStepper(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), 1, Std.parseFloat(event_value), -999, 999);
                    stpCurrent_Variable.name = 'note_event_arg:${i}';
                    @:privateAccess arrayFocus.push(cast stpCurrent_Variable.text_field);
                    note_event_sett_group.add(stpCurrent_Variable);
                    last_height += lblArgName.height + 5;
                }
                case 'String':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); note_event_sett_group.add(lblArgName);
                    var txtCurrent_Variable = new FlxUIInputText(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), Std.string(event_value), 8);
                    txtCurrent_Variable.name = 'note_event_arg:${i}:string';
                    arrayFocus.push(txtCurrent_Variable);
                    note_event_sett_group.add(txtCurrent_Variable); 
                    last_height += lblArgName.height + 5;
                }
                case 'Array':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); note_event_sett_group.add(lblArgName);
                    var data:String = ''; try{data = Json.stringify(cast(event_value, Array<Dynamic>));}catch(e){trace(e); data = '[]';}
                    var txtCurrent_Variable = new FlxUIInputText(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), data, 8);
                    txtCurrent_Variable.name = 'note_event_arg:${i}:array';
                    arrayFocus.push(txtCurrent_Variable);
                    note_event_sett_group.add(txtCurrent_Variable); 
                    last_height += lblArgName.height + 5;
                }
                case 'List':{
                    var clCurrent_Variable = new FlxUICustomList(0, last_height, Std.int(MENU.width) - 10, setting.list);
                    clCurrent_Variable.setPrefix('${setting.name}: ['); clCurrent_Variable.setSuffix(']');
                    clCurrent_Variable.name = 'note_event_arg:${i}';
                    clCurrent_Variable.setLabel(event_value,true);
                    note_event_sett_group.add(clCurrent_Variable); 
                    last_height += clCurrent_Variable.height + 5;
                }
            }
        }
    }

    private function loadEventSettings(?event:String):Void {
        event_sett_group.clear();   

        if(event == null){return;}
        
        this.pushTempScript(event);
        var setting_list:Array<Dynamic> = tempScripts.get(event).getVariable("defaultValues");

        var last_height:Float = 0;

        for(i in 0...setting_list.length){
            var setting:Dynamic = setting_list[i];
            var event_value:Dynamic = selEvent.eventData[clEventListEvents.getSelectedIndex()][1][i];

            switch(setting.type){
                default:{
                    var chkCurrent_Variable = new FlxUICheckBox(0, last_height, null, null, setting.name);
                    chkCurrent_Variable.checked = event_value == true || event_value == "true";
                    chkCurrent_Variable.name = 'event_arg:${i}';
                    event_sett_group.add(chkCurrent_Variable);
                    last_height += chkCurrent_Variable.height + 5;
                }
                case 'Float':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); event_sett_group.add(lblArgName);
                    var stpCurrent_Variable = new FlxUICustomNumericStepper(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), 0.1, Std.parseFloat(event_value), -999, 999, 3);
                    stpCurrent_Variable.name = 'event_arg:${i}';
                    @:privateAccess arrayFocus.push(cast stpCurrent_Variable.text_field);
                    event_sett_group.add(stpCurrent_Variable);
                    last_height += lblArgName.height + 5;
                }
                case 'Int':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); event_sett_group.add(lblArgName);
                    var stpCurrent_Variable = new FlxUICustomNumericStepper(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), 1, Std.parseFloat(event_value), -999, 999);
                    stpCurrent_Variable.name = 'event_arg:${i}';
                    @:privateAccess arrayFocus.push(cast stpCurrent_Variable.text_field);
                    event_sett_group.add(stpCurrent_Variable);
                    last_height += lblArgName.height + 5;
                }
                case 'String':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); event_sett_group.add(lblArgName);
                    var data:String = ''; try{data = Json.stringify(event_value);}catch(e){trace(e); data = '""';}
                    var txtCurrent_Variable = new FlxUIInputText(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), Std.string(event_value), 8);
                    txtCurrent_Variable.name = 'event_arg:${i}:string';
                    arrayFocus.push(txtCurrent_Variable);
                    event_sett_group.add(txtCurrent_Variable); 
                    last_height += lblArgName.height + 5;
                }
                case 'Array':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: '); event_sett_group.add(lblArgName);
                    var data:String = ''; try{data = Json.stringify(cast(event_value, Array<Dynamic>));}catch(e){trace(e); data = '[]';}
                    var txtCurrent_Variable = new FlxUIInputText(lblArgName.width, last_height, Std.int(MENU.width - lblArgName.width - 10), data, 8);
                    txtCurrent_Variable.name = 'event_arg:${i}:array';
                    arrayFocus.push(txtCurrent_Variable);
                    event_sett_group.add(txtCurrent_Variable); 
                    last_height += lblArgName.height + 5;
                }
                case 'List':{
                    var clCurrent_Variable = new FlxUICustomList(0, last_height, Std.int(MENU.width) - 10, setting.list);
                    clCurrent_Variable.setPrefix('${setting.name}: ['); clCurrent_Variable.setSuffix(']');
                    clCurrent_Variable.name = 'event_arg:${i}';
                    clCurrent_Variable.setLabel(event_value,true);
                    event_sett_group.add(clCurrent_Variable); 
                    last_height += clCurrent_Variable.height + 5;
                }
            }
        }
    }
}