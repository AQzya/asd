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

## Build layers

| # | Layer | Script | Status |
|---|---|---|---|
| 1 | Terrain, oasis, palms, campfire, spawn, night lighting | `tools/01_terrain_oasis.luau` | done |
| 2 | Mud-brick village (modular walls, parapets, arches, doors) | | next |
| 3 | Souq, well and farm, fort | | |
| 4 | Keys, gate, hiding spots | | |
| 5 | Creature AI (sound and light attention, patrols) | | |
| 6 | Audio and jump scares | | |
| 7 | Optimization and playtest | | |
