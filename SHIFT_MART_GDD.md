# SHIFT MART

## Game design document and jam production plan

**Version 1.0 — 5 November 2026**  
**Status:** Proposed design. Prototype the driving and shifting before locking the tuning values.  
**Working title:** SHIFT MART

Night shift supermarket employees race modified motorized shopping trolleys through the closed store. Ram friends, wreck their carts, and reach checkout first. Every successful gear shift changes the shared racing route, creating opportunities to help yourself and sabotage somebody else.

This is a **2–4 player competitive party racer** with the social chaos associated with friendslop games. Each player controls one trolley. A separate cooperative mode is outside this plan.

## 1 The game we are building

| Decision | Jam scope |
|---|---|
| Platform | PC, keyboard controls |
| Players | 2–4 human players; solo mode only for development testing |
| Match | Three laps; target 3–5 minutes; five minute hard limit |
| Environment | One compact supermarket circuit |
| Main mechanic | Two personal gears; accepted shifts toggle two shared track layouts |
| Sabotage | Ramming plus two supermarket items |
| Trolley damage | One durability bar; temporary destruction and respawn |
| Visual style | Low-poly models, flat materials, readable colors |
| Multiplayer baseline | One player hosts; others join over LAN |
| Internet play | Include only if an existing networking template already supports it; no custom lobby or relay project |
| Progression | One race, results, immediate rematch |

The jam duration, team size, and networking experience are unknown. Work follows ordered milestones rather than an invented daily schedule. Do not promise join-from-anywhere online play from a LAN build.

### Design pillars

- **Understand the mess.** Players can identify who changed the route, what hit them, and where they can drive next.
- **Attack while racing.** Sabotage helps you finish first; it does not replace the race objective.
- **Recover quickly.** A broken trolley creates a funny setback, followed by another chance to play.
- **Reuse a small space.** Player collisions and route changes create variety inside one authored supermarket.

## 2 Fantasy and match flow

The store is closed. The night crew has fitted questionable motors to shopping trolleys and turned checkout into a finish line. The setup needs one sign or short announcement, not a story sequence.

**Flow:** host/join → ready up → three second countdown → race and sabotage → finish order → rematch.

First to complete three valid laps wins. Ordered checkpoints at the branch rejoins prevent shortcutting or reversing across the finish to gain laps. All route variants pass through the same checkpoint sequence.

When the first racer finishes, a 20 second countdown begins. The race ends when everybody finishes, the countdown expires, or the five minute hard limit is reached. Finished players follow an unfinished racer and cannot attack. Finished players rank by finish time; unfinished players rank by completed laps, checkpoints, then progress along their valid branch.

There is no elimination, damage score, or bonus points for bullying one player. The results screen needs finish order and one Rematch button.

## 3 Driving and controls

Players remain attached to their trolleys. Characters lean and wobble visually; they do not walk, jump, or ragdoll as separate physical bodies.

| Input | Action |
|---|---|
| W | Accelerate |
| A / D | Steer |
| S | Brake; reverse when nearly stopped |
| E | Request a gear shift |
| Space | Use the held item |
| Hold R | Reset to the last passed checkpoint with the normal respawn penalty |
| Esc | Local settings or exit; does not pause a multiplayer race |

The trolley should accelerate quickly, slide enough for funny collisions, and remain easy to recover. Braking must always work, including while gear shifting is unavailable. Use a simple arcade vehicle controller; four independently simulated wheels and realistic suspension are unnecessary.

| Gear | Driving behavior | Best use |
|---|---|---|
| 1 — Grip | Lower top speed, tighter steering, stronger grip | Tight corners, recovering from a hit, setting up a controlled ram |
| 2 — Rush | Higher top speed, wider turns, more slide | Straights, overtaking, harder impacts |

Start everyone in Grip. A first tuning target is Grip at roughly 80% of Rush top speed. Both gears remain usable throughout the map; a bad gear choice should cost time rather than make a section impossible. There is no separate drift button, boost meter, or gear minigame.

## 4 The defining mechanic

### A personal gear shift changes the shared supermarket

Each player has their own gear. The supermarket has one shared route state: **Blue layout** or **Orange layout**. Every accepted upshift or downshift toggles that shared state.

