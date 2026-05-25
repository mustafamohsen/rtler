# Experimental Plan: Cross-Platform Floating RTLER Button

## Goal

Create a minimal always-on-top floating button that converts the currently selected text in any application and replaces that selection with RTLER's transformed text.

Initial target: **macOS**.

Long-term target: cross-platform, with the existing Rust RTLER library as the shared transformation core.

## Product behavior

User flow:

1. User selects Arabic-script text in any app.
2. User clicks a small floating RTLER button.
3. The app reads the selected text.
4. The app transforms it using the Rust `rtler::transform` library.
5. The app replaces the original selected text with the transformed output.
6. If conversion cannot happen, the app shows a minimal error state without destroying the user's clipboard.

## Key design constraint

Operating systems do not expose a universal, safe, cross-application “get selected text and replace it” API.

The practical MVP approach is clipboard-mediated automation:

1. Preserve current clipboard contents.
2. Simulate Copy in the frontmost app.
3. Read plain text from the clipboard.
4. Transform via RTLER library.
5. Put transformed text on the clipboard.
6. Simulate Paste in the frontmost app.
7. Restore the user's original clipboard after the paste completes.

This is how many cross-app text utilities work. It is not perfect, but it is the best experimental baseline for broad application compatibility.

## Architecture

```text
rtler/
├── src/                         # existing Rust library + CLI
├── apps/
│   └── macos-floating/          # macOS AppKit/Swift app
├── docs/
│   └── experimental-floating-button-plan.md
└── tests/
```

### Shared core

Use the existing Rust library as the source of truth:

```rust
rtler::transform(input: &str) -> TransformResult
```

For native app integration, expose a small FFI boundary rather than shelling out to the CLI.

Recommended experimental FFI shape:

```c
char *rtler_transform_text(const char *input);
void rtler_free_string(char *ptr);
```

This keeps Swift simple:

```swift
let transformed = RtlerBridge.transform(selectedText)
```

### Why not use the CLI?

The CLI is useful for users and tests, but the floating app should prefer the library/FFI path because:

- no subprocess overhead
- easier packaging
- avoids shell escaping issues
- keeps error handling inside the app
- matches the user's preference

## macOS implementation plan

### App technology

Recommended stack:

- Swift + AppKit
- `NSPanel` for the always-on-top floating button
- Rust static or dynamic library linked through C FFI

Avoid SwiftUI-only for the first version because non-activating floating panels are easier and more controllable in AppKit.

### Floating button window

Use a custom `NSPanel`:

- `styleMask`: `.nonactivatingPanel`, `.borderless` or minimal titled style during debugging
- `level`: `.floating` or `.statusBar`
- `collectionBehavior`: `.canJoinAllSpaces`, `.fullScreenAuxiliary`
- `hidesOnDeactivate = false`
- `isMovableByWindowBackground = true`
- `canBecomeKey = false`
- `canBecomeMain = false`

Important: the panel should avoid stealing focus from the user's active app. If the button click activates RTLER, the selected text in the source app may disappear or become inaccessible.

### Conversion sequence on click

On click:

1. Remember frontmost app:
   - `NSWorkspace.shared.frontmostApplication`
2. Preserve clipboard:
   - capture `NSPasteboard.general.pasteboardItems`
   - capture `changeCount`
3. Ensure Accessibility permission:
   - `AXIsProcessTrustedWithOptions`
   - prompt the user if missing
4. Send `Cmd+C` to the frontmost app using `CGEvent`.
5. Wait briefly for pasteboard `changeCount` to change.
6. Read `String` from `NSPasteboard.general`.
7. If no text exists:
   - restore clipboard
   - show a small failure indication
   - do not paste
8. Transform text through RTLER FFI.
9. Put transformed text on clipboard.
10. Reactivate source app if needed.
11. Send `Cmd+V`.
12. Wait briefly.
13. Restore original clipboard contents.
14. Show a subtle success state.

### Clipboard preservation

Preserve as much as possible:

- Prefer storing full pasteboard items, not just string content.
- If full restoration is too brittle in the experiment, document the limitation and preserve plain text at minimum.
- Delay clipboard restoration until after paste is likely consumed.

### Permissions

macOS likely requires Accessibility permission for synthetic keyboard events.

The app should:

- detect missing permission on startup or first click
- show concise setup instructions
- deep-link/open System Settings if possible
- fail safely if permission is denied

Possible permissions:

- Accessibility: required for global keyboard event posting/control
- Input Monitoring: may be needed depending on event strategy
- Automation: may be needed if AppleScript/System Events is used, but the preferred plan is CGEvent, not AppleScript

### Error states

Minimal button states:

- idle
- working
- success flash
- permission needed
- no text selected
- transform warning/error

Warnings from RTLER should not block replacement by default. For the experiment, show warnings only in a debug log or optional popover.

## Cross-platform plan

The cross-platform architecture should split responsibilities:

```rust
RTLER core
  ↓
Platform selection adapter
  ↓
Floating UI shell
```

Define a platform abstraction conceptually like:

```text
SelectionReplacer
- read_selected_text() -> Result<String>
- replace_selected_text(String) -> Result<()>
- restore_clipboard()
- permission_status()
```

