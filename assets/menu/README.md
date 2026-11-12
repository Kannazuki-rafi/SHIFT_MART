# MIDNIGHT SHIFT menu assets

These are generated concept assets, intended to be replaced by the project's
final art. Both were made with the built-in image generation tool on 2026-11-10.

- `midnight-aisle.png`: full-screen supermarket illustration, opaque, 16:9.
  Keep the left 46% quiet for the live title and buttons.
- `midnight-title.png`: separate RGBA title artwork. Preserve alpha when replacing.
  The title reads MIDNIGHT SHIFT; the underlying game remains SHIFT MART.

The game draws these in `scripts/menu_art.gd`; changing the files at these paths
replaces the artwork without changing menu behavior. All interactive text is live
Godot UI. The generated title is the only baked-in menu lettering.

`scripts/midnight_theme.gd` owns the palette and standard control styles.
`scripts/menu_action.gd` owns the native Button with the custom receipt drawing:
65ms entrance stagger, 320ms entrance slide, 180ms focus slide/tilt, 70ms press.
The art has restrained pointer parallax. Settings > Reduce menu motion disables
both effects and is saved to `user://menu_settings.cfg`.

The direction is midnight supermarket mischief: warped aisles, exaggerated trolley
perspective, printed paper texture, receipt cuts, cream lettering, acid yellow
selection, and pink offset ink. The artwork carries the surreal setting; the
yellow receipt and matching cursor make keyboard/mouse selection unambiguous.
Forms appear only after choosing CLOCK IN. The 1280x720 composition scales as a
unit with letterboxing at other aspect ratios.

For the later pause-menu pass, reuse the palette and receipt Button component
over the paused world. The current gameplay/local-menu behavior is unchanged.

Exact generation prompts are in `PROMPTS.md`.