Only the initiating player's gear changes. Everyone sees the route change.

**Example:** You are in Grip on a straight. You press E. After the warning, your trolley enters Rush and the supermarket switches from Blue to Orange. A rival loses access to the shortcut they were approaching. Later, another racer shifts down; only their trolley enters Grip, while the whole supermarket switches back to Blue.

### Exact shift rules

1. When shifting is available, the first valid E press reserves the next shift. Broken, respawning, and finished racers cannot request one.
2. A 1.5 second warning identifies the instigator and the incoming layout. Gate arrows show which entrances will open or close. Driving continues in the current gear during the warning.
3. At the end of the warning, the initiating trolley changes gear and the shared layout toggles. The scheduled layout change still happens if that trolley crashes during the warning; it does not cancel the event.
4. Shifting is then unavailable to everybody for six seconds. Steering, braking, acceleration, attacks, and items remain available.
5. E presses during the warning or cooldown do nothing and show “Shift busy.” Requests are never queued, and holding E does not repeatedly activate it.

This uses one shared cooldown rather than several currencies or voting rules. The cooldown is visible to all racers. It limits layout spam, although players can still compete to trigger the next change. Six seconds is a starting value to playtest, not a final balance claim.

### What physically changes

The floor and overall circuit stay in place. Three fork junctions each have two prebuilt branches. Sliding entrance gates select the active branch; both branches rejoin the same checkpoint. Blue and Orange are two authored combinations of these gates.

- Every accepted shift changes the gates at all three junctions.
- A racer already inside a branch can finish it; that branch's exit never closes.
- A gate never sweeps through a trolley. If its entrance safety area is occupied, that gate waits until clear, keeping its warning light on. Other gates change normally.
- A shift never creates a dead end, removes the floor, or forces a checkpoint skip.
- Layout colors identify routes, not safe versus dangerous options. Both layouts contain useful opportunities and awkward corners.

The visual payoff is a supermarket visibly rearranging its access routes. Do not procedurally rebuild the map or maintain separate worlds for each player.

## 5 Sabotage and trolley destruction

### Ramming

Ramming is always available and requires no attack button. A meaningful relative-speed impact causes durability damage and a short shove. Gentle contact causes pushing, not repeated damage.

- A strong rear or side hit primarily damages the recipient.
- A head-on collision damages both racers.
- A hard collision with a fixed wall also damages the driver.
- After taking damage, a trolley has one second of damage protection so sustained contact cannot drain the entire bar.
- Hits can briefly disturb steering but never create a long stun or reverse the controls.

The joke comes from recognizable driving mistakes and deliberate attacks. Random steering failures would make the trolley feel unresponsive.

### One damage system

Every trolley has 100 durability. Below 35, a bent wheel and rattling sound communicate damage, with a maximum 10% top-speed penalty. Steering remains reliable. Individual wheels, axles, engines, and gearboxes do not have separate health.

At zero durability, the trolley folds with a short visual effect. After three seconds, the racer respawns at the last passed checkpoint with full durability. Lap and checkpoint progress remain; respawning never advances them. Brief spawn protection prevents immediate repeat destruction, and a protected racer cannot damage others.

Manual reset uses the same penalty and never repairs the cart instantly in place. There are no repair stations or permanent eliminations. Damage should matter through lost time without making a damaged player helpless.

### Two items only

One inventory slot. Marked stands provide a known item; driving through collects it if the slot is empty. Stands refill after roughly eight seconds. There is no randomized rarity, aiming mode, or inventory menu.

| Item | Use | Effect | Counterplay |
|---|---|---|---|
| Banana peel | Drop behind the trolley | The next trolley hitting it briefly loses grip and speed; no direct damage | Visible peel, steering around it, slowing before contact |
| Canned drink | Fire straight ahead | A short-lived projectile deals a small fixed amount of durability damage and a shove | Misses are possible; dodge or use a different lane |

A peel disappears on contact or after eight seconds. A can disappears on its first collision or after four seconds. Both can hit their owner after deployment, so careless placement is a risk. Spawn protection blocks their harmful effects. No bouncing, homing, chain reactions, or product combinations.

## 6 One supermarket track

The course loops through checkout, produce, a freezer aisle, and the edge of the stockroom. Most of the width allows two trolleys side by side. Narrow sections are short and have room to escape afterward.