### macOS

- UI: AppKit `NSPanel`
- Selection: clipboard + `CGEvent` Cmd+C/Cmd+V
- Clipboard: `NSPasteboard`
- Permissions: Accessibility APIs

### Windows later

Candidate approaches:

- UI: native WinUI/WPF/Tauri shell
- Selection: clipboard + `SendInput` Ctrl+C/Ctrl+V
- Clipboard: Win32 clipboard APIs
- Permissions: usually less explicit than macOS, but protected/elevated apps may block automation

### Linux later

Candidate approaches:

- UI: GTK/Qt/Tauri shell
- X11: clipboard + XTest Ctrl+C/Ctrl+V
- Wayland: significantly harder due to compositor security restrictions
- Clipboard: X11 selections / `wl-clipboard` equivalents

Linux should probably be split into:

1. X11 support
2. Wayland best-effort support with clear limitations

## TDD / validation strategy

UI automation is harder than library testing, so use layered tests.

### Rust core / FFI tests

- Add tests for FFI transform wrapper.
- Confirm UTF-8 Arabic/Urdu/Persian strings round-trip through FFI.
- Confirm allocated strings can be freed safely.

### macOS service unit tests

Where possible, isolate logic behind protocols:

- `ClipboardStore`
- `KeyboardEventSender`
- `RtlerTransformer`
- `SelectionReplacementService`

Then unit-test with fakes:

- selected text is copied and transformed
- clipboard is restored after successful paste
- clipboard is restored after no-text failure
- permission denial prevents mutation
- transform warnings do not block replacement

### Manual QA checklist

Test on macOS with these target apps:

- TextEdit
- Notes
- Safari text field
- Chrome text field
- Affinity text object, if available
- VS Code editor

Cases:

- Arabic sentence
- mixed Arabic + English URL/email
- Urdu sentence
- Persian sentence
- no selection
- read-only field
- existing clipboard with rich content
- app without Accessibility permission

## MVP branch implementation slices

Do not implement all at once. Use these vertical slices.

### Slice 1 — FFI bridge

Goal: Swift-callable RTLER transform function.

Steps:

1. Add an FFI surface around `rtler::transform`.
2. Add Rust tests for UTF-8 FFI behavior.
3. Generate or hand-write a C header.
4. Confirm macOS build can link the library.

Done when:

- FFI tests pass.
- Existing CLI/library tests pass.

### Slice 2 — minimal macOS app shell

Goal: visible floating button that does nothing but show success state.

Steps:

1. Create `apps/macos-floating`.
2. Add AppKit app with floating non-activating panel.
3. Add minimal circular button.
4. Make it draggable and always on top.

Done when:

- App launches locally.
- Button stays above normal windows.
- Button click does not steal focus from the active app, or the limitation is documented.

### Slice 3 — clipboard copy/read service

Goal: clicking button reads selected text without replacing it yet.

Steps:

1. Add Accessibility permission detection.
2. Preserve clipboard.
3. Simulate `Cmd+C`.
4. Read selected plain text.
5. Restore clipboard.
6. Show copied text in debug log or temporary popover.

Done when:

- TextEdit selected text can be read.
- Existing clipboard is restored.
- No-selection path is safe.

### Slice 4 — transform and replace

Goal: selected text is replaced with RTLER output.

Steps:

1. Call RTLER through FFI.
2. Put transformed text on clipboard.
3. Simulate `Cmd+V`.
4. Restore original clipboard.
5. Show success/failure state.

Done when:

- Arabic selection in TextEdit is replaced.
- Mixed Arabic fixture sample is replaced.
- Clipboard is restored.

### Slice 5 — Affinity/manual hardening

Goal: validate against the actual target class of apps.

Steps:

1. Test Affinity or equivalent non-RTL tool.
2. Tune event delays and focus restoration.
3. Add user-facing permission/no-selection feedback.
4. Document known limitations.

Done when:

- Manual QA checklist has results recorded in docs.

## Risks

### Selection can disappear when clicking the button

Mitigation:

- Use non-activating panel.
- Remember/reactivate frontmost app.
- Prefer global hotkey later if clicking is unreliable.

### Clipboard restore may race with paste

Mitigation:

- Wait after paste before restoring.
- Make delay configurable internally.
- Test slow apps.

### Some apps block synthetic paste

Mitigation:

- Detect paste failure where possible.
- Document app-specific limitations.
- Consider app-specific accessibility insertion later.

### Rich text may be lost

Mitigation:

- Preserve rich clipboard contents.
- Replacement itself is plain text by design for this experiment.

### Wayland cross-platform support is hard

Mitigation:

- Treat Linux Wayland as a separate future platform, not part of macOS experiment.

## Recommended first experimental deliverable

A macOS-only unsigned developer app with:

- floating always-on-top RTLER button
- Accessibility permission prompt/check
- selected text copied via Cmd+C
- transform via Rust library/FFI
- replacement via Cmd+V
- clipboard restoration
- manual QA checklist

This is enough to validate whether the interaction model works before investing in polish or cross-platform packaging.
