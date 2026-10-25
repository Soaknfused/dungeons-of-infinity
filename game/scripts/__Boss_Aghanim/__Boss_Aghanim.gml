enum AghanimScript{
	Pause,
	ChargeL,
	ChargeR,
	ChargeLR,
	Shoot,
	Move,
	Bombs,
	GravityBall
}

enum AghanimWeapon{
	EnergyBall,
	BlueBalls
	
}

global.AghanimHandPos[UP] = [-9, -28, 9, -28];
global.AghanimHandPos[DOWN] = [11, -22, -11, -22];
global.AghanimHandPos[LEFT] = [-8,-17,-8,-23];
global.AghanimHandPos[RIGHT] = [8,-23,8,-17];
global.AghanimHandPos[BOTTOMLEFT] = [-3,-14,-11,-22];
global.AghanimHandPos[BOTTOMRIGHT] = [11,-22,3,-14];


function Aghanim_FacingLinkDir(){
	
	var _Dir = point_direction(x, y, oLink.x, oLink.y);
	
	if(_Dir >= 45 && _Dir < 135) return UP
	else if( (_Dir >= 0 && _Dir < 45) || (_Dir >= 330 && _Dir <= 360) ) return RIGHT
	else if(_Dir >= 135 && _Dir < 210) return LEFT
	else if(_Dir >= 210 && _Dir < 235) return BOTTOMLEFT
	else if(_Dir >= 235 && _Dir < 305) return DOWN
	else if(_Dir >= 305 && _Dir < 330) return BOTTOMRIGHT 
		
}

function Aghanim_SetSprite(){
	
	switch(Dir){
		case UP: sprite_index = sBoss_Aghanim_Up; break;
		case DOWN: sprite_index = sBoss_Aghanim_Down; break;
		case LEFT: sprite_index = sBoss_Aghanim_Left; break;
		case RIGHT: sprite_index = sBoss_Aghanim_Right; break;
		case BOTTOMLEFT: sprite_index = sBoss_Aghanim_DownLeft; break;
		case BOTTOMRIGHT: sprite_index = sBoss_Aghanim_DownRight; break;		
	}
	
}

function Aghanim_UpdateCharge(){

	var _Lerp = clamp(Charge_PosIndex - 0.25, 0, Charge_Lerp);

	if(Charge_PosIndex < 0.5){
		Charge_ImageIndex = 2;
	}else if(Charge_PosIndex < 0.75){
		Charge_ImageIndex = 1;
	}else{
		Charge_ImageIndex = 0;
	}

	var _HandPosLX = global.AghanimHandPos[Dir][0];
	var _HandPosLY = global.AghanimHandPos[Dir][1];
	var _HandPosRX = global.AghanimHandPos[Dir][2];
	var _HandPosRY = global.AghanimHandPos[Dir][3];
	
	with(Charge_InstL){
		
		switch(other.Dir){

			case LEFT: 
				depth = other.depth - 5;
				break;
				
			case UP:
			case RIGHT: 
				depth = other.depth + 5;			
				break;

			case BOTTOMRIGHT:
				depth = other.depth - 3;
				break;
				
			default: 
				depth = other.depth - 5;
				break;
		}

		x = other.x + lerp(_HandPosLX, _HandPosRX, _Lerp);
		y = other.y + lerp(_HandPosLY, _HandPosRY, _Lerp);
		
		image_index = other.Charge_ImageIndex;
		
	}

	with(Charge_InstR){
		
		switch(other.Dir){

			case LEFT:  
				depth = other.depth + 5;
				break;
				
			case UP:
				depth = other.depth + 5;					
				break;
			
			case BOTTOMLEFT:
				depth = other.depth - 3;
				break;
				
			default: 
				depth = other.depth - 5;
				break;
		}

		x = other.x + lerp(_HandPosRX, _HandPosLX, _Lerp);
		y = other.y + lerp(_HandPosRY, _HandPosLY, _Lerp);
		
		image_index = other.Charge_ImageIndex;
		
	}


}


function Aghanim_DropBomb(_x, _y){
	
	
	var _BombInst = instance_create_layer(_x, _y, "Objs_Upper", oBomb);
	with(_BombInst){
		z = 48;
		vz = -0.5;
		State = PickupObjState.Travelling;
		Red = true;
		ObjSetY(y);
		alarm[0] = 55;
	}
	
	var _PoofInst = instance_create_layer(_x, _y - 32, EffectLayer(UPPER), oPoof_NoSound);
	
	audio_play_sound(Sound_SwordBeam, 1, false);
	
	audio_play_sound(Sound_Fall, 1, false);

	
}

function Aghanim_TakingItems(){
	
	if(global.Level.Index == DungeonLevel.Aghanim2){ //once AGhanim grabs items, don't draw shield. Shield form inventory will eventually be destroyed, so this only applies during the taking phase
		with(oBoss_Aghanim){
			if(Intro && TakeItems && TakeItems_ShowBag){
				return true;
			}
		}		
	}	
	
	return false;
	
}

// How much of Link's defense Aghanim's projectiles ignore. 0 = normal defense, 1 = defense does nothing.
#macro AGHANIM_DEFENSE_BYPASS 0.75

/// @description Raises a projectile's damage so Link's defense counts for less against Aghanim.
function Aghanim_ProjectileDamage(_Base){
	return _Base + oLink.DefensePoints * 0.25 * AGHANIM_DEFENSE_BYPASS;
}

