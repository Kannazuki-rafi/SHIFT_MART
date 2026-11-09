# Test matrix

Build: shift-mart-m0.1-godot4.7.2 · 6 November 2026 · Windows x64.

| Test | Evidence/status |
|---|---|
| Script import/startup | PASS, Godot 4.7.2 |
| Five separate ENet processes | PASS, one host plus four clients, loopback |
| Input and snapshot replication | PASS, five clients/carts including host observed movement |
| Rematch | PASS, second session loaded on all five processes |
| Snapshot MTU | PASS, packed five-cart snapshot below 1200 bytes |
| Client departure | PASS, host roster reduced and race continued |
| Armor overflow and damage protection | PASS, automated state test |
| Five-second repair | PASS, cannot finish at tick 499; finishes at 500 for start 200 |
| Repair in place and recovery anchor | PASS, distinct behavior and no armor farming |
| Wrong-way / skipped checkpoint | PASS, no progress awarded |
| Three laps / finish grace / ties | PASS, ordered crossings and stable peer ID |
| Windows export | PASS, official release template, embedded PCK |
| Windows UI render | PASS, actual GPU screenshot |
| Fresh extracted Windows build | PASS, standalone EXE renders a solo circuit without editor |
| Five freshly extracted release processes | PASS, host + four clients, replicated movement and second-session rematch |
| Mismatched client version | PASS, exported runtime rejects and returns to menu |
| Host departure | PASS, exported client displays host-disconnected reason and clears session |
| Different homes | NOT RUN — M0 acceptance blocker |
| Five human players | NOT RUN |
| Real 100–200 ms latency/loss | NOT RUN |
| Target laptop 30 FPS | NOT RUN |
| Route shifting / item tests | NOT RUN — feature not implemented |
| Final audio/assets | NOT RUN — feature not implemented |

## Human cross-home test

1. Give both testers the same extracted Windows ZIP; record build version above.
2. Record date, player count, host hardware and connection method. Do not publish
   private/public IP addresses in source control or screenshots.
3. Host creates lobby with port 24567; apply required UDP firewall/forwarding manually.
4. Remote tester enters public host address and 24567. Confirm roster on both displays.
5. Add a third tester for normal start (or use `--debug-small-lobby` on the host for
   explicit two-person connectivity debugging). Ready all players, start, drive.
6. Compare positions/health, collide, finish or use the five-minute deadline, rematch.
7. Client leaves; reconnect in the next lobby. Host closes: remote should return to menu.
8. Record PASS/FAIL, latency feel, connection method, and any CGNAT restrictions.

Do not label a LAN/loopback test as a different-home test. If unreachable, record the
failure and investigate the network; no silent VPN/relay dependency is authorized.
