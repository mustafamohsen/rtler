# RTLER Floating macOS Experiment

Experimental AppKit floating button for replacing selected text in the frontmost macOS app with RTLER output.

## Build/test

From the repo root:

```bash
cargo build
cd apps/macos-floating
swift test
swift build
```

The Swift package links against the Rust library in `../../target/debug`, so run `cargo build` first.

## Run

```bash
cd apps/macos-floating
swift run RtlerFloating
```

On first conversion, macOS may prompt for Accessibility permission. Grant permission in System Settings, then try again.

## Current behavior

- Shows a small always-on-top `RTL` floating button.
- On click, attempts to copy selected text from the frontmost app.
- Transforms the copied text via the Rust RTLER library through C FFI.
- Pastes the transformed text back over the selection.
- Restores the previous clipboard contents after paste.

## Known experimental limitations

- Uses clipboard-mediated `Cmd+C` / `Cmd+V` automation.
- Some apps may block synthetic keyboard events.
- Timing may need tuning for slow apps.
- Replacement is plain text.
- The floating panel may still affect focus in some app/window configurations.
