# Work log — 9 November 2026

Project: SHIFT_MART_3D. Reference: SHIFT_MART_GDD.md. Engine tested: Godot 4.6.3.
Protocol: shift-mart-circuit-v2. Source changes are saved in this workspace;
previously exported EXE/ZIP files have not been rebuilt. No Git repository exists
here, so this save is a filesystem record, not a Git commit.

## Course and GDD corrections

Rebuilt the cluttered course as a compact supermarket loop with Produce, Freezer
and Checkout fork pairs. Blue/Orange entrance gates share a 1.5-second warning and
six-second shift cooldown. Only the instigator changes Grip/Rush gear. Occupied
entrances wait until clear; exits stay open. Floor arrows follow both lanes and
approach arrows indicate the open entrance. HUD names the next checkpoint.

Directional checkpoints align with lanes. Finish art and the lap detector share
the same coordinates. Segment/plane crossing checks count three ordered laps,
reject reversing/skips, and preserve the actual lane for checkpoint respawn.
NOS/rockets were replaced by banana peels/canned drinks. All six pickup pads are
pass-through with eight-second refill. There is one marked fixed slippery patch,
one durability bar, three-second respawn, 1.5-second protection, and 2–4 players.

## Solo Debug Drive correction

Reproduced an error from freeing a menu button while its pressed signal was
emitting. Button callbacks now use CONNECT_DEFERRED. The Solo button calls
Session.start_solo() using OfflineMultiplayerPeer; it no longer binds a UDP port.
The player name is copied before screen transitions free the input controls.
Offline load/start/ready/rematch paths work locally. Leaving Solo clears solo_mode
and restores the normal two-player network lobby minimum.

## Verification already run

- tests/state_test.tscn: 50 checks passed, zero failures. Physical trolley collider
  traversed three laps on each layout and every pickup pad. Shift/gate safety,
  item effects/refill, respawn, lap crossings and state replication were covered.
- tests/solo_test.tscn: 12 checks passed, zero failures. Used the actual Solo menu
  button while UDP 24567 was occupied; verified countdown, real acceleration,
  shifting, rematch, leaving, normal hosting and reopening Solo.
- tests/run_multiplayer.ps1: four independent ENet processes passed movement,
  authoritative layout/gear snapshots and clean rematch after the Solo fix.
- Latest multiplayer log directory:
  C:/Users/LENOVO/AppData/Local/Temp/shift-mart-test-053f5274ced7456cb9e264c38fcf5ac3
- Local evidence: tests/state-run.log, tests/solo-run.log, tests/race-preview.png.

## Persistence check

Existing Graphify graph/report/HTML were found; they described the older NOS and
rocket version. Earlier graph artifacts are archived in graphify-out/2026-11-09/.
The refreshed graph uses current source definitions and reviewed relationships;
the installed Graphify AST updater does not support GDScript. Regeneration script:
graphify-out/refresh_source_graph.py. Graphify generates the clustered report/HTML.

Claude-Mem database was found and read in read-only mode. Existing SHIFT_MART_3D
observations #1 and #2 describe the older course and pickups. The running local
worker was located from worker.pid and its health endpoint responded HTTP 200.
The new durable note is submitted via its documented /api/memory/save endpoint.
The request and receipt are saved alongside this log for verification.

## Remaining work

Human playtesting for readability, handling, branch balance and the 3–5 minute
match target. Gate sliding animation, audio/lap scanner beep, final art, persistent
settings and detailed ram-direction balance remain pending. No export, public
publish, internet/NAT test or target-hardware performance claim was made.

## Save confirmation

Claude-Mem observation #3 was saved successfully (HTTP 200) and verified by
reading the matching project/title row from the database. Request:
docs/claude-mem-save-request.json. Receipt: docs/claude-mem-save-receipt.json.
Graphify graph/report/HTML were regenerated: 144 nodes, 315 edges, 10 communities.
A Graphify save-result handoff was also persisted under graphify-out/memory/.
