# Graph Report - SHIFT_MART_3D  (2026-11-09)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 144 nodes · 315 edges · 10 communities (6 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- scripts/race/race_world.gd
- scripts/net/network_session.gd
- scripts/app.gd
- scripts/race/trolley_controller.gd
- tests/state_test.gd
- solo_test.run_solo

## God Nodes (most connected - your core abstractions)
1. `network_session.leave()` - 14 edges
2. `race_world._physics_process()` - 12 edges
3. `app._main_menu()` - 11 edges
4. `app.label()` - 10 edges
5. `app._lobby()` - 10 edges
6. `app.button()` - 9 edges
7. `solo_test.run_solo()` - 9 edges
8. `state_test.items_and_respawn()` - 9 edges
9. `app._modal()` - 8 edges
10. `app._results()` - 8 edges

## Surprising Connections (you probably didn't know these)
- `state_test.replication()` --calls--> `trolley_controller.state_data()`  [EXTRACTED]
  tests/state_test.gd → scripts/race/trolley_controller.gd
- `solo_test._ready()` --calls--> `network_session.leave()`  [EXTRACTED]
  tests/solo_test.gd → scripts/net/network_session.gd
- `solo_test.run_solo()` --calls--> `network_session.back_to_lobby()`  [EXTRACTED]
  tests/solo_test.gd → scripts/net/network_session.gd
- `solo_test.run_solo()` --calls--> `network_session.can_start()`  [EXTRACTED]
  tests/solo_test.gd → scripts/net/network_session.gd
- `solo_test.run_solo()` --calls--> `network_session.leave()`  [EXTRACTED]
  tests/solo_test.gd → scripts/net/network_session.gd

## Import Cycles
- None detected.

## Communities (10 total, 4 thin omitted)

### Community 0 - "scripts/race/race_world.gd"
Cohesion: 0.09
Nodes (33): app._process(), network_session._snapshot(), C, CHECKPOINT_HALF_WIDTH, COLORS, DIRECTIONS, FORKS, GATES (+25 more)

### Community 1 - "scripts/net/network_session.gd"
Cohesion: 0.11
Nodes (30): app._capture(), app._cli(), app._test_process(), MAX_PLAYERS, VERSION, network_session._accept_input(), network_session._broadcast_roster(), network_session._clean_name() (+22 more)

### Community 2 - "scripts/app.gd"
Cohesion: 0.18
Nodes (25): LIME, PALE, R, app._begin(), app._close_overlay(), app._credits(), app._destroy_world(), app._help() (+17 more)

### Community 3 - "scripts/race/trolley_controller.gd"
Cohesion: 0.16
Nodes (14): network_session.publish_snapshot(), race_world._contact(), race_world._physics_process(), race_world._update_cans(), race_world._update_peels(), TUNING, trolley_controller._ready(), trolley_controller.box() (+6 more)

### Community 4 - "tests/state_test.gd"
Cohesion: 0.25
Nodes (15): race_world._advance_shift(), race_world._checkpoint(), race_world._collect_pickup(), race_world._update_gates(), race_world.setup(), W, state_test._ready(), state_test.check() (+7 more)

### Community 5 - "solo_test.run_solo"
Cohesion: 0.39
Nodes (6): network_session.request_shift(), race_world.request_shift(), solo_test._ready(), solo_test.check(), solo_test.click(), solo_test.run_solo()

## Knowledge Gaps
- **16 isolated node(s):** `R`, `LIME`, `PALE`, `VERSION`, `MAX_PLAYERS` (+11 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 28 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `network_session._load()` connect `scripts/net/network_session.gd` to `scripts/app.gd`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **What connects `R`, `LIME`, `PALE` to the rest of the system?**
  _16 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `scripts/race/race_world.gd` be split into smaller, more focused modules?**
  _Cohesion score 0.08571428571428572 - nodes in this community are weakly interconnected._
- **Why does `app._solo_debug_drive()` connect `scripts/app.gd` to `scripts/net/network_session.gd`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **Should `scripts/net/network_session.gd` be split into smaller, more focused modules?**
  _Cohesion score 0.11229946524064172 - nodes in this community are weakly interconnected._