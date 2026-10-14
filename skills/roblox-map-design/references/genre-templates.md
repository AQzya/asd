# Genre templates for Roblox maps

Use these as a starting skeleton. Adapt zones, scale and theme to the user.

## Obby

- Structure: 30 to 100 stages, difficulty curve rising slowly, a checkpoint every 5 to 10 stages.
- Themes per section of 10 stages (lava, ice, neon, candy, space) to keep it fresh.
- Introduce one new mechanic at a time (moving platforms, spinners, disappearing
  floors, conveyors), then combine them later.
- Fairness: every jump must be possible at default WalkSpeed 16 and JumpPower 50.
  Leave visible landing spots, no blind jumps.
- Add skip stage, stage counter, and leaderboard (`leaderstats`).

## Tycoon

- A flat plot per player, 6 to 12 plots arranged in a ring or two rows around a shared center.
- Core loop: dropper -> conveyor -> collector -> cash -> buttons that unlock the next
  machine. Show the next unlock clearly.
- Plot needs: owner claim door, spawn point, wall boundary, button pads with prices.
- Shared center: shop, leaderboard, and social space.
- Keep plots as identical Models cloned from `ServerStorage` so balancing is easy.

## Simulator

- Hub world plus 3 to 6 themed worlds unlocked by progression (each with higher multipliers).
- Zones: spawn hub, upgrade shops, collection areas (clicking, mining, farming),
  sell area, rebirth station, pet/egg area.
- Teleport pads between worlds, each locked by requirement.
- Make the collection area compact so action stays dense; players hate walking.

## Horror

- Narrow corridors, long sightlines broken by corners, one safe room as a hub.
- Lighting: very low ambient, a few strong light sources, fog via Atmosphere.
- Sound does half the work: ambient loops, distant noises, footsteps echo.
- Use doors, vents, and loops so players can run in circles from a threat.
- Keep collision simple for performance, since many small details are visual only.

## Open world / adventure

- Use a central landmark visible from everywhere, biomes around it
  (forest, desert, snow, swamp) with smooth transitions.
- Paths and roads connect points of interest every 100 to 200 studs.
- Enable StreamingEnabled from the start.
- Use terrain for large shapes, models for towns, scatter scripts for vegetation.

## Arena / FPS / PvP

- Symmetric or carefully balanced. Test with bots first.
- Three lanes style: two flanks and a middle, with cover every 10 to 15 studs.
- Spawns far from each other and out of line of sight of enemies.
- Height variety: high ground has risk (exposed), reward (view), and clear access.
- Keep the map small enough that fights happen within seconds of spawning.

## Lobby / hub

- Clear radial layout: center plaza, spokes to game portals or teleporters.
- Large readable signs, strong landmark, social spots (seating, emotes, photo spot).
- Light touch on performance, since many players are present at once.
