# Aghanim Rework: Where the Code Is and How to Tweak It for Your Own Fork

This branch changes the final boss fight so it plays more like the original A Link to the Past fight: you keep your
inventory, the sword can hurt him (a direct hit shocks you unless you have the Dragon Sword or better),
you can reflect his energy balls back at him, and his attacks come in a random order that gets harder as his health
drops.

This file is for anyone who wants to fork the branch and build their own version of the fight. Everything below is
GameMaker (GML). "Object" means a GameMaker object such as `oBoss_Aghanim`; "event" means one of its code files
(`Create_0.gml`, `Step_0.gml`, `Alarm_N.gml`, ...). Paths are relative to the `game/` folder.

> File names on disk follow GameMaker's event numbering: `Create_0.gml` is the Create event, `Step_0.gml` is the Step event,
> `Step_2.gml` is the **End Step** event, and `Alarm_N.gml` is Alarm N. In the GameMaker IDE the events show up by their
> names, not these file names.

> Naming note: in this code, "Script" means two different things. GameMaker *scripts* are the `.gml` files under
> `scripts/`. Aghanim's `Script` *array* is his list of attack steps. This document says "attack list" for the array.

---

## 1. What changed (summary)

| Area | Change |
|---|---|
| Inventory | He no longer takes your items. `Inventory_ClearAll()` is gone from `Alarm_9.gml`. |
| Damage to him | The sword does normal damage (not bomb-only). A reflected energy ball and a sword beam do 4. |
| Shock rule | Hitting him directly with the sword shocks you unless you have the Dragon sword or better, or the Cape. |
| Reflecting | A real sword swing or spin sends his energy balls back at him. |
| Attack pattern | No bomb phase. A shuffled mix of energy balls, blue balls and a gravity ball that scales with his health. |
| Blue ball knockback | Softer, so one hit does not throw you off the floor. |
| Death check | He dies when Energy is effectively zero, not only when it is exactly zero. |

---

## 2. File map

| What | Where |
|---|---|
| Boss object, fight loop | `objects/oBoss_Aghanim/Step_0.gml` |
| Boss setup, starting Energy | `objects/oBoss_Aghanim/Create_0.gml` |
| Step types (enum), phase logic, attack-pattern builder | `scripts/__Boss_Aghanim/__Boss_Aghanim.gml` |
| Intro dialogue and item-taking sequence | `objects/oBoss_Aghanim/Alarm_5` ... `Alarm_10`, `Step_0.gml` (the `if(Intro)` block) |
| Old bomb phase (no longer used by the new patterns) | `objects/oBoss_Aghanim/Alarm_2.gml` |
| Gravity ball ends | `objects/oBoss_Aghanim/Alarm_6.gml` |
| Energy ball (also the held "charge" balls) | `objects/oAghanim_EnergyBall/` |
| Blue ball | `objects/oAghanim_NewBlueBall/` |
| Gravity ball | `objects/oAghanim_GravityBall/` |
| Teleport "black ball" he turns into when moving | `objects/oAghanim_MorphBall/` |
| Sword hitting a ball (the reflect) | `objects/oSword/Step_2.gml` |
| How weapons hurt him, the shock rule | `scripts/__Enemies/__Enemies.gml` |
| Damage the player takes from a projectile | `scripts/__Link/__Link.gml` (`LinkHit`, and the projectile check that calls it) |

---

## 3. How the fight works

His behaviour is a loop over an **attack list**, an array of steps:

```gml
Script[i++] = [AghanimScript.Move, [0,1,2,3,4,5,6,7,8]];
Script[i++] = [AghanimScript.Pause, 30];
Script[i++] = [AghanimScript.ChargeLR, 30];
Script[i++] = [AghanimScript.Shoot, AghanimWeapon.EnergyBall];
```

Each step is `[type, data]`. The types are the enum `AghanimScript` at the top of `__Boss_Aghanim.gml`. The code that
runs a step is the `switch(S[0])` inside `if(ScriptNext){` in `oBoss_Aghanim/Step_0.gml`. When a step finishes it sets
`ScriptNext = true`, and the next step in the list starts. After the last step the list wraps back to the first.

| Step | Data | What it does |
|---|---|---|
| `Pause` | frames | Stands still, then an alarm (`Alarm_0`) moves on |
| `ChargeL` / `ChargeR` | frames | Charges one hand |
| `ChargeLR` | frames | Charges both hands |
| `Shoot` | `AghanimWeapon.EnergyBall` or `.BlueBalls` | Fires one shot at Link, then moves on at once |
| `Move` | list of spots 0 to 8 | Teleports to a random spot from the list |
| `GravityBall` | unused | Casts the gravity ball; `Alarm_6` ends it |
| `Bombs` | unused | The original bomb phase, no longer used |

The spots are a 3 by 3 grid, numbered row by row (0 1 2 / 3 4 5 / 6 7 8).

---

## 4. The attack pattern: where to change difficulty

`Aghanim_BuildAttackPattern(_Inst)` in `scripts/__Boss_Aghanim/__Boss_Aghanim.gml` builds the attack list. It is called
from `Create_0.gml` and from `Step_0.gml` whenever the phase changes or the list starts over (so the order is
reshuffled). Call it as `Aghanim_BuildAttackPattern(id)`; the parameter is the boss instance.

