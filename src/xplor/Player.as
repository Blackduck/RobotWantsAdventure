﻿package xplor 
{
	import org.flixel.*;
 
	public class Player extends FlxSprite
	{
		[Embed(source="../../data/player.png")] 
		protected var PlayerImage:Class;
		[Embed(source="../../data/rocket.png")]
		protected var rocketPic:Class;
		
		[Embed(source="../../data/die.mp3")] 
		protected var dieSnd:Class;
		[Embed(source="../../data/jump.mp3")] 
		protected var jumpSnd:Class;
		[Embed(source="../../data/rocket.mp3")] 
		protected var rocketSnd:Class;
		[Embed(source="../../data/powerup.mp3")] 
		protected var powerupSnd:Class;
		[Embed(source="../../data/door.mp3")] 
		protected var doorSnd:Class;
		
		protected static const PLAYER_RUN_SPEED:int = 80;
		protected static const GRAVITY_ACCELERATION:Number = 420;
		protected static const JUMP_ACCELERATION:Number = 200;
		
		protected static const POWER_JUMP:int = 0;
		protected static const POWER_SHOOT:int = 1;
		protected static const POWER_DOUBLEJUMP:int = 2;
		protected static const POWER_ROCKET:int = 3;
		protected static const POWER_DASH:int = 4;
		protected static const POWER_REDKEY:int = 5;
		protected static const POWER_BLUKEY:int = 6;
		protected static const POWER_GRNKEY:int = 7;
		protected static const POWER_RAPID:int = 8;
		
		public var justdied:Boolean = false;
		protected var powers:Array,bullets:Array;
		protected var map:FlxTilemap;
		protected var startx:int, starty:int;
		protected var reload:int;
		protected var airjump:int;
		protected var rocket:FlxEmitter;
		protected var rocketTime:int;
		protected var timeToDoubleTap:int;
		protected var doubleTapDir:int;
		protected var dashTime:int;
		protected var dashed:Boolean;
		
		public function Player(x:int,y:int,map:FlxTilemap,bullets:Array)
		{
			
			startx = x * 16;
			starty = y * 16;
			this.map = map;
			super(PlayerImage, x*16, y*16, true, true);
			this.offset.x = 4;
			this.offset.y = 2;
			this.width = 8;
			this.height = 14;
			drag.x = PLAYER_RUN_SPEED * 8;
			acceleration.y = GRAVITY_ACCELERATION;
			maxVelocity.x = PLAYER_RUN_SPEED;
			maxVelocity.y = 1200;

			addAnimation("idle", [0], 15, true);
			addAnimation("run", [1, 2], 8, true);
			addAnimation("jump", [3], 1, true);
			addAnimation("duck", [4], 0, true);
			addAnimation("dash", [5], 0, true);
			
			powers = new Array();
			this.bullets = bullets;
			reload = 0;
			airjump = 0;
			rocket = FlxG.state.add(new FlxEmitter(0, 0, 5, 5, null, 0.05, -10, 10, 0, 300, 0,0, 600, 5, rocketPic, 12, true)) as FlxEmitter;
			rocket.kill();

			timeToDoubleTap = 0;
			dashTime = 0;
			dashed = false;
			
			if (ConfigState.PowerStart) {
				for (var i:uint = 0; i <= 8; ++i) powers[i] = true;
			}
		}

		public function Die():void
		{
			justdied = true;
			x = startx;
			y = starty;
			velocity.x = 0;
			velocity.y = 0;
			play("idle");
			FlxG.play(dieSnd);
		}
		
		public override function update():void
		{
			var i:int;
			
			if (timeToDoubleTap > 0)
				timeToDoubleTap--;
			if (dashTime)
				dashTime--;
			else
				maxVelocity.x = PLAYER_RUN_SPEED;
				
			if (dashTime == 0) dashed = false;
				
			if (reload)
				reload--;
			if (rocketTime>0)
			{
				rocketTime--;
				if (!rocketTime)
					rocket.active = false;
			}
			
			rocket.x = x+width/2;
			rocket.y = y + height;
			
			acceleration.x = 0;
			if (FlxG.keys.DOWN && velocity.y==0)
			{
				play("duck");
				if (FlxG.keys.justPressed("Z"))
				{
					if (powers[POWER_ROCKET] == 1)
					{
						velocity.y = -1200;
						rocket.restart();
						rocketTime = 30;
						FlxG.play(rocketSnd);
					}
					else if(ConfigState.DuckJump || powers[POWER_JUMP])
					{
						velocity.y = -JUMP_ACCELERATION;
						FlxG.play(jumpSnd);
					}
				}
			}
			else
			{
				if (powers[POWER_DASH]==1 && FlxG.keys.justPressed("LEFT") && dashTime==0 && dashed==false && (ConfigState.RocketOnFloor || velocity.y!=0))
				{
					if (timeToDoubleTap > 0 && doubleTapDir==LEFT)
					{
						// rocket left
						velocity.y = 0;
						velocity.x = -600;
						maxVelocity.x = 600;
						dashTime = 90;
						FlxG.play(rocketSnd);
						airjump = 1;
						dashed = true;
					}
					else
					{
						timeToDoubleTap = 15;
						doubleTapDir = LEFT;
					}
				}
				if (powers[POWER_DASH]==1 && FlxG.keys.justPressed("RIGHT") && dashTime==0 && dashed==false && (ConfigState.RocketOnFloor || velocity.y!=0))
				{
					if (timeToDoubleTap > 0 && doubleTapDir==RIGHT)
					{
						// rocket right
						velocity.y = 0;
						velocity.x = 600;
						maxVelocity.x = 600;
						dashTime = 90;
						FlxG.play(rocketSnd);
						airjump = 1;
						dashed = true;
					}
					else
					{
						timeToDoubleTap = 15;
						doubleTapDir = RIGHT;
					}
				}
				
				if(FlxG.keys.LEFT)
				{
					facing = LEFT;
					acceleration.x = -drag.x;
				}
				else if(FlxG.keys.RIGHT)
				{
					facing = RIGHT;
					acceleration.x = drag.x;
				}
				if(FlxG.keys.X)
				{
					if (powers[POWER_SHOOT]==1 && reload == 0)
					{
						var shotspeed:int;
						if (facing == LEFT)
							shotspeed = -180;
						else
							shotspeed = 180;
						reload = 30;
						if (powers[POWER_RAPID] == 1)
							reload = 5;
						
						for each(var b:Laser in bullets)
						{
							if (b.exists == false)
							{
								b.shoot(x, y, shotspeed, 0);
								break;
							}
						}
					}
				}
				if(FlxG.keys.justPressed("Z"))
				{
					if (powers[POWER_JUMP] == 1 && !velocity.y)
					{
						velocity.y = -JUMP_ACCELERATION;
						FlxG.play(jumpSnd);
					}
					else if (powers[POWER_DOUBLEJUMP] == 1 && airjump == 0)
					{
						airjump = 1;
						FlxG.play(jumpSnd);
						velocity.y = -JUMP_ACCELERATION;
					}
				}
				if (velocity.y == 0)
				{
					if(velocity.x == 0)
					{
						play("idle");
					}
					else
					{
						play("run");
					}
				}
			}
				
			var tx:int, ty:int;
			
			tx = (x + 8) / 16;
			ty = (y + 8) / 16;
			if (map.getTile(tx,ty) == 4)	// jump power!
			{
				map.setTile(tx, ty, 0);
				powers[POWER_JUMP] = 1;
				FlxG.play(powerupSnd);
			}
			if (map.getTile(tx,ty) == 5)	// shoot power!
			{
				map.setTile(tx, ty, 0);
				powers[POWER_SHOOT] = 1;
				FlxG.play(powerupSnd);
			}
			if (map.getTile(tx, ty) == 6)	// deadly acid
			{
				Die();
			}
			if (map.getTile(tx,ty) == 7)	// double jump power
			{
				map.setTile(tx, ty, 0);
				powers[POWER_DOUBLEJUMP] = 1;
				FlxG.play(powerupSnd);
			}
			if (map.getTile(tx,ty) == 8)	// rocket jump power
			{
				map.setTile(tx, ty, 0);
				powers[POWER_ROCKET] = 1;
				FlxG.play(powerupSnd);
			}
			if (map.getTile(tx,ty) == 9)	// dash power
			{
				map.setTile(tx, ty, 0);
				powers[POWER_DASH] = 1;
				FlxG.play(powerupSnd);
			}
			if (map.getTile(tx,ty) == 11)	// red key
			{
				map.setTile(tx, ty, 0);
				powers[POWER_REDKEY] = 1;
				FlxG.play(powerupSnd);
			}
			if (map.getTile(tx,ty) == 12)	// green key
			{
				map.setTile(tx, ty, 0);
				powers[POWER_GRNKEY] = 1;
				FlxG.play(powerupSnd);
			}
			if (map.getTile(tx,ty) == 13)	// blue key
			{
				map.setTile(tx, ty, 0);
				powers[POWER_BLUKEY] = 1;
				FlxG.play(powerupSnd);
			}
			if (map.getTile(tx,ty) == 15)	// rapid fire
			{
				map.setTile(tx, ty, 0);
				powers[POWER_RAPID] = 1;
				FlxG.play(powerupSnd);
			}
			
			if(velocity.y != 0 && dashTime==0)
			{
				play("jump");
			}
			else if (dashTime)
				play("dash");
			
			super.update();
		}

		override public function hitFloor(Contact:FlxCore = null):Boolean 
		{
			velocity.y = 0; 
			airjump = 0;
			if(!ConfigState.RocketOnFloor) {
				dashTime = 0;
				dashed = false;
			}
			return true;
		}
		
		override public function hitWall(Contact:FlxCore = null):Boolean 
		{
			var tx:int, ty:int;
			
			if(facing==RIGHT)
				tx = (x + 8) / 16;
			else
				tx = (x - 8) / 16;
			ty = (y + 8) / 16;
			/*if (velocity.x > 0)
				tx++;
			else
				tx--;
				*/
			if (map.getTile(tx, ty) == 55 && powers[POWER_REDKEY]==1)	// red door
			{
				map.setTile(tx, ty, 0);
				FlxG.play(doorSnd);
			}
			if (map.getTile(tx, ty) == 56 && powers[POWER_GRNKEY]==1)	// green door
			{
				map.setTile(tx, ty, 0);
				FlxG.play(doorSnd);
			}
			if (map.getTile(tx, ty) == 57 && powers[POWER_BLUKEY]==1)	// blue door
			{
				map.setTile(tx, ty, 0);
				FlxG.play(doorSnd);
			}
			super.hitWall(Contact);
			return true;
		}
		
	}
}