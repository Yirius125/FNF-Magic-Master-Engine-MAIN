import("flixel.sound.FlxSound", "FlxSound");
import("flixel.FlxSprite", "FlxSprite");
import("PreSettings", "PreSettings");
import("SavedFiles", "SavedFiles");
import("Character", "Character");
import("flixel.FlxG", "FlxG");
import("Paths", "Paths");

preset("initChar", 5);
preset("camP_1", [585,305]);
preset("camP_2", [980,610]);
preset("zoom", 1.1);

var phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
var trainMoving:Bool = false;
var trainFrameTiming:Float = 0;
var trainCars:Int = 8;
var trainFinishing:Bool = false;
var trainCooldown:Int = 0;
var startedMoving:Bool = false;
var curLight:Int = -1;

var sky:FlxSprite = null;
var city:FlxSprite = null;
var lights:FlxSprite = null;
var behindtrain:FlxSprite = null;
var train:FlxSprite = null;
var street:FlxSprite = null;
var trainsound:FlxSound = null;

function addToLoad(temp):Void {
	temp.push({type: "IMAGE", instance: Paths.image('sky','stages/philly')});
	temp.push({type: "IMAGE", instance: Paths.image('city','stages/philly')});
	temp.push({type: "IMAGE", instance: Paths.image('win','stages/philly')});
	temp.push({type: "IMAGE", instance: Paths.image('behindTrain','stages/philly')});
	temp.push({type: "IMAGE", instance: Paths.image('train','stages/philly')});
	temp.push({type: "IMAGE", instance: Paths.image('street','stages/philly')});
}

function create():Void {
	sky = new FlxSprite(-100, 0);
	sky.scrollFactor.set(0.1, 0.1);
	sky.loadGraphic(SavedFiles.getGraphic(Paths.image('sky', 'stages/philly')));
	instance.add(sky);

	city = new FlxSprite(-10, 0);
	city.scrollFactor.set(0.3, 0.3);
	city.loadGraphic(SavedFiles.getGraphic(Paths.image('city', 'stages/philly')));
	instance.add(city);

	lights = new FlxSprite(0, 0);
	lights.scrollFactor.set(0.3, 0.3);
	lights.loadGraphic(SavedFiles.getGraphic(Paths.image('win', 'stages/philly')));
	instance.add(lights);

	behindtrain = new FlxSprite(-40, 50);
	behindtrain.loadGraphic(SavedFiles.getGraphic(Paths.image('behindTrain', 'stages/philly')));
	instance.add(behindtrain);

	train = new FlxSprite(2000, 360);
	train.loadGraphic(SavedFiles.getGraphic(Paths.image('train', 'stages/philly')));
	instance.add(train);

	street = new FlxSprite(-40, 50);
	street.loadGraphic(SavedFiles.getGraphic(Paths.image('street', 'stages/philly')));
	instance.add(street);

	trainsound = new FlxSound();
	trainsound.loadEmbedded(SavedFiles.getSound(Paths.sound('train_passes', 'stages/philly')), true);
	FlxG.sound.list.add(trainsound);
	instance.add(trainsound);

    pushGlobal();
}

function update(elapsed:Float):Void {
    if(!PreSettings.getPreSetting("Background Animated", "Graphic Settings")){return;}

    if(trainMoving){
        trainFrameTiming += elapsed;

        if(trainFrameTiming >= 1 / 24){
            updateTrainPos();
            trainFrameTiming = 0;
        }
    }

    lights.alpha -= (getState().conductor.crochet / 1000) * FlxG.elapsed * 1.5;
}

function beatHit(curBeat:Int):Void {
    if(!PreSettings.getPreSetting("Background Animated", "Graphic Settings")){return;}
    
    if(!trainMoving){trainCooldown += 1;}

    if(curBeat % 4 == 0){
        curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
        lights.color = phillyLightsColors[curLight];
        lights.alpha = 1;
    }

    if(curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8){
        trainCooldown = FlxG.random.int(-4, 0);
        trainStart();
    }
}

function trainStart():Void {
    trainMoving = true;
    if(!trainsound.playing){trainsound.play(true);}
}

function stepHit(curStep:Int):Void {
    if(trainMoving && trainsound.time >= 4700 && curStep % 2 == 0){
        var gf_char:Character = getState().stage.getCharacterByType("Girlfriend");
        if(gf_char != null){gf_char.singAnim('hairBlow', true, true);}
    }
}
function updateTrainPos():Void {
    if(trainsound.time >= 4700){
        train.visible = true;
        startedMoving = true;
    }

    if(startedMoving){
        train.x -= 400;

        if(train.x < -2000 && !trainFinishing){
            train.x = -1150;
            trainCars -= 1;

            if(trainCars <= 0){trainFinishing = true;}
        }

        if(train.x < -4000 && trainFinishing){trainReset();}
    }
}

function trainReset():Void {
    train.x = FlxG.width + 200;
    train.visible = false;
    trainMoving = false;
    //trainsound.stop();
    //trainsound.time = 0;
    trainCars = 8;
    trainFinishing = false;
    startedMoving = false;
    
    var gf_char:Character = getState().stage.getCharacterByType("Girlfriend");
    if(gf_char != null){gf_char.singAnim('hairFall', true, true);}
}

function song_paused(isPaused:Bool):Void {
    if(isPaused){
        trainsound.pause();
    }else{
        trainsound.resume();
    }
}