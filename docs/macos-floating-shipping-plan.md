# macOS Floating Button Shipping Plan

## Goal

Turn the current experimental macOS floating button into a shippable RTLER macOS app for private alpha first, then a public beta-quality unsigned/signed build.

The current prototype proves the core interaction model:

- a draggable always-on-top `RTL` button,
- clipboard-mediated selected-text replacement,
- Rust RTLER transform through FFI,
- fallback transform of Arabic-script clipboard text when no selection is available,
- subtle success/error feedback.

This plan focuses on making that prototype installable, understandable, recoverable, and manually validated.

## Release levels

### Private alpha

Target audience: project owner and a tiny set of trusted testers.

Acceptable limitations:

- unsigned or ad-hoc signed app,
- manual permission setup is acceptable if clearly documented,
- plain-text clipboard restoration only,
- logs may remain in Console/terminal,
- app-specific incompatibilities may exist if documented.

Not acceptable:

- users must run `cargo build` or `swift run`,
- app cannot be quit cleanly,
- missing Accessibility permission silently fails,
- no known-limits documentation.

### Public beta

Target audience: non-technical macOS users who can install a downloaded app.

Required improvements beyond private alpha:

- signed/notarized app if distributed outside a developer machine,
- first-run onboarding for Accessibility permission,
- stable app bundle containing the Rust library,
- position persistence,
- basic app menu/status controls,
- manually validated compatibility matrix.

## Product scope for first shippable macOS app

### In scope

- Floating draggable RTLER button.
- Replace selected text in the frontmost app.
- Transform Arabic-script clipboard text when no selected text is detectable.
- Preserve and restore plain-text clipboard for selection replacement.
- User-visible feedback for:
  - selection replacement success,
  - clipboard transformation success,
  - permission needed,
  - no selected text / no Arabic clipboard fallback,
  - transform failure.
- Accessibility permission detection and guidance.
- Quit/hide controls.
- App bundle packaging.
- Manual QA results and known limitations.

### Out of scope for first shippable version

- Windows/Linux support.
- Full rich clipboard preservation.
- Per-app Accessibility insertion APIs.
- Auto-update.
- App Store distribution.
- Deep preferences UI.
- Global hotkey, unless click reliability regresses enough to require it.

## Architecture target

```text
apps/macos-floating/
├── Sources/
│   ├── RtlerFloating/           # AppKit UI shell
│   └── RtlerFloatingCore/       # selection/clipboard/permission service
├── Tests/
│   └── RtlerFloatingTests/      # fake-backed service behavior tests
├── Package.swift
└── README.md

Rust crate
├── src/lib.rs                   # RTLER transform source of truth
├── include/rtler.h              # C FFI header
└── target/.../librtler.*        # packaged into app bundle for release
```

Keep the boundary clean:

- Swift UI should only decide how to present state.
- `SelectionReplacementService` should own cross-app replacement behavior.
- Rust stays the only text-shaping implementation.
- Build/packaging scripts should own library placement and install names, not app code.

## Phase 1 — Private alpha hardening

### 1.1 Package a launchable `.app`

Problem: currently users must run:

```bash
cargo build
cd apps/macos-floating
swift run RtlerFloating
```

Plan:

1. Add a packaging script, e.g. `scripts/build-macos-floating-app.sh`.
2. Build Rust in release mode:
   - `cargo build --release`
3. Build Swift in release mode:
   - `cd apps/macos-floating && swift build -c release`
4. Create an app bundle:
   - `RtlerFloating.app/Contents/MacOS/RtlerFloating`
   - `RtlerFloating.app/Contents/Resources/`
   - `RtlerFloating.app/Contents/Info.plist`
5. Copy the Rust dynamic library into the app bundle, or switch to static linking if simpler.
6. Ensure runtime linking works when launched from Finder, not just from terminal.

Acceptance criteria:

- Double-clicking `RtlerFloating.app` launches the floating button.
- No terminal is needed.
- The app can transform selected text in TextEdit after permission is granted.
- The app works from a different directory than the repo checkout.

Validation:

```bash
scripts/build-macos-floating-app.sh
open dist/RtlerFloating.app
```

Manual test:

- Launch from Finder.
- Transform selected Arabic text in TextEdit.
- Quit app cleanly.

### 1.2 Add `Info.plist` and app metadata

Plan:

Add a minimal `Info.plist` with:

- `CFBundleName`: `RTLER Floating`
- `CFBundleDisplayName`: `RTLER`
- `CFBundleIdentifier`: stable identifier, e.g. `com.mustafamohsen.rtler.floating`
- `CFBundleVersion`
- `CFBundleShortVersionString`
- `LSUIElement`: likely `true` for accessory/background-style app, depending on menu/status behavior
- human-readable permission usage text where applicable

Acceptance criteria:

- App has a stable name in System Settings → Privacy & Security → Accessibility.
- App identity remains stable across rebuilds, so permissions are not unnecessarily reset.

