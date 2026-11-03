# Whiteboard Room: Remaining Work

This plan records work discussed during the browser-wall prototype. The current
implementation is usable for experimentation, but the items below are not yet
complete or verified on Beast's desktop.

## gdCEF build and keyboard input

See [README.md](README.md#verify) for the current pinned extension build and
punctuation regression check.

- [ ] Investigate shifted characters, navigation keys, and shortcuts beyond the
  punctuation regression in both wall and full-window modes. Preserve normal
  text input and key-release behavior rather than injecting text through
  page-specific JavaScript.

## Browser performance and distance-based refresh

- [ ] Measure actual browser paint rates and room frame times, plus CPU/GPU load,
  with pages idle and active, before choosing higher refresh limits. Compare the
  two-browser setup with a useful baseline on Beast's 240 Hz display.
- [ ] Expose Chromium's runtime windowless frame-rate setting through the patched
  gdCEF extension. Change the limit without reloading the page, losing session
  state, or interrupting input.
- [ ] Implement and test a per-board policy. Initial values to evaluate:
  - Distant or behind the player: 1 FPS.
  - Nearby and visible, but not being used: 30 FPS.
  - Board currently being used on the wall or full-window: 120 FPS.
  - Other boards while one is full-window: 1 FPS.
- [ ] Measure whether 240 FPS is achievable and useful for the active browser
  before making it the default. Refresh limits are maximums, not guarantees;
  limiting paints does not necessarily stop background scripts or network use.
- [ ] Verify transitions between rates, visibility/distance changes, multiple
  browsers, input, persistence, and clean shutdown. Avoid rapid switching near
  distance or visibility boundaries if measurements show it causes problems.

## Native Wayland and desktop verification

- [ ] Investigate enabling native Wayland for gdCEF/Chromium. The Godot window
  prefers Wayland, but the current gdCEF build requires an X11 display, usually
  XWayland; without it, the embedded browser fails to initialize.
- [ ] Test on Beast's actual desktop: native Wayland window, mouse capture and
  release, wall cursor and right-button glance, 12-unit interaction reach,
  target-specific E-to-full-window, Esc transitions, keyboard input, and return
  to room rendering. Check both browser-backed walls.
- [ ] Assess comfort and frame pacing during real board use. Stop testing if it
  causes discomfort; compare the stable-cursor interaction and full-window view
  before making further camera or refresh-rate changes.

## Current constraints

- The browser requests up to 120 paint updates per second at all distances;
  distance-based throttling is not implemented.
- Full-window mode disables the room's 3D rendering, but does not pause the
  other browser.
- Browser storage is separate from the user's regular browser profile. The
  embedded browsers share the gdCEF profile but use normal per-origin storage.
