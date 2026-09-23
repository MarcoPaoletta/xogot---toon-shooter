# Container Yard

A third person, over the shoulder arena shooter built in **Xogot for Mac** (a native Godot 4.7 editor) by **Claude Opus 5.5**, driven from the Claude desktop app through Xogot's `xo` command line tool. You are the green soldier holding a container yard against five waves of red bandits: run between stacked shipping containers, sandbag lines and a wrecked car, aim over your shoulder and fire. You start with a blaster, a pistol and a knife and find the other eleven weapons of the kit lying around the yard: revolvers, an SMG, shotguns, snipers, a grenade launcher, a rocket launcher, a second knife and a shovel. A weapon wheel held open with Tab shows all fourteen as their real 3D models, rotating. Bandits arrive on foot from the back of the yard and shoot in bursts when they see you; a container or a sandbag wall between you and them blocks their shots, but not yours over the sandbags. Clear the five waves for the results screen and the score to beat, or get overrun and see which wave did it.

It starts from an empty project, one free asset pack, one concept image and one design document. Every scene in the game is created and edited inside the Xogot editor by the agent (scene, node, material, particle and UI commands through `xo`), not hand written as `.tscn` text.

Built for the next Letta Corporation video.

## Running it

1. Install [Xogot for Mac](https://xogot.com/mac) (free while it is in beta) or Godot 4.7.
2. Open `project.godot`.
3. Press play. The game opens on the title screen over the live yard; Play starts a run of five waves.

| Input | Action |
|---|---|
| W A S D or the arrow keys | move, relative to the camera |
| Mouse | aim (the camera sits over the right shoulder) |
| Left button | fire (hold for the automatic weapons, press for the others, swing for the melee ones) |
| Right button | aim down the sights: narrower view, tighter spread, a scope for the two snipers |
| Hold Tab, move the mouse, release | the weapon wheel: pick any unlocked weapon (time slows to a quarter while it is open) |
| Mouse wheel / Q | next or previous unlocked weapon / swap back to the last one |
| Escape | pause (resume, restart, menu, music and sound toggles) |
| F1 (development only) | hold to snap to the concept image's camera, with the concept's two bandits posed, for the side by side comparisons |

You start with the blaster, the pistol and the knife; the other eleven weapons are crates around the yard. Walk into one to unlock it; it comes back 45 s later as an ammo refill. Sandbags and containers stop the bandits' shots; theirs come in bursts of three.

### Running the tests

`sh tools/run_tests.sh` with the project open in Xogot runs every suite: the structural ones in `tests/editor/` through `xo test run --root res://tests/editor`, the behaviour ones in `tests/game/` inside a fresh live arena through `xo game eval`, and the menu check (`tools/check_menu.py`). `python3 tools/gen_audio.py --verify` checks the three audio rules.

## The game design document

The full spec lives in [`docs/GDD.md`](docs/GDD.md) (also as [`docs/GDD.pdf`](docs/GDD.pdf)). It is written for an implementing agent, not for a human reader, and that changes what goes in it.

### How the GDD was created

1. **Start from what exists, not from a blank page.** The project began as an empty Xogot project plus the Quaternius pack already imported, and a concept image (`docs/concept/concept.png`). The GDD was written with **Claude Opus** in the Claude desktop app. Before writing, the model imported the pack, measured every model through `xo` (bounding boxes, animation clips, materials) and wrote [`docs/asset-inventory.md`](docs/asset-inventory.md), so that every 3D object named in the document is a real file with a known size. `Container_Long` in the GDD means `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Container_Long.gltf` in the project. An agent can build from that; it cannot build from "a container".

2. **Specify behaviour, never code.** The GDD says what happens, with numbers: the blaster fires 8 shots per second for 10 damage, a bandit walks at 4.0 units per second and holds at 9 units to fire a burst of 3, the camera sits 1.4 units over the right shoulder with a 50° field of view and no position smoothing. It contains no GDScript. The agent that builds has the whole project in front of it and writes better code than a spec can paste in.

3. **Every pillar and every non trivial mechanic carries an acceptance test.** The look is tested against the concept image with a side by side comparison after every visual milestone (`docs/evidence/`). The camera is tested by moving the player one unit and reading where the camera went the same frame. The enemies are tested by a differential test that fails a bandit which never moves. A test the agent can run is the difference between an agent that declares something finished and one that cannot.

4. **Scope is written down, including what is out.** Section 13 has an explicit cut list and a numbered build order where each step ends with a run in Xogot, a screenshot check and a commit. One thing is reserved on purpose for the live session that follows the build: one new enemy behaviour. Section 14 lists every asset the design needs that the pack does not contain, and what to do instead (audio synthesised by a script, effects and HUD drawn in code, container colours through material overrides).

5. **The document is versioned after each round of play, it is never rewritten.** The first build is one prompt: *create the game, follow @docs/GDD.md*. After playing that build, changes are written as a new section that supersedes the earlier ones, and the agent is pointed at the new section:
   - **1.0** the pre build specification (sections 0 to 15).
   - **1.1** the full arsenal: all fourteen weapons of the kit (section 16).
   - **1.2** three starting weapons, eleven unlocks placed around the yard, and the weapon wheel with rotating 3D models (section 17).
   - **1.3** implementation notes: where the shipped build deviated from 1.0 to 1.2 and why (section 18): the concept region placed again by back projection from the image, the camera at 3.0 / -8°, chain link fences that stop bodies but not bullets, flat colour ambient light, ballistic grenades, the bandits' elliptical spread, and how the tests run.

6. **Iterate with screenshots, not descriptions.** The concept image is the acceptance test for the look, judged in a fixed check order (camera height and horizon, distance and FOV, subject position, silhouettes, props, sky, ground, sun, fog, glow, grade, UI), fixing only the first failing item each time. The agent takes its own screenshots and runs the game through `xo`, so it checks its own work before reporting back.

The commit history of this repo follows the build order in section 13.2 one step per commit, so `git log` reads as the build diary.

## Layout

| Path | What it is |
|---|---|
| `docs/GDD.md`, `docs/GDD.pdf` | the game design document, all versions in one file |
| `docs/asset-inventory.md` | every model in the pack with its `res://` path and measured size |
| `docs/concept/concept.png` | the approved concept image, the acceptance test for the look |
| `docs/evidence/` | the concept comparisons (`comparison-01` to `04`, `comparison-final`), one screenshot per wave of a full run, the results and overrun screens, every weapon firing, the weapon wheel, the yard from above |
| `scenes/` | every scene, created in the Xogot editor: `arena.tscn`, `main.tscn`, `audio.tscn`, and `props/` (28 prop prefabs with collision), `actors/`, `weapons/` (14 weapons, grenade, rocket), `fx/`, `ui/` |
| `scripts/` | GDScript: one script per scene, the shared `weapons/weapon.gd`, and the `autoload/` singletons (`Game`, `Audio`) |
| `materials/`, `env/`, `fx/`, `shaders/`, `ui/` | container colours and effect materials, the yard environment, particle materials and meshes, the damage vignette, the UI theme |
| `tests/editor/`, `tests/game/` | the structural suites (`xo test run`) and the behaviour suites run inside the live game (`xo game eval`) |
| `tools/` | `gen_audio.py` (audio synthesiser and `--verify`), `compare.py` (concept comparisons and the value table), `check_menu.py`, `run_tests.sh` |
| `assets/Toon Shooter Game Kit - Dec 2022/` | Quaternius pack, untouched |
| `assets/audio/` | the SFX and music loops synthesised by `tools/gen_audio.py` |
| `.claude/skills/xogot/` | the `xo` skill Xogot installs for external agents |

At the `project-setup` tag only `docs/`, `assets/Toon Shooter Game Kit - Dec 2022/` and `.claude/` exist: the project holds the pack, the design document and nothing else, zero scenes, zero scripts. Everything else is the build.

## License

The project is released under the **MIT License** (see [`LICENSE`](LICENSE)). The `assets/` folder includes third party content that ships under its own license: the Quaternius Toon Shooter Game Kit is **CC0 1.0**. It keeps its license file inside its folder, and [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) lists it.

## Credits

- 3D art: [Toon Shooter Game Kit](https://quaternius.com/packs/toonshootergamekit.html) by Quaternius (CC0).
- Editor: [Xogot for Mac](https://xogot.com/mac).
- Build: Claude Opus 5.5 through the Claude desktop app; design document with Claude Opus.
- Produced by [Letta Corporation](https://lettacorporation.com).
