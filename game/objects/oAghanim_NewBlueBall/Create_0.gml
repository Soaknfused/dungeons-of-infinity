event_inherited();

OutsideRoomDestroy = false;
OutsideCameraDestroy = true;

DestroyAnimation = true;

Enemy = true;

Damage = 1;

//Softer knockback than the original (was HitV 3, HitTime 14)
//so one hit doesn't guarantee you fall off the floor
HitV = 2.5;
HitTime = 12;

LightIndex = Lighting_CreateLight(RoomIndex, x, y, 0.65, [0.5, 1.1, 1.6]);