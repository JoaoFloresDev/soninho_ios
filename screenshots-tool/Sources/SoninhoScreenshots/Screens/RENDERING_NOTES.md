# Rendering notes — read this before editing the screens

These are non-obvious gotchas that bit us during the framework's first
30 iterations. Skipping any of them produces visibly broken screenshots
that look fine in code review but reveal the bug only after rendering.

## 1. Never put `.shadow()` on a parent view that contains opaque internals

The macOS `ImageRenderer` rasterises the whole view hierarchy when it
generates a shadow. If the parent contains a Dynamic Island or any dark
opaque shape, the renderer bleeds shadow halos around those internal
elements — looks like a tacky glow.

**Wrong:**
```swift
DeviceFrame { content }
    .shadow(color: .black.opacity(0.3), radius: 30)  // halo around Dynamic Island
```

**Right** — sibling shadow placed BEHIND the device:
```swift
ZStack {
    RoundedRectangle(cornerRadius: 60).fill(.black.opacity(0.3)).blur(radius: 30)
    DeviceFrame { content }
}
```

The kit's `MarketingScreen` already does this — only watch out if you
extend or wrap it.

## 2. VStack content shorter than the canvas auto-centers vertically

If your screen recreation has fewer subviews than fill the device canvas,
the VStack will center vertically — and your iOS status bar will visibly
shift down 50–100pt. The fix is to push content to the top with a trailing
`Spacer(minLength: 0)`:

```swift
VStack(spacing: 0) {
    iOSStatusBar()
    customHeader
    content
    Spacer(minLength: 0)   // <-- mandatory
}
```

All the placeholder screens in this folder follow this pattern. Don't
remove it.

## 3. System tokens cannot be rendered

These don't render through macOS `ImageRenderer` — they require a real
iOS simulator screenshot:

- `FamilyActivitySelection.applicationTokens` (Screen Time API)
- `MapKit` map tiles
- `WidgetKit` live widget data
- `PDFKit` PDF previews
- `VisionKit` camera preview

If your real app shows any of these, build the closest static stand-in
that LOOKS like what users see at runtime — not a redesigned alternative.
The "Golden rule" in the `/generate-print` skill is non-negotiable: be
faithful to the production layout, only deviate where the framework
literally can't render.

## 4. Use `.foregroundStyle()`, never `.foregroundColor()`

`.foregroundColor()` is deprecated. `.foregroundStyle()` works for both
solid colors and gradients and renders consistently in `ImageRenderer`.

## 5. Headlines fail-fast on TODO

`main.swift` calls `validateNoTODOs(...)` before rendering. If any
headline in the active mode's treatments contains "TODO" or is empty,
the run aborts. You'll see the offending entries listed. Fill them in
`Headlines.swift` (with user-approved copy) and rerun.
