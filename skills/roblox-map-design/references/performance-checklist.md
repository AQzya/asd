# Performance checklist for Roblox maps

Treat these as guidelines, not hard limits. Always measure in Studio on the phone
emulator and, if possible, on a real low-end phone.

## Targets

- Aim for 60 FPS on mid-range phones, 30+ on low-end.
- Keep part counts low in view at once: a few thousand visible parts is comfortable on
  mobile; tens of thousands needs streaming and careful culling.
- Fewer, larger parts beat many small ones. Merge decoration where you can.

## Checklist

1. **StreamingEnabled** (Workspace): turn on for big maps. Set `StreamingMinRadius`
   and `StreamingTargetRadius` so players never see pop-in in the main path.
   Mark models that must always exist (spawn, gameplay) with `ModelStreamingMode = Persistent`.
2. **Anchor everything static.** Unanchored parts cost physics time.
3. **CanCollide / CanTouch / CanQuery off** on decoration (grass, small rocks, signs).
4. **CollisionFidelity:** use `Box` or `Hull` for most MeshParts. `PreciseConvexDecomposition`
   only where needed, since it is expensive.
5. **RenderFidelity:** use `Automatic` or lower detail for far or small meshes.
6. **Textures and decals:** small resolutions, reuse the same textures across parts.
7. **Lights:** limit PointLight/SpotLight count and range. Prefer baked-looking
   emissive materials for glow plus Bloom. Avoid many shadow-casting lights.
8. **Particles and beams:** cap rate and lifetime, disable when far from the player.
9. **Transparency and overlapping glass:** costly in bulk. Use sparingly.
10. **Unions:** can bloat memory. Prefer MeshParts built in Blender for complex shapes.
11. **Terrain:** water and very large detailed terrain cost more. Keep voxel-heavy
    regions only where visible.
12. **Scripts:** no `while true do wait()` loops on many objects. Use events, tags
    (`CollectionService`), and `RunService` sparingly. Avoid touching hundreds of
    parts every frame.
13. **Anti-lag spawn:** do not generate the whole map in one frame at runtime; spread
    work with `task.wait()` or generate in Edit mode and save.
14. **Test on mobile emulator** (Test tab > Device) and watch frame time.

## Tools

- **MicroProfiler** (Ctrl+F6) to see where frame time goes.
- **Stats** overlay (Shift+F3) for memory, draw calls, and physics.
- **Developer Console** (F9) for memory by category and script activity.
- **Output window** for errors and warnings.

## Quick wins when a map is laggy

1. Turn on StreamingEnabled.
2. Switch decoration collision off and meshes to Box/Hull.
3. Reduce light count and particle emitters.
4. Merge or delete tiny parts the player never sees.
5. Lower `Lighting.Technology` ambitions on mobile-heavy games (ShadowMap is lighter
   than Future).
