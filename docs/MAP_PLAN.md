# الديرة المهجورة (The Abandoned Hamlet)

Saudi heritage survival horror for Roblox, 1 to 4 players, PC and mobile.

## Brief

- **Genre:** co-op survival horror
- **Theme:** an abandoned Najdi mud-brick village at night, desert oasis, old souq, old well, fort
- **Creature:** أم الدويس, a Gulf folk-tale figure. Gameplay behavior is a design choice, not a faithful retelling
- **Size:** about 600 x 600 studs
- **Core loop:** collect 5 keys around the village, avoid the creature, open the fort gate
- **Rule:** no mosques or religious symbols as horror elements

## Palette

Sand and mud brown, night teal-blue sky, warm amber lantern accent.
Materials: Sandstone, Concrete, WoodPlanks.

## Zones (north = -Z)

1. **Oasis** (south, spawn): palms, pond, campfire safe zone
2. **Mud alleys** (center): narrow Najdi-style alleys, broken sightlines
3. **Old souq** (west): palm-frond roofs, hanging lanterns, broken stalls
4. **Well and farm** (east): palm farm, aflaj channel, old well, key puzzle
5. **Fort and watchtower** (north): finale and last chase

```
        [5 Fort]
           |
 [3 Souq]--+--[4 Well/Farm]
           |
      [2 Mud alleys]
           |
       [1 Oasis]  <- spawn
```

## Player mechanics

- **Sprint:** hold Left Shift, up to 23 seconds of running, thin stamina line at the bottom of the screen, then exhaustion until recovered. Phone gets an on-screen RUN button.
- **Flashlight:** dim beam, toggle with F (button on phones). The creature notices a lit flashlight from much farther away.
- **Safe zone:** nobody within 38 studs of the campfire can be targeted by the creature.

## Run order in Roblox Studio (Command Bar, Edit mode)

| Step | Script | What it does |
|---|---|---|
| 1 | `tools/01_terrain_oasis.luau` | Terrain, oasis pond, palms, campfire, spawn, night lighting (clears all terrain) |
| 2 | `tools/02_player_systems.luau` | Sprint with stamina bar, flashlight tool (F) |
| 3 | `tools/03_village.luau` | The mud-brick village: about 18 houses, alleys, rubble |
| 4 | `tools/04_creature_umm_al_duwais.luau` | The creature and her AI (appears when you press Play) |

Always run step 1 before step 3. Steps 2 to 4 can be rerun safely.

## Build layers

| # | Layer | Status |
|---|---|---|
| 1 | Terrain, oasis, palms, campfire, spawn, night lighting | done |
| 2 | Sprint and flashlight | done |
| 3 | Mud-brick village | done (first version) |
| 4 | Creature walking AI | done (first version) |
| 5 | Old souq, well and farm, fort | next |
| 6 | Keys, gate, hiding spots | |
| 7 | Audio and jump scares | |
| 8 | Optimization and playtest | |
