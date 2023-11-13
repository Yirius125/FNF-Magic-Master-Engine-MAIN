package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets as OpenFlAssets;
import flixel.graphics.frames.FlxAtlasFrames;

using SavedFiles;
using StringTools;

class HealthIcon extends FlxSprite {
	public var isPlayer:Bool = false;
	public var curIcon:String = "";
	public var default_scale:FlxPoint = FlxPoint.get(1, 1);

	public function new(char:String = 'bf', _isPlayer:Bool = false){
		this.isPlayer = _isPlayer;
		super();

		this.setIcon(char);

		this.scrollFactor.set();
	}

	override function update(elapsed:Float){
		super.update(elapsed);
	}

	public function setIcon(char:String){
		if(curIcon == char){return;}
		curIcon = char;

		switch(curIcon){
			default:{
				var path = Paths.image('icons/icon-${curIcon}');
				if(!Paths.exists(path)){path = Paths.image('icons/icon-${curIcon}-pixel');}
				if(!Paths.exists(path)){path = Paths.image('icons/icon-face');}

				if(path.getAtlas() != null){
					this.frames = path.getAtlas();

					this.animation.addByPrefix('default', 'Default', 24, true, isPlayer);
					this.animation.addByPrefix('losing', 'Losing', 24, true, isPlayer);
				}else{
					var _bitMap:FlxGraphic = path.getGraphic();
					if(_bitMap == null){return;}

					this.loadGraphic(_bitMap, true, Math.floor(_bitMap.width / 2), Math.floor(_bitMap.height));

					this.animation.add('default', [0], 0, false, isPlayer);
					this.animation.add('losing', [1], 0, false, isPlayer);
				}
				playAnim("default");
				updateHitbox();
				antialiasing = !path.contains("pixel");
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0){
		if(animation.getByName(AnimName) == null){return;}
		animation.play(AnimName,Force,Reversed,Frame);
	}
}
