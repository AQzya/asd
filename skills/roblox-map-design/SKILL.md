---
name: roblox-map-design
description: Use when the user wants to design, plan, build, generate, or polish a Roblox map, level, or world (obby, tycoon, simulator, horror, open world, arena, lobby). Covers layout planning, scale rules, Luau generator scripts for terrain, props, lighting and checkpoints, performance budgets, and a Rojo + GitHub workflow.
---

# Roblox Map Design

Help the user design and build Roblox maps. Claude cannot click inside Roblox Studio,
so the leverage is: (1) a strong design plan, (2) Luau scripts the user pastes into the
Studio command bar or a Script, and (3) file-based Rojo workflow through GitHub.

Reply in the user's language and dialect (Arabic in, Arabic out). Keep Luau code,
property names and Roblox terms in English.

## Workflow

1. **Get the brief (ask only what is missing, max 4 questions).**
   - Genre: obby, tycoon, simulator, horror, open world, FPS arena, lobby, other
   - Theme and mood: e.g. candy, ancient ruins, sci-fi, snowy village, backrooms
   - Scale and players: map size, players per server, mobile support yes/no
   - What exists already: empty baseplate, existing models, a GitHub repo
2. **Write the map plan before any code** (see "Plan template"). Get a quick yes.
3. **Build in layers**, one script per layer, so each is easy to test and undo:
   terrain, then structures/landmarks, then props, then lighting/atmosphere,
   then gameplay (spawns, checkpoints, triggers), then audio, then optimization.
4. **Deliver scripts as files** in the repo under `src/` or `tools/` when a repo is
   attached; otherwise as code blocks. Never paste a giant 500-line script. Split it.
5. **Finish with a test checklist** the user can run in Studio (see "Playtest").

## Plan template

```
Map: <name>            Genre: <genre>           Theme: <theme>
Size: <X x Z studs>    Players: <n>             Platform: PC + mobile
Core loop: <what the player does every 30 seconds>
Zones (3-6): name, purpose, mood, approx size, landmark, difficulty/pace
Flow: spawn -> zone A -> zone B -> ... (draw it as an ASCII map)
Landmarks: tall visible things that orient the player
Palette: 3 main colors + 1 accent + materials
Performance budget: part count target, lights, particles
```

Always include an ASCII top-down sketch of the flow so the user sees the shape.

## Scale rules (studs)

Use these so the map "feels" right. Defaults for R15 characters:

| Thing | Value |
|---|---|
| Character height | about 5 studs |
| Default WalkSpeed | 16 |
| Default jump height | about 7.2 studs (JumpPower 50) |
| Doorway | 7 wide x 10 tall minimum |
| Corridor | 10 wide minimum, 14+ for combat |
| Stair step | 1 stud tall max, ramps under 45 degrees |
| Obby gap | keep jumps under about 70% of max distance for fair difficulty |
| Terrain voxel | 4 studs, so features smaller than 4 studs will not read in terrain |

Make doors, ceilings and props slightly oversized. Realistic scale feels cramped in Roblox.

## Design principles

- **Landmarks and sightlines:** one tall, unique silhouette per zone, visible from the
  previous zone, so players always know where to go.
- **Shape language:** pick one per zone (round and soft = friendly, sharp and angular =
  hostile, blocky = classic Roblox). Do not mix inside a zone.
- **Pacing:** alternate tension and rest. After every hard section, give a safe area
  with a checkpoint, a view, or a reward.
- **Guide with light, color and paths,** not arrows. The brightest, most saturated
  spot pulls the eye.
- **Vertical layers:** ground, mid, high. Gives variety and room for shortcuts.
- **Breadcrumbs:** small props, trails, or lights that lead to the next objective.
- **Clutter with purpose:** props should tell a story and never block the main path.
- **Readability first:** gameplay-critical parts (platforms, hazards, buttons) must have
  clearly different color and material from decoration.

Genre-specific notes are in `references/genre-templates.md`.

## Building rules (always follow)

- Name and group everything: `Workspace/Map/Zones/<Zone>/{Terrain,Structures,Props,Gameplay}`.
- Anchor all map parts. Set `CanCollide`, `CanTouch`, `CanQuery` to false on pure decoration.
- Use `CollectionService` tags for gameplay objects (`Checkpoint`, `KillBrick`,
  `Collectible`) instead of scanning by name.
- Generated content goes inside one Folder per run so it can be deleted and rerun:
  `local folder = Instance.new("Folder"); folder.Name = "Gen_Props"`.
- Scripts must be idempotent: destroy the old Folder before regenerating.
- Use a fixed `seed` so a generated map is reproducible. Tell the user which seed to change.
- Yield in long loops (`task.wait()` every few hundred operations) so Studio does not freeze.
- Prefer MeshParts and unions only when needed; mind `CollisionFidelity` (see performance).

## Script library

Ready-to-adapt Luau is in `references/luau-snippets.md`:
terrain hills with noise, flat arena, water, prop scatter with raycast, lighting and
atmosphere presets, checkpoint system, kill brick, and a cleanup helper.
Copy, adapt to the user's numbers, and explain what to tweak.

## Performance

Budgets, StreamingEnabled guidance and the optimization checklist are in
`references/performance-checklist.md`. Run through it before calling a map done,
and always consider mobile players.

## Rojo + GitHub workflow

When the user has a repo attached, set up a file-based project so Claude can edit
scripts directly and the user syncs them into Studio with Rojo.
Layout and `default.project.json` are in `references/rojo-workflow.md`.
Important limits: Rojo syncs scripts and instances defined as files; hand-built
terrain and large meshes live in the `.rbxl` place file, not in Git.

## Playtest checklist (give this at the end of every build)

1. Press Play (not Run) and walk from spawn to the end of the intended path.
2. Test on the Studio device emulator (phone) for UI and performance.
3. Try to break it: jump out of bounds, skip checkpoints, push against edges.
4. Check the output window for errors and warnings.
5. Check MicroProfiler or the Performance stats for frame time spikes.
6. Ask a friend to play with no instructions and watch where they get lost.

## Honest limits

- Claude cannot open Studio, see the viewport, or place things live. It writes the
  scripts and the plan; the user runs them and reports back (screenshots help a lot).
- Lighting `Technology` is chosen in the Lighting properties panel in Studio.
- Verify API details in the official Roblox Creator docs when something errors,
  since the engine changes over time.
