# Experienced Driver

## Main Features

- Added a new **Driving** skill that allows players to gain Driving XP by driving vehicles.

- The Driving skill must first be unlocked by watching the newly added VHS tapes.
  - The VHS tapes and skill books will spawn normally at their corresponding locations throughout the game.

### ⚠️ No Driving XP will be accumulated before the skill is unlocked.

## Skill Bonuses

### Increase Vehicle Top Speed

Levels 1–10 provide a percentage-based bonus to vehicle top speed.

> For example, a Level 1 bonus of `0.08` results in a **top speed of 108%** of the vehicle's original value.

### Improve Vehicle Braking Performance

Provides a percentage-based improvement to vehicle braking performance.

> The scaling works in the same way as the top speed bonus.

### Reduce Vehicle Engine Noise

Levels 1–10 reduce the engine noise attribute by a percentage.

> For example, a Level 1 reduction of `0.03` results in **97% of the original** engine noise.

### Reduce Vehicle Part Collision Damage

Reduces damage dealt to vehicle parts through **active and passive collisions**.

> The reduction uses the same percentage-based scaling described above.

> **All of the above features can be individually enabled or disabled, and the parameters for each skill level can be freely adjusted in the Sandbox settings.**

---

## Compatibility & Known Issues

This mod can be safely removed from an existing save.

If you encounter conflicts with other mods or any bugs, please report them.

- Known to conflict with other mods that add or modify the Driving skill.
- If you are using any mods that **override UI tooltips**, please place this mod **after** those mods in the load order.

### Game Version

**Compatible with B42.20 and later.**

**Host mode** has not been fully tested. The functionality appears to work normally, but compatibility with **dedicated servers** is currently unknown.

### Multiplayer Known Issues

The following issues have only been observed in multiplayer. Please take note:

#### 1. Vehicle State Resets After Leaving the Game

When quitting the game while sitting in the driver's seat, the vehicle's state may reset.

The skill bonuses may not be automatically restored when entering the vehicle again.

**Solution:** Simply exit and re-enter the vehicle to restore the bonuses.

#### 2. Original Skill Level-Up Banner

After increasing the Driving skill level, the level-up notification banner may display the original field:

```text
IGUI_perks_Driving
```

This is a **base-game issue**.

When retrieving the skill's translation field, the game incorrectly concatenates `getName()` twice due to an error in `getType()`.

---

# Special Thanks & Disclaimer

> This mod was inspired by [Driving Skill [B42]](https://steamcommunity.com/sharedfiles/filedetails/?id=3407791878) and is **an independent reimplementation of a similar concept**.
>
> It was developed separately for the current version of Project Zomboid and **does not** directly incorporate the original mod's files or assets.
>
> I may add other interesting features in the future, such as increased damage when hitting zombies or functionality for driving animals away, depending on available free time.
>
> Special thanks again to [Afterworlds](https://steamcommunity.com/id/Afterworlds) for creating such a great mod.
>
> If you'd like, you can buy him a [Ko-fi](https://ko-fi.com/udomakestuff) — [OR buy me one](https://ko-fi.com/deepsleeping).
>
> ～(∠・ω< )⌒★

## Workshop Information

- **Workshop ID:** `3792957770`
- **Mod ID:** `NM_CR_ExperiencedDriver`