### 1.3 Add quit and basic controls

Problem: accessory/floating apps need an obvious way to quit.

Plan:

Add either:

- a status bar item with menu:
  - `Show Button`
  - `Hide Button`
  - `Transform Clipboard` maybe later
  - `Quit RTLER`

or a right-click/context menu on the floating button:

- `Quit`
- `Reset Position`
- `Open Accessibility Settings`

Recommendation: status bar item first. It is discoverable and solves quit/hide without cluttering the floating button.

Acceptance criteria:

- User can quit without Activity Monitor or terminal.
- User can hide/show the floating button.
- User can reset the button location if dragged off-screen.

### 1.4 Persist button position

Plan:

- Save panel origin to `UserDefaults` after drag ends.
- Restore on launch.
- Clamp restored position to visible screen bounds.
- Add reset-position menu item.

Acceptance criteria:

- Drag button, quit, relaunch: position is restored.
- If monitor layout changes, the button remains visible.

### 1.5 Improve permission UX

Problem: missing Accessibility permission currently becomes an orange/red feedback state plus macOS prompt, but the user may not know what to do.

Plan:

1. Check `AXIsProcessTrusted()` at startup.
2. On first conversion if not trusted:
   - show permission feedback on button,
   - open a concise alert/popover explaining:
     - RTLER needs Accessibility to send copy/paste to the frontmost app,
     - no keystrokes are recorded,
     - grant permission in System Settings.
3. Provide a button to open System Settings:
   - `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`
4. Detect permission after app regains focus or periodically after prompt.

Acceptance criteria:

- User understands why permission is needed.
- System Settings opens to the relevant area or as close as macOS allows.
- If permission is denied, no clipboard mutation occurs.

### 1.6 Clarify feedback states

Current states:

- `✓` green: selection replaced.
- `⧉` teal: clipboard transformed.
- `!` orange/red: permission/error.

Plan:

- Keep animation subtle: color fade + label fade only; no scale pulse.
- Consider brief tooltip/popover only for errors:
  - `No selection or Arabic clipboard text found`
  - `Accessibility permission needed`
- Keep success feedback transient and quiet.

Acceptance criteria:

- Success is visible but not distracting.
- Error states are understandable without terminal logs.

## Phase 2 — Reliability and compatibility

### 2.1 Manual QA matrix

Create and maintain a table in docs or README with results.

Target apps:

| App | Selected text replacement | Clipboard fallback | Notes |
| --- | --- | --- | --- |
| TextEdit | TBD | TBD | baseline editable field |
| Notes | TBD | TBD | native rich text |
| Safari/Zen browser field | TBD | TBD | web text inputs |
| Chrome browser field | TBD | TBD | web text inputs |
| VS Code | TBD | TBD | editor surface |
| Affinity | TBD | TBD | main target class |
| Terminal | TBD | TBD | shell/text selection caveats |

Text cases:

- Arabic sentence.
- Mixed Arabic + English URL/email.
- Urdu sentence.
- Persian sentence.
- Arabic punctuation and numbers.
- Empty selection.
- Non-Arabic clipboard.
- Arabic clipboard fallback.
- Read-only field.
- Existing clipboard with plain text.
- Existing clipboard with rich/non-text data.

Acceptance criteria for private alpha:

- TextEdit passes.
- Browser text field passes in at least one browser.
- Affinity passes for the common user flow.
- Known failures are documented.

Acceptance criteria for public beta:

- Manual QA matrix is complete.
- No silent data-loss cases are known.
- Clipboard limitations are explicit.

### 2.2 Clipboard timing hardening

Current behavior uses a configurable paste restore delay:

- `RTLER_PASTE_RESTORE_DELAY`
- default `2.0s`

Plan:

- Keep default conservative for alpha.
- Record app-specific failures.
- Consider making restore delay configurable through internal preferences only if needed.
- Consider detecting pasteboard consumption if practical, but do not over-engineer before QA data.

Acceptance criteria:

- Affinity and browser fields reliably paste before clipboard restoration.
- Delay does not feel excessively slow for normal users.

### 2.3 Clipboard preservation policy

Current implementation preserves/restores plain-text clipboard only during selected-text replacement.

Plan:

- Document this clearly for alpha.
- For beta, investigate safer rich clipboard snapshot restoration:
  - copying `NSPasteboardItem`s stalled in prototype,
  - determine whether specific item types or lazy pasteboard providers caused the stall,
  - add timeout/fallback if rich preservation is attempted.

Recommendation:

- Do not block private alpha on rich preservation.
- Block public beta only if testers frequently rely on rich clipboard contents.

Acceptance criteria:

- Plain-text clipboard restore is reliable.
- Rich clipboard limitation appears in README/release notes.

### 2.4 Selection detection robustness

Current fallback must distinguish:

- no selection copied, so clipboard remains original,
- selected text equals current clipboard text,
- app copies slowly,
- app refuses synthetic copy.

