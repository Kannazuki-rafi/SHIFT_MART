# Decisions and assumptions

Source: user-supplied SHIFT_MART_CODEX_PLAN.md, version 1.0, 6 November 2026.
The document is the requested product specification, not proof of tests or approval
for external publication. No project/ancestor AGENTS.md was found in the checked workspace.

## Adopted scope

- New 3D project, Godot 4.7.2 standard, Compatibility, English UI, Windows.
- ENet direct IP, listen-server authority, 3–5 participants; explicit solo debug option.
- No AI, third-party service, VPN or plugin dependency.
- Preserve the phased acceptance gates. M0 cross-home test cannot be certified locally.

## Provisional, not final user approval

- A1–A5: two gears, gear request triggering global A/B route swap, 1.5-second warning,
  six-second cooldown, laps independent of shifts, static route entrances. **Not yet
  implemented**; next prototype is one junction for user evaluation.
- A6–A7: five-second automatic repair, two-second protection, one upgrade slot.
  Only cardboard armor is implemented for evaluation. No choice of three upgrades yet.
- A8: ENet direct IP implemented; cross-home reachability remains unproven.
- License for project source/assets remains pending owner decision before publishing.

## Implementation notes

- Small modules combined to avoid empty scaffolding. All network RPCs share one
  autoload path; no per-cart RPC node-path race.
- Five-cart snapshots use packed float arrays, not verbose per-field dictionaries.
  Integer host ticks remain exactly representable within the five-minute race.
- Collision shove is bounded to 4 m/s; pair cooldown and victim protection limit damage.
- Ramming currently applies equal body damage to both participants. Rear/side impact
  differentiation is pending tuning, explicitly not the final damage model.
- Results are repeated in full snapshots. A reliable result-event/revision layer is
  a follow-up hardening task before latency/loss acceptance.
- No unrelated network/account/firewall/router settings were changed automatically.