| Junction | Blue branch | Orange branch | Gameplay purpose |
|---|---|---|---|
| Produce | Short pallet chicane | Longer, wider arc | Grip saves distance; Rush carries speed |
| Freezer | Wide curve with a fixed slippery patch | Narrow dry passage | Risky speed versus controlled handling |
| Checkout | Tight direct checkout lane | Wide outside loop | Short route versus passing and ramming space |

Each fork needs an approach long enough to read the shift warning and brake. No layout should be consistently the fastest for all situations. Branches need only be close enough in travel time to make choices interesting, not perfectly identical.

**Environmental hazard cap:** fixed walls, pallets, and one marked slippery patch. Shelved products are static decoration; hundreds of individually simulated groceries are outside scope.

**Example race moment:** A player approaches the tight checkout shortcut. Their friend shifts into Rush, opening the outside loop instead. The first player brakes and gets rear-ended by a third racer. They recover, drop a banana, and later shift down to redirect the next pack of trolleys. Every reversal comes from a visible player action.

## 7 Camera and feedback

A third-person chase camera shows the trolley, nearby opponents, and the next junction. Use a stable follow camera with mild speed-based pullback. Avoid mandatory mouse aiming. Keep shelves low enough, or camera collision simple enough, that the view stays useful.

**Minimum HUD:** position, lap, durability, current gear, held item, shared shift availability, and the active layout. During a warning, show “Yogi is shifting — Orange in 1.5s” with a countdown and matching gate lights.

Racer names and colors must remain visible above carts. Color is paired with arrows, labels, or symbols so route changes do not depend only on color recognition.

Sound priorities are wheel squeaks, gear clunks, gate movement, item hits, and trolley collapse. A checkout scanner beep confirms a lap. Optional cosmetic humor includes a deadpan PA announcement and an unpaid-overtime joke on the results receipt. Neither adds a gameplay system.

## 8 Low-poly asset budget

| Asset group | Required set |
|---|---|
| Racers | One trolley mesh with healthy/bent appearance; one simple rider mesh; four color variants |
| Supermarket | Modular floor/walls, shelf, checkout counter, freezer, pallet, sliding gate |
| Decorations and pickups | Three reusable product shapes, banana, canned drink, pickup stand |
| Route readability | Direction arrow, warning light, checkpoint/finish marker |
| Animation | Rider lean, visual wheel spin, gate slide, trolley collapse |
| Audio | A small set covering driving, impacts, items, shift warning, gates, lap, destruction, results |

Reuse colors, product arrangements, and shelf rotations. Start with primitive shapes. Detailed characters, facial animation, destructible shelving, and procedural destruction are unnecessary. A trolley collapsing can be a short animation or a few cosmetic pieces that do not affect the race.

## 9 Scope lock

### Required for the complete jam build

- One trolley controller and one rider appearance with four colors.
- Two personal gears and two shared layouts.
- One circuit, three fork junctions, three laps.
- Ramming, one durability bar, temporary destruction, checkpoint respawn.
- Two items, one inventory slot, fixed pickup stands.
- One hosted 2–4 player session with ready, race, results, and rematch.
- Readable HUD, shift warning, basic sound, and low-poly presentation.

### If time runs short

Cut in this order: cosmetic PA jokes and extra animations; the canned drink; the banana; the third fork junction; the damaged-speed penalty. Ramming still supplies sabotage without items.

The smallest version worth shipping is **2–4 players, one circuit, two changing forks, two gears, ramming, durability/respawn, finish order, and rematch**. Preserve multiplayer, the shared route change, and fast recovery. Those define the game.

### Explicitly outside the jam

No second map, AI racers, security guard AI, horror mode, employee chores, walking, crafting, trolley upgrades, skill tree, shop, matchmaking service, built-in voice chat, full-store procedural generation, or separate cooperative/team mode.

## 10 Extra mechanic brainstorm

This is a parking lot, not an implementation checklist. Add none of these before the complete jam build works. If there is genuine spare time, choose at most one small addition.