**Phase** (0 to 3) comes from `Aghanim_GetPhase()`, which looks at his remaining Energy. His starting Energy is set in
`Create_0.gml`. If you change it, change the number inside `Aghanim_GetPhase` to match (or store it in a `MaxEnergy`
variable and use that in both places).

**Tuning tables.** Everything that sets difficulty is a table at the top of `Aghanim_BuildAttackPattern`, with one entry
per phase `[phase 0, 1, 2, 3]`:

| Table | Meaning |
|---|---|
| `_EnergyCount`, `_BlueCount`, `_GravityCount` | How many of each attack happen per cycle (the "bag") |
| `_EnergyCharge`, `_BlueCharge` | Wind-up frames before a shot |
| `_EnergyPauseMin/Max` | Random wait after an energy ball |
| `_BluePause` | Rest after each blue ball |
| `_BlueRoundsMin/Max` | How many blue balls in one volley (random between them) |
| `_BlueBurst` | Balls per burst in a volley (0 = no bursts) |
| `_BurstGap` | Extra wait between bursts |
| `_MovePauseMin/Max` | Wait after teleporting |
| `EnergyBallSpeed`, `BlueBallSpeed` (set from arrays) | Projectile speeds |

The attacks are shuffled into a random order each cycle, but the counts are guaranteed. To change the *shape* of an
attack, edit its `case` in the `switch(_Bag[b])` inside the same function.

**Add a new attack type**
1. Add a number for it to the bag (a new count table and a new `case`).
2. In the `case`, append steps with `Script[i++] = [...]`.
3. If it needs a new kind of step, add a name to `enum AghanimScript` and a matching `case AghanimScript.Name:` in
   `Step_0.gml`. Remember to set `ScriptNext = true` when it finishes, or the fight will freeze.

---

## 5. Hitting him

`scripts/__Enemies/__Enemies.gml`:
- The `EnemyDataInit(oBoss_Aghanim, ...)` row says how each weapon affects him. `H_FF` means "damage from the standard
  sword formula", `H_ND` means "clink, no damage", a number is a fixed damage amount, `H_Sh` shocks Link.
  Weapon order is Sword, Pot, Arrow, Boomerang, Hookshot, Bomb, Fire, Ice, SwordBeam, Stone, Transform.
- A bracketed value like `[4, 0]` means "first value while he is standing or shooting, second value while he is
  teleporting". `Enemy_LinkWeaponHit()` picks the value in a per-enemy `switch`; the `case oBoss_Aghanim:` there also
  holds the **shock rule** (`SwordLevel(Swords.Dragon)` and `oLink.Cape`). Change the sword level there to change who is
  safe.

Death: in `oBoss_Aghanim/Step_0.gml`, the check `Energy <= EnemyEnergyConsideredDead` (instead of `<= 0`) is what lets
sword hits finish him. Do not change it back to an exact zero test.

---

## 6. Reflecting energy balls

- `oSword/Step_2.gml`, inside `if(CheckCollision){`: finds an `oAghanim_EnergyBall` touching the sword. If it is not
  already reflected and is moving, it flips the ball:
  `Reflected = true`, `Enemy = false`, a new direction toward the boss, and a new speed.
- `oAghanim_EnergyBall/Step_0.gml`: while `Reflected` is true, a ball that touches the boss hurts him (through
  `Enemy_LinkWeaponHit` as a sword beam) and is destroyed.
- To make blue balls reflectable, copy the same pattern to those objects (they'll need their own
  `Reflected` flag).

---

## 7. Knockback and damage to the player

- Each projectile has `Damage`, `HitV` (push speed) and `HitTime` (push frames) in its `Create_0.gml`. Distance pushed
  is `HitV x HitTime` pixels. The blue ball was softened because in later phases you have to stand on the far side of the arena, and a full-strength push would carry Link off the floor.
- The damage taken is worked out from `Damage` and the player's defense (`Enemy_Attack()`), with a small minimum, so a
  heavily armored player still takes a little damage.

---

## 8. Intro and the removed item theft

The intro dialogue lives in `Create_0.gml` (`IntroMsg1Str`, `IntroMsg2Str`) and the `Alarm_5` to `Alarm_10` chain. The
original `Alarm_9.gml` called `Inventory_ClearAll()` to wipe the player's inventory; that call is removed. The bag and
explosion animation still play unless you also edit the intro chain. Several variables and helper functions
(`TakeItems_*`, `Aghanim_TakingItems()`) are left over from the original and can be tidied up if you want a cleaner
version.

---

## 9. Testing tips

- Give yourself a quick way to reach the boss floor and to choose your sword level.
- Check the final phase: the fastest blue-ball bursts should ideally still be dodgeable.
- A missing function call (for example from a typo in a renamed function) only fails at runtime. It's a good idea to play through the entire
  fight after any rename or adjustments.

---

## 10. Known limits

- The numbers are tuned for a player with only the starting gear. A fully geared player would likely take very little damage and the fight would be easier; there is no scaling for the player's gear or health. Damage to Aghanim through reflected Energy Balls is static at 4 (this can be tweaked in `__Enemies.gml`)
- The attacks are random, so occasionally the same attack happens twice or more in a row.
- Blue balls and the gravity ball cannot be reflected.
- Old unused code from the original (bomb phase, item taking) is still in the project if you want to add those back in.