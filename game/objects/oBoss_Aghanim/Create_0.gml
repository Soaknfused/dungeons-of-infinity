event_inherited();

ScriptIndex = 0;
ScriptNext = true;

Energy = 32;
Phase = 0;
EnergyBallSpeed = 5;
BlueBallSpeed = 5;
Aghanim_BuildAttackPattern(id);

State = EnemyState.Standing;

Dir = DOWN;

Charge_InstL = noone;
Charge_InstR = noone;
Charge_ImageIndex = 0;
Charge_PosIndex = 0;
Charge_Speed = 0;
Charge_Lerp = 0.5;
Charge_Weapon = AghanimWeapon.EnergyBall;

EnergyBall_PalIndex = 0;
EnergyBall_PalDelay = 4;
alarm[1] = EnergyBall_PalDelay;

GravityBallInst = noone;
GravityBall = false;
GravityBallTime = 220;

ShotInst = noone;

ShootDelay = 15;
ShootSpeed = 6.5;

BlackballMorph = 255;
MorphToSpeed = 20;

BombIndex = 0;
BombDelay = 24;
BombsTotal = 5;
BombPosIndex = [6, 6, 7, 7, 8, 8];

MovePosX[0] = global.Level.Rooms[RoomIndex].x + 64
MovePosX[1] = global.Level.Rooms[RoomIndex].x + 128
MovePosX[2] = global.Level.Rooms[RoomIndex].x + 192
MovePosY[0] = global.Level.Rooms[RoomIndex].y + 58
MovePosY[1] = global.Level.Rooms[RoomIndex].y + 112
MovePosY[2] = global.Level.Rooms[RoomIndex].y + 176

CurrentPos = 1;
MovePos = 0;

FinalExplosionsInit = false;
FinalExplosions = 16;
BossDestroyed = false;


Hit_Sound = Sound_Boss_Hit;


Intro = true;

IntroMsg1 = false;
IntroMsg1Str = "Well well, if it isn't my old friend Link. You are foolish to have come here, I have grown more powerful since the last time you saw me. This time you don't stand a chance. MWAH HA HA!";

TakeItems = false;
TakeItems_ShowBag = false;
TakeItems_ShowShield = false;
TakeItems_BagPosX = 0;
TakeItems_BagPosY = 0;
TakeItems_BagV = 0;
TakeItems_BagA = 0.15;
TakeItems_Explosions = 8;
TakeItems_ExplosionDelay = 8;

IntroMsg2 = false;
IntroMsg2Str = "Now, prepare to meet your demise!";

alarm[5] = 30;


LightRadius[0] = 0.9;
LightRadius[1] = 0.95;
LightRadius[2] = 1;
LightRadius[3] = 1.05;
LightRadius[4] = 1.1;
LightIndex = Lighting_CreateLight(RoomIndex, x, y, LightRadius[0], [0.9, 0.9, 1.4]);
Lighting_UpdateLight_Visible(RoomIndex, LightIndex, false);

LightIndex_Body = Lighting_CreateLight(RoomIndex, x, y - 14, 0.2, [0.6, 0.6, 0.6]);