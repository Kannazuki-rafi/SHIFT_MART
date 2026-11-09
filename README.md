# SHIFT MART — editable 3D prototype

Godot **4.6.3 standard**, GDScript, Compatibility renderer. Open `project.godot`
and press F5. Use **SOLO DEBUG DRIVE** for local testing, or host a LAN lobby
with 2–4 ready players. Default UDP port: **24567**.

Source was updated on 9 November 2026. Any previously exported executable/ZIP
must be rebuilt to include these changes.

## Controls

| Input | Action |
|---|---|
| W / Up | Accelerate |
| S / Down | Brake, then reverse |
| A / D, Left / Right | Steer |
| E | Switch personal Grip/Rush gear and toggle the shared Blue/Orange route |
| Space | Drop banana peel or fire canned drink |
| Hold R for 2 seconds | Reset to the last checkpoint after a three-second penalty |
| Esc | Local menu; multiplayer keeps running |

Follow the floor arrows around checkout, produce, freezer and stockroom. Three
forks rejoin the same ordered checkpoint sequence. The approach arrows point to
the currently open entrance. Gate labels show route identity and OPEN/CLOSED;
during a shift they show OPENING/CLOSING. A 1.5-second warning precedes the
change, then all players share a six-second cooldown. Occupied entrances wait
until clear. Branch exits always stay open.

Pass every checkpoint in order, then cross the checkered checkout line to add a
lap. The finish artwork and detector use the same position. Three laps finish the
race; the first finisher starts a 20-second grace period. Hard limit: five minutes.
HUD guidance identifies the next checkpoint and direction. Unfinished racers rank
by lap, checkpoint and segment progress. The host can return to the lobby for a
clean rematch.

Marked pads have no physical pedestal: drive through to collect a known item
when the inventory is empty. Pickups refill after eight seconds. Banana peels
briefly reduce grip/speed and expire after eight seconds; cans fly straight,
deal 15 damage and expire on first collision or after four seconds.

There is one durability bar. Destroyed carts return to the last passed checkpoint
with full durability after three seconds. Spawn protection lasts 1.5 seconds and
blocks outgoing damage/items. There is one marked fixed slippery patch.

## Multiplayer

Use `127.0.0.1` for processes on the same PC, or the host PC's LAN address for
other PCs on that network. Direct IP/ENet has no relay, matchmaking or automatic
NAT traversal. Cross-home internet play has not been verified. Host departure
closes the session; no host migration or mid-race reconnect is implemented.

The host decides movement, damage, shifts, occupied-gate delays, checkpoints,
items and results. Movement inputs use channel 1, snapshots channel 2, and reliable
lobby/loading/shift messages channel 0. Snapshot data includes actual gate closure
states, personal gear, item visuals and pickup cooldowns. Clients interpolate carts.
Protocol `shift-mart-circuit-v2` rejects older builds.

## Tests

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --log-file tests/state-run.log --fixed-fps 60 res://tests/state_test.tscn
godot --headless --path . --log-file tests/solo-run.log --fixed-fps 60 res://tests/solo_test.tscn
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_multiplayer.ps1 -Godot 'D:\codingan\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

The state suite exercises physical collider traversal through both layouts and
all pickup pads, ordered laps, crossing edge cases, shift timing/safety, item
collection, respawn and replication. The integration runner launches four ENet
processes and checks movement, shared layout/gear replication and a rematch.
These are automated local tests; human driving and network latency still need
playtesting. The current prototype has no audio or final art, and lap duration
and relative branch travel times have not been balanced to the GDD's 3–5 minute
target. See `docs/PROGRESS.md` for verification details.