Plan:

- Keep current heuristic but add manual tests for selected text identical to clipboard text.
- If false fallback occurs, improve service protocol/test cases around pasteboard `changeCount` and source app behavior.

Acceptance criteria:

- If selected text exists and is same as clipboard text, replacement still works when the app updates pasteboard/change count.
- If no selection exists, Arabic clipboard fallback works.
- If no selection and non-Arabic clipboard, app shows error without mutation.

## Phase 3 — Build, signing, and distribution

### 3.1 Release build script

Plan:

Add script that can produce:

- debug/developer `.app`,
- release `.app`,
- zipped artifact.

Example commands:

```bash
scripts/build-macos-floating-app.sh --configuration release
scripts/package-macos-floating-app.sh
```

Artifacts:

```text
dist/
├── RtlerFloating.app
└── RtlerFloating-macos-arm64.zip
```

Acceptance criteria:

- Clean checkout can produce artifact with one command.
- Artifact can be copied elsewhere and launched.

### 3.2 Signing/notarization decision

For private alpha:

- ad-hoc signing may be enough.

For public beta:

- use Developer ID signing and notarization if available.

Plan:

- Add optional signing env vars:
  - `RTLER_CODESIGN_IDENTITY`
  - `RTLER_NOTARIZE_PROFILE`
- If env vars are absent, produce unsigned/ad-hoc build and document Gatekeeper steps.

Acceptance criteria:

- Script works without secrets.
- Script can sign/notarize when credentials are provided.
- No secrets are committed.

### 3.3 Versioning

Plan:

- Define app version independent of Rust crate version if necessary.
- Start with `0.1.0-alpha.1`.
- Include version in `Info.plist` and release zip name.

Acceptance criteria:

- App About/menu/release artifact identifies version.
- Version can be bumped in one obvious place.

## Phase 4 — Documentation

### 4.1 Update macOS README

Add:

- How to install.
- How to grant Accessibility permission.
- How to use selected-text replacement.
- How clipboard fallback works.
- How to quit/hide/reset.
- Known limitations.
- Troubleshooting.

Troubleshooting examples:

- Button flashes permission warning.
- Nothing changes in target app.
- Clipboard transformed instead of selected text.
- App is blocked by Gatekeeper.
- How to adjust paste restore delay for debugging.

### 4.2 Add release notes template

Plan:

Create `docs/release-notes/macos-floating-alpha-template.md` or include in README.

Sections:

- What's included.
- Install steps.
- Known limitations.
- Apps tested.
- How to report issues.

### 4.3 Issue tracker labels/tasks

Use GitHub issues to track shipping work.

Suggested issues:

1. Package macOS floating app as launchable `.app`.
2. Add status menu with quit/hide/reset controls.
3. Persist floating button position.
4. Add Accessibility permission onboarding.
5. Create manual QA compatibility matrix.
6. Document clipboard limitations and troubleshooting.
7. Add optional signing/notarization to release script.

## Phase 5 — Optional product improvements after alpha

### 5.1 Global hotkey

Add only if testers prefer it or click-based automation has app compatibility issues.

Potential behavior:

- `Option+Shift+R` transforms selected text.
- Floating button remains as visual/status affordance.

Risks:

- hotkey registration conflicts,
- extra permissions/expectations,
- hidden behavior may be less discoverable.

### 5.2 Preferences

Potential settings:

- launch at login,
- show/hide floating button,
- paste restore delay,
- enable/disable clipboard fallback,
- reset permissions help.

Do not build before alpha unless needed.

### 5.3 Better error popovers

Potential messages:

- `No selected text or Arabic clipboard text found.`
- `Grant Accessibility permission to let RTLER copy and paste.`
- `This app did not accept paste. Try increasing paste delay or use clipboard fallback.`

## Recommended implementation order

1. Package launchable `.app` with bundled Rust library.
2. Add status/menu controls: quit, hide/show, reset position, permissions.
3. Persist and clamp button position.
4. Improve Accessibility permission onboarding.
5. Update README and known limitations.
6. Run manual QA matrix and record results.
7. Decide whether alpha is ready.
8. Optional signing/notarization for broader distribution.

## Definition of done for private alpha

- `dist/RtlerFloating.app` launches via Finder.
- App has a quit path.
- Button position persists.
- Missing Accessibility permission is understandable and recoverable.
- TextEdit, browser text field, and Affinity have been manually tested.
- README explains installation, usage, permissions, and limitations.
- `cargo test` passes.
- `cd apps/macos-floating && swift test` passes.
- Build/package script works from a clean checkout.

## Definition of done for public beta

Everything in private alpha, plus:

- Compatibility matrix completed.
- App is signed/notarized or distribution clearly documents Gatekeeper expectations.
- Release artifact is versioned.
- Known limitations are explicit and acceptable.
- No known issue causes silent destructive clipboard/data loss.
