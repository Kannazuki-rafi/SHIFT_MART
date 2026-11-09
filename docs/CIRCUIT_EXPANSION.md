# Supermarket circuit and events

The latest layout tightens the expanded footprint by 20% on both axes to approximately 100.8 x 119.7 meters. It retains the longer circuit, three shared fork pairs and stockroom S-bends. Short stocked shelving bays, bakery islands, freezer end caps and corner department displays replace empty or repetitive space. Twelve item pads and two wet patches provide more interaction along the route.

Three cabinets use a red landing footprint, a 1.5 second warning and a 0.5 second fall. Impact deals 25 damage and a 0.75 second stun; each event rearms after 18 seconds. Two produce racks drop five visible fruit each. Landed fruit causes 1.25 seconds of slipping without damage, is consumed on contact, and otherwise clears after eight seconds. Fruit events rearm after 15 seconds.

The host owns event decisions. Compact trigger timestamps and consumed-fruit masks travel in race snapshots. Protected, respawning and finished players are immune; events reset on rematch. Protocol: shift-mart-store-events-v4.

Verification: physical three-lap traversal through both gate layouts, all twelve pickups, lap and branch progression, solo flow, focused event tests, and four ENet processes with matching cabinet-warning timestamps and rematch. Human playtesting is still needed for difficulty and the three-to-five-minute match target.

The art remains procedural placeholders; use KebutuhanArt3d.md for replacement models.