| Idea | Decision | Reason |
|---|---|---|
| Look-behind button | First small stretch | Helps plan rear attacks without changing balance systems |
| Cosmetic product bursts on hard hits | Small stretch | Adds impact spectacle if particles or non-colliding pieces stay cheap |
| Friendliest employee or biggest menace result caption | Small stretch | Uses existing hit counts; does not change who wins |
| One rotating shelf replacing a gate | Post-jam | Strong visual payoff, but introduces moving geometry problems |
| Spill bottle creating temporary slippery floor | Post-jam alternative item | Reuses low-grip behavior; replace an item rather than expanding the pool |
| Drafting behind a trolley | Post-jam experiment | Could bring racers together, but needs balancing |
| Drift-to-boost | Exclude from jam | Adds a second driving mastery and resource system |
| Third gear with a third layout | Exclude from jam | Multiplies track design, warnings, and testing |
| Manually repair or steal a trolley | Exclude from jam | Requires on-foot controls and extra interactions |
| Independent broken-wheel steering | Exclude | Removes reliable control from the player already losing |
| Security guard chasing racers | Exclude from jam | Adds navigation, AI, and another threat to explain |
| Blackout or random aisle events | Exclude from jam | Makes it harder to attribute chaos to friends |
| Carry a teammate in the basket | Separate future mode | Changes player roles, camera, and vehicle balance |
| Team shopping delivery objectives | Separate future mode | Creates a different win condition and cooperative game |

## 11 Build order and completion checks

### Milestone 1 Driving feels good

Build one graybox trolley and a small oval. Add accelerate, steer, brake/reverse, two gears, and reset. Completion check: a tester can turn corners deliberately, recover from a slide, and explain the difference between gears.

### Milestone 2 Friends share the same race

Connect two players, then test four. The host decides shared outcomes: shift order, gate state, accepted damage, item collection, checkpoint progress, and results. Completion check: both players see the same collisions and can finish and rematch. Verify the connection method before making art; do not assume LAN support implies internet support.

### Milestone 3 The shift is fun

Build one fork with Blue/Orange gates, warning, cooldown, and safe passage. Test contested shift requests, a trolley overlapping a gate, a racer already inside a branch, and a crash during the warning. Completion check: racers can explain who changed the route and can intentionally help themselves or inconvenience a friend.

### Milestone 4 The full race works

Finish the circuit and remaining forks. Add ordered checkpoints, laps, durability, ramming damage, respawn, finish countdown, and the results screen. Completion check: a full race ends correctly even after crashes, manual resets, and repeated route changes.

### Milestone 5 Sabotage and presentation

Add banana first, canned drink second, then low-poly dressing, readable effects, and sound. Completion check: both item effects are understandable, races stay close enough for interaction, and repeated rematches work.

If ramming and shifting already produce funny decisions, protect that result. Do not compensate for weak core mechanics by adding more items or modes.

## 12 Initial tuning and playtest priorities

All values below are prototype starting points.

| Variable | Starting value |
|---|---|
| Laps | 3 |
| Players | 2–4 |
| Shift warning | 1.5 seconds |
| Shared shift cooldown after a change | 6 seconds |
| Durability | 100 |
| Hard ram damage | Roughly 15–25, depending on impact |
| Canned drink damage | 15 |
| Damage protection after a hit | 1 second |
| Bent trolley threshold | Below 35 durability |
| Maximum damage-related top-speed penalty | 10% |
| Respawn delay | 3 seconds |
| Protection after respawn | 1.5 seconds, with outgoing damage disabled |
| Pickup refill | 8 seconds |
| Finish countdown | 20 seconds |
| Race hard limit | 5 minutes |

**Playtest questions:** Can players predict the next route? Can they name the friend responsible for a shift? Does shifting down sometimes help? Can a damaged racer still participate? Are racers close enough to sabotage? Does repeated claiming of the shared shift become frustrating?

If the field spreads out, first shorten the circuit, reduce damage penalties, and tune the two branches. If shifting is unreadable, reduce to two forks and lengthen the warning. If one gear dominates, change its speed/steering tradeoff before inventing a new mechanic. If the shared cooldown feels bad, prototype a different shift cadence before committing to more systems.

**Definition of done:** Four friends can join the supported connection type, understand the controls, finish a complete race, identify the causes of major setbacks, recover after destruction, and start another race without restarting the game. This is the release gate, not a claim that the game has already been tested.
