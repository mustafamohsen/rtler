# Windows Floating App Plan

## Purpose

Build a Windows app for RTLer that follows the successful macOS beta path: a tiny always-on-top floating control plus tray menu that transforms selected Arabic-script text in the frontmost app by reusing the existing Rust transform core through FFI.

This is a planning document only. It intentionally does not implement the Windows app.

## Sources studied

- Handoff: `/tmp/rtler-handoff-20260525-current.md`.
- Product/design docs: `README.md`, `DESIGN.md`, `docs/experimental-floating-button-plan.md`, `docs/macos-floating-shipping-plan.md`, `apps/macos-floating/README.md`.
- macOS app code:
  - `apps/macos-floating/Sources/RTLer/main.swift`
  - `apps/macos-floating/Sources/RtlerFloatingCore/SelectionReplacementService.swift`
  - `apps/macos-floating/Sources/RtlerFloatingCore/RtlerBridge.swift`
  - `apps/macos-floating/Tests/RtlerFloatingTests/SelectionReplacementServiceTests.swift`
  - `apps/macos-floating/Package.swift`
  - `apps/macos-floating/Resources/Info.plist`
  - `scripts/build-macos-floating-app.sh`
- Shared Rust/FFI code: `Cargo.toml`, `src/lib.rs`, `include/rtler.h`, `tests/ffi.rs`.
- CI: `.github/workflows/ci.yml`.
- Git history and branches: `main`, `develop`, `experiment/macos-floating-button`, and tag `v0.1.0-beta.1`.

## Current baseline to mirror

The macOS beta provides:

- a draggable, always-on-top floating `RTL` button;
- a status bar menu with show/hide/reset/accessibility/quit actions;
- persisted button position with screen clamping;
- selection replacement in the frontmost app through clipboard-mediated copy/transform/paste;
- fallback transform of Arabic-script clipboard text when no selection is detected;
- plain-text clipboard preservation for selection replacement;
- Rust C FFI bridge as the only native-app transform boundary;
- service-level tests using fake clipboard, keyboard, permission, foreground-app, and activator adapters;
- a local packaging script that produces `dist/RTLer.app` and bundles the Rust dynamic library.

The Windows app should preserve those product semantics unless Windows-specific behavior requires an intentional adaptation.

## Primary Windows stack decision

Assume a **C# WPF/.NET tray app** as the primary implementation path.

Rationale:

- WPF is pragmatic for a small desktop utility with a borderless topmost floating window.
- .NET has good unit testing ergonomics and straightforward P/Invoke for Win32 APIs.
- Tray menu support is mature via `System.Windows.Forms.NotifyIcon` or a maintained tray wrapper.
- Packaging can start with a portable self-contained zip and later move to MSI/MSIX or another installer.
- It mirrors the macOS architecture: native UI shell + platform service layer + Rust FFI bridge.

Non-primary alternatives for future reconsideration:

- WinUI 3: modern UI, but more packaging/runtime complexity for a tiny utility.
- Rust-native Win32: tighter language alignment, but more low-level UI/tray/windowing work.
- Tauri: cross-platform shell potential, but heavier than necessary and less natural for a non-activating floating utility.

## Target architecture

```text
rtler/
├── src/                              # Rust transform source of truth
├── include/rtler.h                   # C ABI contract
├── apps/
│   ├── macos-floating/               # existing Swift/AppKit app
│   └── windows-floating/             # planned C# WPF/.NET app
│       ├── RTLer.Windows.sln
│       ├── src/
│       │   ├── RTLer.Windows/        # WPF shell, tray menu, app resources
│       │   └── RTLer.Windows.Core/   # replacement service, Win32 adapters, FFI bridge
│       └── tests/
│           └── RTLer.Windows.Tests/  # fake-backed service tests
├── scripts/
│   └── build-windows-floating-app.*  # planned packaging script
└── docs/
    └── windows-floating-app-plan.md
```

