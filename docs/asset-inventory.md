# Asset inventory: Toon Shooter Game Kit (Dec 2022)

Pack folder: `res://assets/Toon Shooter Game Kit - Dec 2022/` (Quaternius, CC0 1.0, https://quaternius.com/packs/toonshootergamekit.html). The pack's own folder structure is untouched. Every model exists three times, as glTF, FBX and OBJ, in sibling folders `glTF/`, `FBX/` and `OBJ/` under `Characters/`, `Environment/` and `Guns/`; the `Blends/` folders carry a `.gdignore` and are not imported. **The glTF files are the canonical references for the build**; the FBX and OBJ copies are listed once at the end and are not used.

Measured in Xogot 1.7.2 (Godot 4.7.2) by instantiating each imported glTF and merging the world space AABB of every `MeshInstance3D` inside it, on 2026-09-20. Sizes are width x height x depth in Godot units (X x Y x Z) in the model's own space; `min Y` is the lowest point of the mesh, so a model with `min Y` of 0.00 stands on its origin. Import check: 74 glTF, 74 FBX, 74 OBJ and 5 textures imported with **zero errors** (only the harmless "OBJ: Ambient light ignored in PBR" warnings from the OBJ duplicates).

## How to read the sizes

- A **character** is 2.2 units tall from feet to the top of the head and stands on Y 0 (feet at Y about 0.0). The 2.7 unit width is the T pose of the rest frame: arms out. Shoulder height is about 1.6, eye height about 1.9.
- A **crate** is a 0.79 unit cube. A **small container** is 2.19 x 2.13 x 2.09 (one crate is roughly a third of a container edge). A **long container** is 4.36 x 2.13 x 2.09 (exactly two small containers end to end).
- A **sandbag wall** (`SackTrench`) is 3.35 wide, 1.28 tall: chest height cover for a 2.2 unit character. The small one is 2.48 wide, 1.00 tall: waist height.
- The **water tower** (`WaterTank_Platform`) is only 3.52 tall on its own, 1.62 x 2.35 in plan: it is a tank on a short platform, not a full height tower. To read as the tall tower in the concept it needs to be scaled (about 2.5x gives 8.8 tall) or placed on top of stacked containers.
- The **tank** is 2.37 x 2.14 x 2.50: about one container's footprint, a character's height. The **wrecked car** is 2.64 x 1.76 x 5.49: long along Z.
- **Trees** are 5.1 to 6.2 tall, 2.1 to 4.3 wide, all standing on Y 0.
- The **chain link fence** (`MetalFence`) is one panel 3.55 wide x 2.88 tall x 0.11 deep, textured with `Texture_Fence`. `Fence` and `Fence_Long` are low concrete barriers (1.05 tall), not chain link.
- **Weapons** in `Guns/glTF` are loose models with the grip near the origin (min Y between -0.1 and -0.5) and the barrel along +X for most guns; the same 14 models are also bundled inside each character file, attached to the right hand and visible by default, see the character notes.

## Characters (`Characters/glTF/`)

| Model | `res://` path | Size (W x H x D) | min Y | Notes |
|---|---|---|---|---|
| `Character_Soldier` | `res://assets/Toon Shooter Game Kit - Dec 2022/Characters/glTF/Character_Soldier.gltf` | 2.73 x 2.34 x 2.45 (T pose, all weapons visible) | -0.13 | the player. Green uniform (`Character_Main`, `Pants`, `Skin`), `Head`, `Body`, `ShoulderPad_L`, `ShoulderPad_R` meshes |
| `Character_Enemy` | `res://assets/Toon Shooter Game Kit - Dec 2022/Characters/glTF/Character_Enemy.gltf` | 2.72 x 2.41 x 2.51 (T pose, all weapons visible) | -0.13 | the bandit. Red outfit (`Enemy_Red`, `Skin`), `Character_Enemy` and `Character_Enemy_Head` meshes |
| `Character_Hazmat` | `res://assets/Toon Shooter Game Kit - Dec 2022/Characters/glTF/Character_Hazmat.gltf` | 2.72 x 2.25 x 2.48 (T pose, all weapons visible) | -0.13 | yellow hazmat suit (`Hazmat_Main`), `Character_Hazmat` and `Character_Hazmat_Head` meshes. Unused in 1.0 |

**Shared structure of all three characters.** Root `Node3D` (named `Character_Soldier`, `Character_Enemy2`, `Character_Hazmat2` inside the file), child `CharacterArmature` (`Node3D`) holding `Skeleton3D` with 43 bones (`Root`, `Hips`, `Abdomen`, `Torso`, `Neck`, `Head`, `Shoulder.L/R`, `UpperArm.L/R`, `LowerArm.L/R`, three finger chains per hand, `UpperLeg.L/R`, `LowerLeg.L/R`, `Foot.L/R`), and an `AnimationPlayer`. Body mesh alone: 2.72 x 2.22 x 0.69 (soldier), head top at Y 2.18 (soldier) to 2.28 (enemy).

**Weapons inside the characters.** Every character file also contains 14 weapon meshes parented to the right index finger bone (`Index1_R`): `AK`, `GrenadeLauncher`, `Knife_1`, `Knife_2`, `Pistol`, `Revolver`, `Revolver_Small`, `RocketLauncher`, `ShortCannon`, `Shotgun`, `Shovel`, `SMG`, `Sniper`, `Sniper_2`. **All 14 are visible by default**, so a freshly instanced character holds a fan of every gun at once. The build must hide all but the chosen one (the measured whole character AABB above includes them, which is why the depth reads 2.5 instead of 0.7).

**Animation clips (identical in all three, name and length):** `Idle` 1.67 s, `Idle_Shoot` 0.37 s, `Walk` 1.00 s, `Walk_Shoot` 1.00 s, `Run` 0.73 s, `Run_Gun` 0.73 s, `Run_Shoot` 0.73 s, `Jump` 0.30 s, `Jump_Idle` 1.00 s, `Jump_Land` 0.43 s, `Duck` 1.67 s, `Punch` 0.87 s, `HitReact` 0.43 s, `Death` 0.77 s, `Wave` 1.67 s, `Yes` 1.67 s, `No` 1.67 s.

## Weapons (`Guns/glTF/`)

| Model | `res://` path | Size (W x H x D) | min Y | Materials |
|---|---|---|---|---|
| `AK` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/AK.gltf` | 1.42 x 0.73 x 0.15 | -0.32 | Grey, Grey2, Wood, DarkGrey |
| `Pistol` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/Pistol.gltf` | 0.79 x 0.48 x 0.12 | -0.13 | Grey, DarkGrey, Wood |
| `Revolver` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/Revolver.gltf` | 0.99 x 0.53 x 0.18 | -0.18 | Grey2, Grey, DarkGrey, Wood |
| `Revolver_Small` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/Revolver_Small.gltf` | 0.66 x 0.51 x 0.16 | -0.14 | Grey2, Grey, DarkGrey, Wood |
| `SMG` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/SMG.gltf` | 1.14 x 0.62 x 0.13 | -0.26 | Grey, DarkGrey, Grey2, Black |
| `Shotgun` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/Shotgun.gltf` | 1.55 x 0.33 x 0.12 | -0.16 | Grey2, Grey, DarkGrey, Wood |
| `Sniper` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/Sniper.gltf` | 2.05 x 0.76 x 0.19 | -0.30 | DarkGrey, Grey, Black |
| `Sniper_2` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/Sniper_2.gltf` | 1.74 x 0.79 x 0.19 | -0.32 | Grey, DarkGrey, Wood |
| `GrenadeLauncher` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/GrenadeLauncher.gltf` | 1.20 x 0.56 x 0.48 | -0.28 | Grey, DarkGrey, Wood, Grey2 |
| `RocketLauncher` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/RocketLauncher.gltf` | 1.30 x 0.75 x 0.47 | -0.11 | Black, Grey, DarkGrey, Red |
| `ShortCannon` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/ShortCannon.gltf` | 1.21 x 0.31 x 0.13 | -0.16 | Grey, DarkGrey, Wood |
| `Knife_1` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/Knife_1.gltf` | 0.26 x 1.41 x 0.13 | -0.24 | Grey, LightGrey, DarkWood, Wood |
| `Knife_2` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/Knife_2.gltf` | 0.25 x 1.35 x 0.13 | -0.18 | DarkGrey, Black, LightGrey |
| `Shovel` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/Shovel.gltf` | 0.35 x 1.11 x 0.09 | -0.44 | DarkWood, Grey, Red |
| `Grenade` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/Grenade.gltf` | 0.56 x 0.61 x 0.46 | -0.28 | Green, DarkGrey, DarkGreen |
| `FireGrenade` | `res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/FireGrenade.gltf` | 0.57 x 0.85 x 0.47 | -0.52 | Red, DarkRed, Black, Grey |

## Environment: structures, containers, walls and fences (`Environment/glTF/`)

| Model | `res://` path | Size (W x H x D) | min Y | Materials |
|---|---|---|---|---|
| `Structure_1` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Structure_1.gltf` | 7.98 x 4.56 x 4.52 | -0.05 | Red, Cardboard, Tape, Wood, Grey, Grey2 |
| `Structure_2` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Structure_2.gltf` | 10.58 x 7.79 x 7.97 | -0.16 | Green, Yellow, Cardboard, Tape, Wood, Grey, Grey2, Wood_Light |
| `Structure_3` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Structure_3.gltf` | 7.87 x 9.52 x 4.52 | -0.03 | Cardboard, Tape, Wood, Grey, Grey2, Blue |
| `Structure_4` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Structure_4.gltf` | 10.39 x 7.66 x 7.41 | -0.03 | Cyan, Yellow, Wood, Grey, Green, Black, DarkGrey |
| `Container_Long` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Container_Long.gltf` | 4.36 x 2.13 x 2.09 | 0.03 | Red, Grey |
| `Container_Small` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Container_Small.gltf` | 2.19 x 2.13 x 2.09 | 0.04 | Blue, Grey |
| `WaterTank_Platform` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/WaterTank_Platform.gltf` | 1.62 x 3.52 x 2.35 | -0.05 | Grey, Grey2, White |
| `WaterTank_Floor` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/WaterTank_Floor.gltf` | 1.76 x 1.91 x 4.57 | -0.03 | Grey, Grey2, White |
| `BrickWall_1` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/BrickWall_1.gltf` | 2.24 x 0.34 x 0.21 | -0.01 | Brick |
| `BrickWall_2` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/BrickWall_2.gltf` | 2.24 x 0.70 x 0.21 | -0.01 | Brick |
| `MetalFence` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/MetalFence.gltf` | 3.55 x 2.88 x 0.11 | 0.00 | Grey, Texture_Fence |
| `Fence` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Fence.gltf` | 0.94 x 1.05 x 0.62 | 0.00 | Grey |
| `Fence_Long` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Fence_Long.gltf` | 1.33 x 1.05 x 0.62 | 0.00 | Grey |
| `Barrier_Fixed` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Barrier_Fixed.gltf` | 3.81 x 3.18 x 0.67 | 0.00 | Grey, DarkGrey, Yellow, White, Texture_Fence, Red, Wood |
| `Barrier_Large` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Barrier_Large.gltf` | 3.81 x 3.18 x 0.67 | 0.00 | Grey, DarkGrey, Yellow, White, Texture_Fence |
| `Barrier_Single` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Barrier_Single.gltf` | 1.89 x 0.63 x 0.66 | 0.00 | Grey, DarkGrey, Yellow, White |
| `Barrier_Trash` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Barrier_Trash.gltf` | 4.49 x 2.51 x 1.31 | -0.02 | Wood, Wood_Light, Sack, Black, Grey, Red |
| `SackTrench` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/SackTrench.gltf` | 3.35 x 1.28 x 0.92 | -0.03 | Sack |
| `SackTrench_Small` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/SackTrench_Small.gltf` | 2.48 x 1.00 x 0.92 | -0.03 | Sack |
| `StreetLight` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/StreetLight.gltf` | 0.42 x 5.65 x 2.09 | -0.01 | Grey, Light |
| `Pipes` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Pipes.gltf` | 1.00 x 0.96 x 4.27 | -0.02 | Grey, Grey2 |

## Environment: trees (`Environment/glTF/`)

| Model | `res://` path | Size (W x H x D) | min Y | Materials |
|---|---|---|---|---|
| `Tree_1` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Tree_1.gltf` | 3.44 x 5.86 x 3.31 | -0.01 | Tree_Wood, Tree_Green |
| `Tree_2` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Tree_2.gltf` | 2.08 x 6.22 x 2.08 | 0.00 | Tree_Wood, Tree_Green |
| `Tree_3` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Tree_3.gltf` | 4.27 x 5.59 x 2.64 | 0.00 | Tree_Green, Tree_Wood |
| `Tree_4` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Tree_4.gltf` | 3.30 x 5.08 x 2.63 | 0.00 | Tree_Wood, Tree_Green |

## Props (`Environment/glTF/`)

| Model | `res://` path | Size (W x H x D) | min Y | Materials |
|---|---|---|---|---|
| `Crate` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Crate.gltf` | 0.79 x 0.79 x 0.79 | 0.00 | Wood, Wood_Light |
| `CardboardBoxes_1` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/CardboardBoxes_1.gltf` | 0.98 x 0.51 x 0.73 | 0.00 | Cardboard, Tape |
| `CardboardBoxes_2` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/CardboardBoxes_2.gltf` | 0.98 x 0.95 x 0.92 | 0.00 | Cardboard, Tape |
| `CardboardBoxes_3` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/CardboardBoxes_3.gltf` | 1.26 x 2.25 x 1.21 | 0.00 | Cardboard, Tape |
| `CardboardBoxes_4` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/CardboardBoxes_4.gltf` | 1.42 x 1.75 x 0.99 | 0.02 | Cardboard, Tape |
| `Pallet` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Pallet.gltf` | 1.70 x 0.19 x 1.46 | -0.01 | Wood |
| `Pallet_Broken` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Pallet_Broken.gltf` | 1.69 x 0.25 x 1.47 | 0.00 | Wood, Wood_Light |
| `WoodPlanks` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/WoodPlanks.gltf` | 0.72 x 0.12 x 1.73 | 0.10 | Wood, Wood_Light |
| `ExplodingBarrel` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/ExplodingBarrel.gltf` | 0.78 x 1.02 x 0.78 | 0.00 | Red, Grey, White |
| `ExplodingBarrel_Spilled` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/ExplodingBarrel_Spilled.gltf` | 2.53 x 0.80 x 1.40 | -0.05 | Red, Grey, Oil, White |
| `GasCan` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/GasCan.gltf` | 0.80 x 1.05 x 0.34 | 0.00 | Red, DarkRed, Black |
| `GasTank` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/GasTank.gltf` | 1.01 x 1.39 x 1.01 | 0.00 | Yellow, Grey, White |
| `TrashContainer` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/TrashContainer.gltf` | 2.44 x 2.03 x 1.30 | -0.04 | Green, DarkGrey, Grey |
| `TrashContainer_Open` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/TrashContainer_Open.gltf` | 3.16 x 3.34 x 2.63 | -0.07 | Green, DarkGrey, Grey, Black, Oil |
| `TrafficCone` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/TrafficCone.gltf` | 0.67 x 0.64 x 0.67 | 0.00 | Orange, White |
| `Sign` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Sign.gltf` | 0.57 x 1.03 x 0.26 | 0.02 | Yellow, Brown |
| `Sofa` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Sofa.gltf` | 3.35 x 1.32 x 1.46 | 0.00 | Red |
| `Sofa_Small` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Sofa_Small.gltf` | 2.03 x 1.32 x 1.46 | 0.00 | Red |
| `Debris_Pile` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Debris_Pile.gltf` | 2.12 x 0.16 x 2.63 | 0.01 | Wood, Grey, Red |
| `Debris_Tires` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Debris_Tires.gltf` | 1.76 x 1.09 x 1.14 | -0.03 | Black |
| `Debris_Papers_1` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Debris_Papers_1.gltf` | 1.18 x 0.00 x 1.23 | 0.00 | White |
| `Debris_Papers_2` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Debris_Papers_2.gltf` | 1.24 x 0.00 x 1.05 | 0.00 | White |
| `Debris_Papers_3` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Debris_Papers_3.gltf` | 0.60 x 0.00 x 0.73 | 0.00 | White |
| `BearTrap_Open` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/BearTrap_Open.gltf` | 0.88 x 0.20 x 1.04 | -0.01 | Grey |
| `BearTrap_Closed` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/BearTrap_Closed.gltf` | 0.83 x 0.50 x 1.04 | -0.01 | Grey |
| `Landmine` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Landmine.gltf` | 1.11 x 0.29 x 1.11 | -0.01 | DarkGrey, Red, Grey |
| `Health` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Health.gltf` | 0.86 x 0.74 x 0.40 | 0.00 | Green, White, DarkGreen |
| `Key` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Key.gltf` | 0.55 x 0.28 x 0.09 | -0.14 | Grey |

## Vehicles (`Environment/glTF/`)

| Model | `res://` path | Size (W x H x D) | min Y | Materials |
|---|---|---|---|---|
| `Tank` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Tank.gltf` | 2.37 x 2.14 x 2.50 | 0.00 | Grey, Tank_Main, Tank_Main2, Black.001 |
| `Debris_BrokenCar` | `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Debris_BrokenCar.gltf` | 2.64 x 1.76 x 5.49 | -0.10 | Rust, Black, Grey, Rust2 |

## Textures

| File | `res://` path | Use |
|---|---|---|
| `Fence.png` | `res://assets/Toon Shooter Game Kit - Dec 2022/Texture/Fence.png` | chain link alpha texture used by `MetalFence`, `Barrier_Fixed`, `Barrier_Large` (the glTF importer also extracted copies next to those models as `MetalFence_Fence.png`, `Barrier_Fixed_Fence.png`, `Barrier_Large_Fence.png`) |
| `Preview.jpg` | `res://assets/Toon Shooter Game Kit - Dec 2022/Preview.jpg` | the pack's own promotional render, reference only |

## Effects

The pack contains **no effect assets**: no muzzle flash, no impact, no particle texture, no decal, no audio. Everything in that category is generated by the build (GPU particles with built in meshes, code drawn UI, synthesised audio). See the missing assets table in the GDD.

## FBX and OBJ duplicates (not used)

The same 74 models exist as `.fbx` in `Characters/FBX/`, `Environment/FBX/`, `Guns/FBX/` and as `.obj` (with `.mtl`) in `Characters/OBJ/`, `Environment/OBJ/`, `Guns/OBJ/`, with the same base names as the glTF list above (for example `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/FBX/Crate.fbx` and `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/OBJ/Crate.obj`). They import without errors and stay in the project untouched, but the build references only the glTF files. The `.blend` sources in each `Blends/` folder are excluded from import by a `.gdignore`.

## Models that failed to import

None. All 222 model files and 5 textures imported on the first scan.