/// @description Works out how far into the fight the player is from Aghanim's remaining Energy
/// @returns {Real} Phase from 0 to 3.
function Aghanim_GetPhase(){
	//0 = full hp... 3= nearly dead. Based on Energy so it works with any damage source.
	return clamp(floor((32 - Energy) / 8), 0, 3);
}

/// @description Builds Aghanim's attack list (the Script array) for the current phase. Each cycle
/// has a fixed number of energy ball, blueball, and gravity ball attacks, shuffled into a random order.
/// Later phases shoot faster, wait less, and fire longer blue-ball volleys (bursts of 3 in the last phase).
/// All the tuning numbers are in the tables at the top of this function.
/// @param {Id.Insance} _Inst the boss instance to build the list on.

function Aghanim_BuildAttackPattern(_Inst){

	with(_Inst){

		var p = Phase;

		//---- Guaranteed attacks per cycle: [phase 0, 1, 2, 3] ----
		var _EnergyCount = [3, 3, 3, 4];
		var _BlueCount   = [1, 1, 2, 2];
		var _GravityCount= [1, 1, 1, 1];

		//---- Timings: [phase 0..3] ----
		var _EnergyCharge = [30, 26, 22, 18];
		var _EnergyPauseMin = [40, 30, 20, 12];  //wait after an energy ball is random in [min, max]
		var _EnergyPauseMax = [55, 42, 30, 20]; //longest wait after firing an Energy Ball (in frames)
		var _BlueCharge   = [15, 13, 11, 3]; //Wind up frames for Blue Ball attack.
		var _BluePause    = [12, 10, 8, 3]; //Wait period following Blue Ball attack before moving on
		var _BlueRoundsMin= [4, 4, 5, 6]; //Fewest Blue Balls fired in one attack
		var _BlueRoundsMax= [4, 5, 7, 9]; //never more than 9
		var _MovePauseMin = [16, 12, 8, 5]; //shortest wait after he lands in a new spot before charging an attack, in frames
		var _MovePauseMax = [26, 20, 14, 10]; //longest wait after he lands in a new spot before charging an attack, in frames
		var _BlueBurst = [0, 0, 0, 3]; //Balls per burst, 0 = no bursts (fire all rounds in a row)
		var _BurstGap = [0, 0, 0, 20]; //Extra wait between bursts, in frames

		EnergyBallSpeed = [5.0, 5.5, 6.0, 6.5][p];
		BlueBallSpeed   = [5.0, 5.5, 6.5, 8.0][p];

		//---- Fill the bag, then shuffle: 0 = energy, 1 = blue, 2 = gravity ----
		var _Bag = [];
		repeat(_EnergyCount[p]) array_push(_Bag, 0);
		repeat(_BlueCount[p]) array_push(_Bag, 1);
		repeat(_GravityCount[p]) array_push(_Bag, 2);
		_Bag = array_shuffle(_Bag);

		Script = [];
		var i = 0;

		for(var b = 0; b < array_length(_Bag); b++){

			switch(_Bag[b]){

				case 0: //energy ball
					Script[i++] = [AghanimScript.Move, [0,1,2,3,4,5,6,7,8]];
					Script[i++] = [AghanimScript.Pause, irandom_range(_MovePauseMin[p], _MovePauseMax[p])];
					Script[i++] = [AghanimScript.ChargeLR, _EnergyCharge[p]];
					Script[i++] = [AghanimScript.Shoot, AghanimWeapon.EnergyBall];
					Script[i++] = [AghanimScript.Pause, irandom_range(_EnergyPauseMin[p], _EnergyPauseMax[p])];
					break;

				case 1: //blue balls
					Script[i++] = [AghanimScript.Move, [0,2]];
					Script[i++] = [AghanimScript.Pause, irandom_range(_MovePauseMin[p], _MovePauseMax[p])];
					var _Rounds = irandom_range(_BlueRoundsMin[p], _BlueRoundsMax[p]);
					for(var r = 0; r < _Rounds; r++){
						Script[i++] = [(r mod 2 == 0) ? AghanimScript.ChargeL : AghanimScript.ChargeR, _BlueCharge[p]];
						Script[i++] = [AghanimScript.Shoot, AghanimWeapon.BlueBalls];
						Script[i++] = [AghanimScript.Pause, _BluePause[p]];
						//end of a burst (and not the last round): rest before the next one
						if(_BlueBurst[p] > 0 && (r + 1) mod _BlueBurst[p] == 0 && r < _Rounds - 1){
							Script[i++] = [AghanimScript.Pause, _BurstGap[p]];
						}
					}
					Script[i++] = [AghanimScript.Pause, irandom_range(_MovePauseMin[p], _MovePauseMax[p])];
					break;

				case 2: //gravity ball
					Script[i++] = [AghanimScript.Move, [7]];
					Script[i++] = [AghanimScript.Pause, irandom_range(_MovePauseMin[p], _MovePauseMax[p])];
					Script[i++] = [AghanimScript.ChargeLR, 30];
					Script[i++] = [AghanimScript.GravityBall, 0];
					break;

			}
		}

		ScriptLen = array_length(Script);
		ScriptIndex = 0;
		ScriptIndexBombMove = 0;

	}

}