Runtime data flow:

```text
User clicks floating button or tray action
 -> WPF UI calls SelectionReplacementService.ReplaceSelectionAsync()
 -> service captures foreground window
 -> service snapshots clipboard text
 -> service sends Ctrl+C through Win32 input adapter
 -> service waits for clipboard change / selected text
 -> RtlerTextTransformer calls rtler.dll through P/Invoke
 -> service writes transformed Unicode text to clipboard
 -> service restores foreground window/focus
 -> service sends Ctrl+V
 -> service waits for target app to consume paste
 -> service restores original plain-text clipboard
 -> UI shows success/fallback/error feedback
```

## Windows equivalents of macOS pieces

| macOS piece | Windows equivalent |
| --- | --- |
| AppKit `NSPanel` non-activating floating panel | WPF borderless topmost tool window configured not to take focus where practical |
| macOS status bar item | Windows notification area tray icon/context menu |
| `NSPasteboard` | Win32 clipboard APIs, exposed through a C# clipboard adapter |
| `CGEvent` Cmd+C/Cmd+V | `SendInput` Ctrl+C/Ctrl+V through a keyboard input adapter |
| `NSWorkspace.frontmostApplication` | `GetForegroundWindow` / process/window metadata |
| `NSRunningApplication.activate` | `SetForegroundWindow`, focus restoration, and best-effort foreground rules |
| Accessibility permission check | Windows control-capability checks: foreground window, integrity level/UIPI, clipboard availability, secure desktop/elevated app detection where possible |
| `UserDefaults` position storage | App settings file under `%APPDATA%\RTLer` or .NET user settings |
| `.app` bundle + `librtler.dylib` | portable zip or installer containing app exe, `rtler.dll`, icon, readme, license |

## Guiding principles

1. Keep Rust as the only text transform implementation.
2. Keep the native FFI boundary tiny and explicit: UTF-8 text in, allocated UTF-8 text out, free with `rtler_free_string`.
3. Keep UI thin; put cross-app automation logic in a testable service layer.
4. Preserve clipboard safety over cleverness.
5. Prefer simple visible feedback over complex animation.
6. Document Windows automation limits honestly, especially elevated apps and apps that reject synthetic input.
7. Follow the macOS history: plan → FFI validation → prototype → service tests → hardening → fallback → controls → packaging → docs → beta.

## End-to-end implementation plan

### Phase 0 — Preparation and project hygiene

Goal: create a clean branch and issue/doc trail before code work.

Steps:

1. Create a feature branch, e.g. `experiment/windows-floating-button`.
2. Keep this plan as the controlling document.
3. Open or prepare GitHub issues for each major phase, using the existing triage label vocabulary.
4. Confirm supported Windows baseline:
   - initial target: Windows 10/11 x64;
   - optional later: Windows on ARM64.
5. Confirm release level:
   - private alpha first;
   - public beta after packaging, docs, and manual QA.

Acceptance criteria:

- Branch exists.
- Plan is committed.
- No implementation starts until stack, scope, and first release level are agreed.

### Phase 1 — Validate Rust FFI for Windows

Goal: prove the existing FFI can be built and consumed on Windows before creating UI.

Steps:

1. Build the Rust crate for Windows from a Windows environment or CI runner:
   - `cargo build`
   - `cargo build --release`
   - expected dynamic artifact: `target/release/rtler.dll` plus import artifacts as produced by Rust/MSVC.
2. Run existing Rust validation on Windows:
   - `cargo fmt -- --check`
   - `cargo test`
   - `cargo clippy --all-targets --all-features -- -D warnings`
   - fixture diff checks for Arabic, mixed Arabic, Urdu, Persian.
3. Add or verify Windows-specific FFI smoke coverage:
   - UTF-8 Arabic input returns expected presentation-form output;
   - null input returns null;
   - invalid UTF-8 returns null if practical to test;
   - returned pointer is always freed by caller.
