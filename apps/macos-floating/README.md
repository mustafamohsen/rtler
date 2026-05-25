# RTLer macOS Experiment

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

## Package a local app bundle

From the repo root:

```bash
./scripts/build-macos-floating-app.sh
open dist/RTLer.app
```

The generated app is ad-hoc signed for local/private-alpha testing and bundles `librtler.dylib` inside the app.

## Run from SwiftPM during development

```bash
cd apps/macos-floating
swift run RTLer
```

On first conversion, macOS may prompt for Accessibility permission. Grant permission in System Settings, then try again. The status bar `RTL` menu also includes an Accessibility Settings shortcut.

## Current behavior

- Shows a small always-on-top draggable `RTL` floating button.
- On click, attempts to copy selected text from the frontmost app.
- Transforms the copied text via the Rust RTLER library through C FFI.
- Pastes the transformed text back over the selection.
- Restores the previous plain-text clipboard contents after paste.
- If no selected text is detected, transforms Arabic-script clipboard text in place.
- Provides a status bar menu for show/hide, reset position, Accessibility Settings, and quit.
- Persists the floating button position between launches.

## Known experimental limitations

- Uses clipboard-mediated `Cmd+C` / `Cmd+V` automation.
- Some apps may block synthetic keyboard events.
- Timing may need tuning for slow apps.
- Replacement is plain text.
- Clipboard preservation currently targets plain text, not rich clipboard payloads.
- The floating panel may still affect focus in some app/window configurations.
