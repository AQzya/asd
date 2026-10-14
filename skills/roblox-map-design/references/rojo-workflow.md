# Rojo + GitHub workflow

Rojo is a tool that syncs files on disk into Roblox Studio. With the project in a
GitHub repo, Claude can edit scripts as normal files and the user syncs them live.

## One-time setup (the user does this on their PC)

1. Install the Rojo plugin in Studio and the Rojo CLI (rokit/aftman/cargo, or the VS Code
   Rojo extension, which installs it).
2. Clone the repo, open the folder, then run `rojo serve` in the project folder.
3. In Studio, open the Rojo plugin and press Connect.

## Suggested repo layout

```
default.project.json
src/
  server/     -> ServerScriptService/Server
  client/     -> StarterPlayerScripts/Client
  shared/     -> ReplicatedStorage/Shared
tools/        -> command bar scripts (not synced; paste into Studio)
docs/         -> map plan, zone notes, screenshots
```

## default.project.json

```json
{
  "name": "MyRobloxMap",
  "tree": {
    "$className": "DataModel",
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "Server": { "$path": "src/server" }
    },
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Shared": { "$path": "src/shared" }
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "Client": { "$path": "src/client" }
      }
    }
  }
}
```

## File naming

- `Name.server.luau` becomes a Script (server).
- `Name.client.luau` becomes a LocalScript.
- `Name.luau` becomes a ModuleScript.
- A folder with `init.luau` becomes a ModuleScript with children.

(`.lua` also works; `.luau` is the modern extension.)

## How Claude should work in the repo

1. Read the repo structure first and follow its conventions.
2. Make changes on a branch, not directly on `main`, and open a pull request when done.
3. Keep one concern per commit (e.g. "Add checkpoint system").
4. Put the map plan in `docs/MAP_PLAN.md` and update it as zones are completed.
5. Put one-off generators (terrain, scatter) in `tools/` with a comment at the top
   saying how to run them.

## What does not live in Git

Hand-built terrain, large MeshParts and models stay in the `.rbxl` / `.rbxlx` place
file (or published to Roblox). Keep generated content reproducible with seeds in
`tools/` scripts, and store the place file with Roblox's version history or a
separate backup.