4. Keep the existing C ABI unless a concrete Windows blocker appears.

Acceptance criteria:

- Windows Rust build produces the library artifact needed by the C# app.
- Existing FFI tests pass on Windows.
- No native app code reimplements shaping/reordering.

Risks:

- C# strings are UTF-16 while the existing C ABI is UTF-8. This is acceptable, but the bridge must encode/decode explicitly and free returned pointers reliably.

### Phase 2 — Create the Windows solution skeleton

Goal: create a minimal C#/.NET app shape that mirrors the macOS separation between UI and core service.

Planned projects:

```text
apps/windows-floating/
├── RTLer.Windows.sln
├── src/
│   ├── RTLer.Windows/          # WPF executable
│   └── RTLer.Windows.Core/     # platform service + bridge
└── tests/
    └── RTLer.Windows.Tests/    # unit tests
```

Core interfaces to mirror from Swift:

```text
IClipboardStore
- ClipboardSnapshot Snapshot()
- void Restore(ClipboardSnapshot snapshot)
- string? GetString()
- void SetString(string text)
- int ChangeCountOrVersion()

IKeyboardEventSender
- void Copy()
- void Paste()

ITextTransformer
- string? Transform(string input)

IControlCapabilityChecker
- ControlCapability CheckForegroundTarget()

IForegroundWindowProvider
- ForegroundWindow? GetForegroundWindow()

IWindowActivator
- bool Activate(ForegroundWindow window)
```

Service contract:

```text
SelectionReplacementService.ReplaceSelectionAsync()
 -> SelectionReplaced
 -> ClipboardTransformed
 -> errors: control unavailable, no selected text, transform failed, clipboard unavailable, target paste likely failed
```

Acceptance criteria:

- Solution builds without UI behavior beyond launching/quitting.
- Core service is independent of WPF types where practical.
- Unit test project can test service behavior with fakes.

### Phase 3 — Implement the FFI bridge in C#

Goal: C# can call the Rust transform exactly once per operation through a small, tested bridge.

Plan:

1. Add a bridge in `RTLer.Windows.Core`, e.g. `RtlerNativeBridge`.
2. P/Invoke:
   - `rtler_transform_text(byte* or IntPtr input)`;
   - `rtler_free_string(IntPtr ptr)`.
3. Convert C# `string` to UTF-8 NUL-terminated bytes.
4. Convert returned pointer back to a UTF-8 string.
5. Always free non-null returned pointers in a `finally` block or equivalent safe wrapper.
6. Provide a fake `ITextTransformer` for service tests.

Acceptance criteria:

- A bridge test transforms `سلام` to `ﻡﻼﺳ`.
- Null/failure behavior maps to `null` or a typed transform failure.
- Memory ownership is explicit and localized.

Packaging note:

- During development, copy `rtler.dll` into the WPF output directory.
- Do not rely on a developer’s shell PATH for runtime loading.

### Phase 4 — Minimal WPF floating shell

Goal: launch a tiny floating `RTL` button with no transformation yet.

Steps:

1. Create a WPF app with no primary document window.
2. Show a small borderless floating window:
   - round visual matching macOS as closely as WPF makes practical;
   - always on top;
   - draggable;
   - click vs drag threshold;
   - does not appear as a normal taskbar app if tray-only behavior is chosen.
3. Add transient feedback states:
   - idle: `RTL`, blue;
   - success: `✓`, green;
   - clipboard fallback: `⧉`, teal;
   - warning/control issue: `!`, orange;
   - error: `!`, red.
4. Persist position after drag.
5. Clamp position to a visible monitor work area on startup.
6. Use DPI-aware sizing and test across 100%, 125%, 150%, and mixed-DPI monitors.

Acceptance criteria:

- App launches and shows a draggable topmost floating control.
- Position persists and remains visible after monitor changes.
- Clicking the button triggers a placeholder feedback state only.

