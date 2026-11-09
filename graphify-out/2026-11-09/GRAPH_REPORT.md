# Graph Report - SHIFT_MART_3D  (2026-11-09)

## Corpus Check
- 23 files · ~20,303 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 42 nodes · 51 edges · 12 communities (6 shown, 6 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 14,500 input · 3,200 output

## Community Hubs (Navigation)
- Script Setup & Environment Tools
- IDE Skill Integrations
- Combat Hazards & Trolley Stun
- Tool Installation Utilities
- Core Gameplay & Simulation
- Multiplayer Network Session
- NOS Boost & Buff Pickups
- HUD & State Snapshots
- Winding Circuit Checkpoints
- Water Puddles & Slip Dynamics
- Game Design & Rules

## God Nodes (most connected - your core abstractions)
1. `Copy-Skill()` - 11 edges
2. `RaceWorld System` - 5 edges
3. `Install-ToolAuto()` - 4 edges
4. `State & Mechanics Test Suite` - 4 edges
5. `Get-GlobalRootForTool()` - 3 edges
6. `Install-ToolGlobal()` - 3 edges
7. `TrolleyController` - 3 edges
8. `Trolley Stun Handler` - 3 edges
9. `NetworkSession ENet Manager` - 3 edges
10. `Get-RelativePathCompat()` - 2 edges

## Surprising Connections (you probably didn't know these)
- `Headless Multiplayer Integration Runner` --references--> `NetworkSession ENet Manager`  [EXTRACTED]
  tests/run_multiplayer.ps1 → scripts/net/network_session.gd
- `RaceWorld System` --references--> `TrolleyTuning Balance Config`  [EXTRACTED]
  scripts/race/race_world.gd → resources/trolley_tuning.gd
- `State & Mechanics Test Suite` --references--> `12-Checkpoint Winding Circuit`  [EXTRACTED]
  tests/state_test.gd → scripts/race/race_world.gd
- `State & Mechanics Test Suite` --references--> `Trolley NOS Boost Handler`  [EXTRACTED]
  tests/state_test.gd → scripts/race/trolley_controller.gd
- `12-Checkpoint Winding Circuit` --implements--> `Winding Circuit Design`  [EXTRACTED]
  scripts/race/race_world.gd → SHIFT_MART_GDD.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Combat Racing Gameplay Loop** — scripts_race_race_world_raceworld, scripts_race_trolley_controller_trolleycontroller, scripts_race_race_world_pickup_stands, scripts_race_race_world_spawn_rocket, scripts_race_trolley_controller_trigger_boost, scripts_race_race_world_contact [EXTRACTED 0.95]
- **Authoritative ENet Snapshot Architecture** — scripts_net_network_session_session, scripts_race_race_world_raceworld, scripts_race_trolley_controller_state_data, scripts_app_app [EXTRACTED 0.95]

## Communities (12 total, 6 thin omitted)

### Community 1 - "IDE Skill Integrations"
Cohesion: 0.29
Nodes (7): Copy-Skill(), Install-Cline(), Install-Copilot(), Install-Cowork(), Install-Cursor(), Install-Windsurf(), Test-IsExcluded()

### Community 2 - "Combat Hazards & Trolley Stun"
Cohesion: 0.33
Nodes (5): Cart Collision & Ramming Physics, Track Obstacles & Inner Barriers, Rocket Projectile Engine, Durability & Armor System, Trolley Stun Handler

### Community 3 - "Tool Installation Utilities"
Cohesion: 0.50
Nodes (4): Get-GlobalRootForTool(), Get-WorkspaceRootForTool(), Install-ToolAuto(), Install-ToolGlobal()

### Community 4 - "Core Gameplay & Simulation"
Cohesion: 0.83
Nodes (4): TrolleyTuning Balance Config, RaceWorld System, TrolleyController, State & Mechanics Test Suite

### Community 5 - "Multiplayer Network Session"
Cohesion: 0.67
Nodes (3): App Master UI & Client, NetworkSession ENet Manager, Headless Multiplayer Integration Runner

### Community 6 - "NOS Boost & Buff Pickups"
Cohesion: 0.67
Nodes (3): Item Pickup Stands, Trolley NOS Boost Handler, Supermarket Buff & Weapon System

## Knowledge Gaps
- **10 isolated node(s):** `SHIFT MART Game Design Document`, `Winding Circuit Design`, `Supermarket Buff & Weapon System`, `Track Obstacles & Inner Barriers`, `Water Hazard Puddles` (+5 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 16 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `RaceWorld System` connect `Core Gameplay & Simulation` to `Multiplayer Network Session`, `HUD & State Snapshots`?**
  _High betweenness centrality (0.060) - this node is a cross-community bridge._
- **What connects `SHIFT MART Game Design Document`, `Winding Circuit Design`, `Supermarket Buff & Weapon System` to the rest of the system?**
  _10 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Why does `State & Mechanics Test Suite` connect `Core Gameplay & Simulation` to `Winding Circuit Checkpoints`, `NOS Boost & Buff Pickups`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **Why does `NetworkSession ENet Manager` connect `Multiplayer Network Session` to `Core Gameplay & Simulation`?**
  _High betweenness centrality (0.028) - this node is a cross-community bridge._