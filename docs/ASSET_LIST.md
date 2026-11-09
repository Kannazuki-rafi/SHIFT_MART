# Asset contract

Current art is original procedural primitive geometry. No external asset downloads.
Scale: meters. Floor Y=0. Up +Y. Trolley forward **-Z**. Collision is separate from visuals.
Cart mesh root includes basket, four wheels, handle, rider body/head/cap and groceries.
Camera is a sibling of trolley, never a child of the animated visual root.

Final team replacements: trolley, rider, racks, freezer, checkout, pallet, gate,
three products, banana, can, pickup marker and arrows. Use GLB and simple collision
shapes. Keep CharacterBody3D root and replace only mesh_root contents.
Audio is not implemented in this milestone. Motor, ram, break, repair, shift warning,
gate, pickup, item and finish sounds remain required later.