Windows-specific caution:

- WPF windows normally activate on click. If clicking steals focus and loses selection, use Win32 extended styles and message handling to reduce activation, or rely on saving/restoring the foreground window before copy. This must be tested early.

### Phase 5 — Add tray icon and basic controls

Goal: match the macOS status menu with a Windows notification area control surface.

Tray menu items for alpha:

- Show Floating Button
- Hide Floating Button
- Reset Button Position
- Transform Clipboard
- About RTLer / Version
- Quit RTLer

Optional later:

- Start with Windows
- Paste restore delay setting
- Open logs
- Report issue

Acceptance criteria:

- User can quit without Task Manager.
- User can show/hide/reset the floating button.
- Tray icon uses the RTLer logo-derived `.ico` resource.
- The app behaves as a utility rather than a document app.

### Phase 6 — Clipboard adapter

Goal: safely snapshot, read, write, and restore plain Unicode text from the Windows clipboard.

Initial alpha policy:

- Preserve/restore plain Unicode text only, mirroring macOS beta limitations.
- Do not attempt full rich clipboard preservation in the first alpha.
- Clearly document that rich/image clipboard contents may not be preserved during selected-text replacement.

Implementation notes:

1. Use Win32 clipboard APIs or WPF/WinForms clipboard wrappers only behind `IClipboardStore`.
2. Prefer `CF_UNICODETEXT` for Windows text interoperability.
3. Track a clipboard sequence/version using `GetClipboardSequenceNumber` if available.
4. Add retries/backoff when opening the clipboard because another process may own it.
5. Treat clipboard access failure as a recoverable user-visible error.

Acceptance criteria:

- Unit tests cover service behavior with fake clipboard.
- Manual smoke test can read/write/restore text clipboard.
- Clipboard errors do not crash the app.

Future rich-preservation investigation:

- Explore multi-format snapshot/restore only after alpha data shows it is needed.
- If attempted, include size/time limits and fail-safe fallback to avoid stalls similar to the macOS rich clipboard issue.

### Phase 7 — Keyboard input and foreground window adapters

Goal: copy from and paste into the original foreground app without silently mutating the wrong target.

Steps:

1. Capture the foreground window before clicking/transformation.
2. Capture metadata for diagnostics:
   - window handle;
   - process ID/name;
   - window title if available.
3. Send Ctrl+C through `SendInput`.
4. Wait for clipboard sequence change or timeout.
5. Reactivate/focus the captured window before paste.
6. Send Ctrl+V through `SendInput`.
7. Wait before restoring clipboard, using a conservative default modeled after macOS:
   - initial default: 2.0 seconds;
   - configurable internally through env var or settings, e.g. `RTLER_PASTE_RESTORE_DELAY`.

Windows-specific constraints to handle/document:

- UIPI blocks lower-integrity processes from sending input to elevated/admin apps.
- Secure desktop, UAC prompts, lock screen, and some remote desktop contexts may block automation.
- `SetForegroundWindow` can fail due to Windows foreground activation rules.
- Some apps ignore synthetic paste or handle copy/paste asynchronously.

Acceptance criteria:

- Text selected in Notepad can be copied and pasted via service.
- Existing clipboard plain text is restored after selected-text replacement.
- If the target cannot be controlled, the app fails visibly and safely.

### Phase 8 — Selection replacement service

Goal: implement the Mac-equivalent copy/transform/paste workflow in testable C# code.

Algorithm:

1. Check control capability for the current foreground target.
2. Snapshot original clipboard.
3. Record initial clipboard sequence/version.
4. Send copy.
5. Poll for clipboard change up to a short timeout, initially 0.50s.
6. Read copied text.
7. Determine whether a selected text copy was produced:
   - clipboard changed; or
   - copied text differs from original clipboard text;
   - later harden selected-text-identical-to-clipboard cases with manual data.
