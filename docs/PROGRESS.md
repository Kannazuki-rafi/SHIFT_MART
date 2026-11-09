# Progress — 9 November 2026

Current source protocol: `shift-mart-circuit-v2`. Tested engine: Godot 4.6.3.
The earlier executable/export is not updated by these source changes.

## Current work

- Replaced the large, cluttered winding course with an 84 × 68 m supermarket.
  Low shelves, continuous perimeter boundaries, three branch splitters and one
  marked freezer slippery patch replace stacked road closures and five hazards.
- Authored Produce, Freezer and Checkout branch pairs. Entrance gates select
  Blue/Orange; exits stay open. Grip/Rush changes toggle the shared layout after
  a 90-tick warning and start a 360-tick shared cooldown. Only the instigator's
  gear changes. Occupied entrance gates wait until clear.
- Actual arrow silhouettes follow each branch. Approach arrows rotate toward
  the open entrance. Gate text pairs colors with route names and state labels.
  HUD shows gear, route, shift warning/cooldown and next-checkpoint guidance.
- Replaced diagonal checkpoints with directional gates across the driving lanes.
  Finish visuals and lap detection share the same coordinates. Crossing tests use
  the segment/plane intersection. Resets preserve the lane actually driven and
  never count the respawn teleport as forward race progress.
- Replaced NOS/rockets with the GDD banana/can. Pads and floating pickup meshes
  have no collision shapes. Pickup cooldowns and deployed item positions replicate.
- Restored the GDD's 2–4 player lobby, single durability bar, three-second checkpoint
  respawn and 1.5-second spawn protection. Finished racers follow an unfinished cart.

## Verification

- State suite: 50 assertions passed, exit code 0. Includes actual CharacterBody3D
  collider traversal for three complete laps through each layout; all six pickup
  pads; reverse/out-of-bounds/exact-plane/high-speed crossings; shift contention,
  warning/cooldown timing, instigator crash and occupied-gate delay; item use,
  cooldowns, respawn and compact snapshots.
- Four independent local ENet processes passed movement, shared shift/gear
  replication and clean rematch checks. Each process observed Orange/Rush before
  rematching. This tests loopback, not real-world latency or four human drivers.
- Rendered chase-camera preview: `tests/race-preview.png`.
- The environment emits certificate-store and shader-cache warnings. Tests use
  explicit writable log paths to avoid Godot's inaccessible default user log folder.

## Remaining limits

- Human playtesting is needed for handling, route readability, branch balance,
  and the intended 3–5 minute match duration.
- Gates currently toggle collision and visual state; sliding animation is pending.
- Audio (including lap scanner beep), final models, persistent settings and
  detailed ram-direction balancing are pending.
- No public deployment, release export, internet/NAT test or target-hardware
  performance measurement was performed in this revision.

## Solo Debug Drive fix

- Menu button callbacks run deferred, so screen transitions cannot destroy a
  button while it is emitting its pressed signal.
- Solo starts through OfflineMultiplayerPeer without creating an ENet server.
  Leaving Solo clears the solo flag; normal lobbies retain their two-player minimum.
- Solo regression: 12 checks passed, including the actual menu button while port
  24567 is occupied, countdown, real accelerate input, shifting, rematch, normal
  network hosting afterward, and reopening Solo.
