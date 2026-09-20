# Container Yard

A third person, over the shoulder arena shooter built in **Xogot for Mac** (a native Godot 4.7 editor) by **TBD, filled after the build**, driven from the Claude desktop app through Xogot's `xo` command line tool. You are the green soldier holding a container yard against five waves of red bandits: run between stacked shipping containers, sandbag lines and a wrecked car, aim over your shoulder and fire a blaster that never runs dry. Bandits arrive on foot from the back of the yard and shoot in bursts when they see you; a container or a sandbag wall between you and them blocks their shots, but not yours over the sandbags. Clear the five waves for the results screen and the score to beat, or get overrun and see which wave did it.

It starts from an empty project, one free asset pack, one concept image and one design document. Every scene in the game is created and edited inside the Xogot editor by the agent (scene, node, material, particle and UI commands through `xo`), not hand written as `.tscn` text.

Built for the next Letta Corporation video.

## Running it

1. Install [Xogot for Mac](https://xogot.com/mac) (free while it is in beta) or Godot 4.7.
2. Open `project.godot`.
3. Press play. Controls: TBD, filled after the build (the design specifies WASD to move, mouse to aim, left button to fire, right button to aim, Escape to pause; Tab is a development only view that snaps the camera to the concept image's pose).

## The game design document

The full spec lives in [`docs/GDD.md`](docs/GDD.md) (also as [`docs/GDD.pdf`](docs/GDD.pdf)). It is written for an implementing agent, not for a human reader, and that changes what goes in it.

### How the GDD was created

1. **Start from what exists, not from a blank page.** The project began as an empty Xogot project plus the Quaternius pack already imported, and a concept image (`docs/concept/concept.png`). The GDD was written with **Claude Opus** in the Claude desktop app. Before writing, the model imported the pack, measured every model through `xo` (bounding boxes, animation clips, materials) and wrote [`docs/asset-inventory.md`](docs/asset-inventory.md), so that every 3D object named in the document is a real file with a known size. `Container_Long` in the GDD means `res://assets/Toon Shooter Game Kit - Dec 2022/Environment/glTF/Container_Long.gltf` in the project. An agent can build from that; it cannot build from "a container".

2. **Specify behaviour, never code.** The GDD says what happens, with numbers: the blaster fires 8 shots per second for 10 damage, a bandit walks at 4.0 units per second and holds at 9 units to fire a burst of 3, the camera sits 1.4 units over the right shoulder with a 50° field of view and no position smoothing. It contains no GDScript. The agent that builds has the whole project in front of it and writes better code than a spec can paste in.

3. **Every pillar and every non trivial mechanic carries an acceptance test.** The look is tested against the concept image with a side by side comparison after every visual milestone (`docs/evidence/`). The camera is tested by moving the player one unit and reading where the camera went the same frame. The enemies are tested by a differential test that fails a bandit which never moves. A test the agent can run is the difference between an agent that declares something finished and one that cannot.

4. **Scope is written down, including what is out.** Section 13 has an explicit cut list and a numbered build order where each step ends with a run in Xogot, a screenshot check and a commit. Two things are reserved on purpose for the live session that follows the build: one new enemy behaviour and one new weapon. Section 14 lists every asset the design needs that the pack does not contain, and what to do instead (audio synthesised by a script, effects and HUD drawn in code, container colours through material overrides).

5. **The document is versioned after each round of play, it is never rewritten.** The first build is one prompt: *create the game, follow @docs/GDD.md*. After playing that build, changes are written as a new section that supersedes the earlier ones, and the agent is pointed at the new section:
   - **1.0** the pre build specification (sections 0 to 15).
   - TBD, filled after the build.

6. **Iterate with screenshots, not descriptions.** The concept image is the acceptance test for the look, judged in a fixed check order (camera height and horizon, distance and FOV, subject position, silhouettes, props, sky, ground, sun, fog, glow, grade, UI), fixing only the first failing item each time. The agent takes its own screenshots and runs the game through `xo`, so it checks its own work before reporting back.

The commit history of this repo follows the build order in section 13.2 one step per commit, so `git log` reads as the build diary.

## Layout

| Path | What it is |
|---|---|
| `docs/GDD.md`, `docs/GDD.pdf` | the game design document, all versions in one file |
| `docs/asset-inventory.md` | every model in the pack with its `res://` path and measured size |
| `docs/concept/concept.png` | the approved concept image, the acceptance test for the look |
| `docs/evidence/` | the concept comparisons and the run screenshots produced during the build |
| `scenes/` | every scene, created in the Xogot editor (`actors/`, `weapons/`, `fx/`, `ui/`) |
| `scripts/` | GDScript, one script per scene plus the `autoload/` singletons (`Game`, `Audio`) |
| `tests/` | the `test_*.gd` suites run by `xo test run` |
| `tools/` | the audio synthesiser and the comparison image script |
| `assets/Toon Shooter Game Kit - Dec 2022/` | Quaternius pack, untouched |
| `assets/audio/` | the SFX and music loops synthesised by `tools/gen_audio.py` |
| `.claude/skills/xogot/` | the `xo` skill Xogot installs for external agents |

At the time of the first commit only `docs/`, `assets/Toon Shooter Game Kit - Dec 2022/` and `.claude/` exist: the project holds the pack, the design document and nothing else, zero scenes, zero scripts. The other folders appear during the build.

## License

The project is released under the **MIT License** (see [`LICENSE`](LICENSE)). The `assets/` folder includes third party content that ships under its own license: the Quaternius Toon Shooter Game Kit is **CC0 1.0**. It keeps its license file inside its folder, and [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) lists it.

## Credits

- 3D art: [Toon Shooter Game Kit](https://quaternius.com/packs/toonshootergamekit.html) by Quaternius (CC0).
- Editor: [Xogot for Mac](https://xogot.com/mac).
- Build: TBD, filled after the build; design document with Claude Opus.
- Produced by [Letta Corporation](https://lettacorporation.com).