8. If selected text exists:
   - transform through `ITextTransformer`;
   - put transformed text on clipboard;
   - reactivate original foreground window;
   - send paste;
   - wait paste restore delay;
   - restore original clipboard text;
   - return `SelectionReplaced`.
9. If no selected text exists:
   - if original clipboard contains Arabic-script text, transform clipboard in place and return `ClipboardTransformed`;
   - otherwise restore original clipboard and return/throw `NoSelectedText`.
10. On transform failure or control failure:
   - restore clipboard when possible;
   - do not paste.

Service unit tests to port from macOS:

- selected text is replaced and original clipboard is restored;
- no selection + Arabic clipboard transforms clipboard in place;
- no selection + non-Arabic clipboard restores and reports `NoSelectedText`;
- missing control capability sends no keyboard events and does not mutate clipboard;
- transform failure restores clipboard and reports failure;
- clipboard open/read/write failure fails safely;
- paste restore delay is configurable and non-negative;
- Arabic-script detection covers the same Unicode ranges as macOS.

Acceptance criteria:

- Fake-backed service tests pass.
- UI calls only the service and renders outcome/error states.
- No service logic depends on WPF controls.

### Phase 9 — First real replacement slice

Goal: replace selected text in a basic Windows app.

Manual target apps for the first slice:

1. Notepad
2. Windows Run dialog or a simple native text field
3. Browser text field in Edge or Chrome

Test cases:

- Arabic sentence: `سلام`
- mixed Arabic + English URL/email
- Urdu sentence
- Persian sentence
- no selection with non-Arabic clipboard
- no selection with Arabic clipboard fallback
- original clipboard text identical to selection

Acceptance criteria:

- Notepad selected text replacement works reliably.
- Browser text field replacement works at least in one mainstream browser.
- Clipboard fallback works.
- Failures show feedback and preserve clipboard text.

### Phase 10 — Windows hardening and compatibility matrix

Goal: make behavior reliable enough for private alpha.

Create a manual QA matrix in the app README or a docs file:

| App | Selected text replacement | Clipboard fallback | Notes |
| --- | --- | --- | --- |
| Notepad | TBD | TBD | baseline native edit control |
| WordPad or rich text equivalent if available | TBD | TBD | rich text caveats |
| Microsoft Word | TBD | TBD | Office async paste timing |
| Edge text field | TBD | TBD | browser baseline |
| Chrome text field | TBD | TBD | browser baseline |
| VS Code | TBD | TBD | editor surface |
| Affinity/Adobe/design tool | TBD | TBD | target workflow class |
| Terminal/Windows Terminal | TBD | TBD | selection/copy semantics differ |
| Elevated Notepad/admin app | expected limited/fail | TBD | UIPI/elevation behavior |
| Remote Desktop/VM | TBD | TBD | timing/input caveats |

Hardening tasks:

1. Tune copy timeout and paste restore delay based on matrix data.
2. Add retries around clipboard open failures.
3. Add clearer error messages for:
   - target app could not be controlled;
   - clipboard unavailable;
   - no selection/Arabic clipboard text;
   - target likely rejected paste;
   - transform failed.
4. Decide whether to add a global hotkey after real testing.

Recommendation:

- Do not add a global hotkey for the first implementation slice.
- Add it only if clicking the floating button frequently disrupts selection despite focus restoration.

### Phase 11 — Branding and Windows resources

Goal: give Windows artifacts the same RTLer identity as macOS.

Steps:

1. Generate Windows `.ico` from `assets/logo/rtler-logo.svg`.
2. Include app icon in WPF executable metadata.
3. Include tray icon sizes suitable for Windows notification area.
4. Add version metadata:
   - product name: `RTLer`;
   - description: Arabic-script visual compatibility text transformer;
   - company/author metadata;
   - version aligned with release plan.
5. Ensure high-DPI icon quality.

Acceptance criteria:

- Executable, tray, and window visuals use the RTLer logo.
- Artifact properties show correct version/name.

### Phase 12 — Packaging

Goal: produce a downloadable private-alpha Windows artifact without requiring the user to build from source.

Initial artifact:

```text
dist/
└── RTLer-<version>-windows-x64.zip
    ├── RTLer.Windows.exe
    ├── rtler.dll
    ├── README.txt or link to README
    ├── LICENSE
    └── any required .NET/runtime files if self-contained
```

Build script plan:

- `scripts/build-windows-floating-app.ps1` for Windows-native builds.
- Optional shell wrapper later if useful.

Script responsibilities:

1. Build Rust in release mode.
2. Build/publish WPF app in release mode.
3. Copy `rtler.dll` into publish output.
4. Copy license/readme/icon resources.
5. Create a versioned zip under `dist/`.
6. Optionally create checksum file.

Packaging choices:

- Private alpha: self-contained portable zip preferred.
- Public beta: decide between signed portable zip, MSI, MSIX, or winget-compatible installer later.

Acceptance criteria:

- Clean Windows checkout can produce the zip with one command.
- Unzipped app launches on a machine without a repo checkout.
- App can transform text in Notepad from the packaged location.

### Phase 13 — CI

Goal: avoid repeating the macOS gap where native app tests are not covered by CI.

Add CI incrementally:

1. Keep existing Ubuntu Rust job unchanged.
2. Add a `windows-latest` job:
   - checkout;
   - install stable Rust;
   - setup .NET SDK;
   - `cargo test`;
   - `cargo clippy --all-targets --all-features -- -D warnings` if clippy is available/fast enough;
   - build Rust release library;
   - build .NET solution;
   - run .NET unit tests;
   - optionally run packaging script without signing.
3. Add a macOS Swift job later if desired, since the current CI also does not cover `apps/macos-floating`.

Acceptance criteria:

- Pull requests fail if Windows app service tests or build break.
- Windows package script has at least a smoke build path in CI.

### Phase 14 — Documentation

Goal: make Windows alpha understandable and safe for testers.

Docs to add/update:

- `apps/windows-floating/README.md`
- root `README.md` once a Windows build is shippable
- release notes for the Windows alpha/beta
- troubleshooting section

Windows README should include:

1. What RTLer does and the compatibility-text caveat.
2. Install/unzip/run steps.
3. How to use the floating button.
4. How tray actions work.
5. Clipboard fallback explanation.
6. Known limitations:
   - clipboard-mediated Ctrl+C/Ctrl+V automation;
   - plain-text replacement;
   - plain-text clipboard preservation only in alpha;
   - elevated/admin apps may not be controllable;
   - some apps reject synthetic input;
   - timing may vary by app.
7. Troubleshooting:
   - nothing changed;
   - button shows warning/error;
   - clipboard transformed instead of selection;
   - app is elevated;
   - antivirus/SmartScreen warning for unsigned alpha;
   - how to quit/reset/show the floating button.
8. Manual QA matrix and known app results.

Acceptance criteria:

- A non-technical tester can install, run, quit, and understand limitations.
- No known destructive clipboard limitation is hidden.

### Phase 15 — Signing and security posture

Goal: decide how far to go before public beta.

Private alpha:

- Unsigned or self-signed portable zip is acceptable if testers are warned.
- Document SmartScreen/Gatekeeper-equivalent warning expectations.

Public beta:

- Prefer code signing if available.
- Decide whether an installer is needed.
- Publish checksums.
- Avoid committing signing credentials or secrets.

Security/privacy messaging:

- RTLer sends copy/paste shortcuts only when user clicks the button or tray action.
- It does not record keystrokes.
- It reads clipboard contents only to perform the requested transform/fallback.
- It does not send text to a network service.

Acceptance criteria:

- Release notes clearly state signing status.
- Build scripts work without secrets and optionally support signing via environment/config.

### Phase 16 — Release process

Goal: publish a Windows prerelease only after the artifact is validated.

Recommended sequence:

1. Finish implementation on `experiment/windows-floating-button`.
2. Run local Windows validation:
   - Rust tests;
   - .NET tests;
   - package build;
   - manual QA matrix.
3. Merge to `main` with a conventional commit.
4. Create a new prerelease tag, e.g. `v0.1.0-beta.2` or `v0.1.0-windows-alpha.1`, depending on desired release semantics.
5. Upload:
   - Windows zip;
   - checksum;
   - release notes;
   - known limitations.
6. Do not move existing `v0.1.0-beta.1`.

Lessons from macOS release:

- The macOS beta tag points to the merge commit and later docs/CI fixes were committed afterward.
- For Windows, aim to complete docs and CI fixes before tagging the release artifact.

## Definition of done — Windows private alpha

- Packaged zip launches outside the repo checkout.
- Floating button is draggable, topmost, position-persistent, and recoverable via tray reset.
- Tray menu supports show/hide/reset/transform clipboard/about/quit.
- Notepad selected-text replacement works.
- At least one browser text field works.
- Clipboard fallback works.
- Original plain-text clipboard is restored after selection replacement.
- Missing/blocked control capability fails visibly and safely.
- Service behavior is covered by fake-backed unit tests.
- Rust FFI bridge is tested from C#.
- Windows build/test job exists in CI.
- README documents usage, limitations, troubleshooting, and signing status.

## Definition of done — Windows public beta

Everything in private alpha, plus:

- Compatibility matrix completed for target apps.
- No known silent clipboard/data-loss path remains undocumented.
- Packaging has versioned artifact name, checksum, and release notes.
- Signing/SmartScreen posture is explicitly decided and documented.
- App version metadata and icon resources are polished.
- Release artifact is attached to a GitHub prerelease.

## Known risks and mitigations

### Floating button click may steal focus or selection

Mitigations:

- Capture foreground window before handling click when possible.
- Use non-activating/topmost window techniques where practical.
- Restore foreground window before sending copy/paste.
- Consider a global hotkey only if click-based operation proves unreliable.

### Elevated/admin apps cannot be controlled from unelevated RTLer

Mitigations:

- Detect elevated target processes when possible.
- Show a clear limitation message.
- Do not auto-elevate by default; it creates security and UX concerns.
- Consider a separate elevated mode only after alpha evidence.

### Clipboard access races

Mitigations:

- Retry/backoff around clipboard open/read/write.
- Keep operations short.
- Restore original text whenever possible.
- Make failures user-visible.

### Paste may consume clipboard slowly

Mitigations:

- Use conservative paste restore delay, initially 2.0s.
- Make delay configurable internally.
- Tune from manual QA data.

### Rich clipboard data may be lost

Mitigations:

- Plain-text preservation only for alpha, matching macOS beta.
- Document clearly.
- Investigate rich preservation later with strict time/size limits.

### Antivirus/SmartScreen warnings

Mitigations:

- Explain unsigned alpha status.
- Publish checksums.
- Add signing before broader public beta if possible.

## Recommended first implementation slices

1. Windows branch + committed plan.
2. Windows Rust FFI build validation.
3. C# solution skeleton + service interfaces.
4. FFI bridge test.
5. Minimal WPF floating button + tray quit/reset.
6. Fake-backed service tests.
7. Real clipboard + `SendInput` adapters.
8. Notepad replacement success.
9. Clipboard fallback and feedback states.
10. Packaging zip.
11. Windows CI.
12. README/manual QA/release notes.

## Explicit non-goals for the first Windows alpha

- Full rich clipboard preservation.
- App Store/Microsoft Store distribution.
- Auto-update.
- OCR or screenshot-based insertion.
- Per-app accessibility/UI Automation insertion paths.
- Full preferences UI.
- Linux support.
- Rewriting the Rust transform algorithm.
