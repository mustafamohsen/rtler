# MVP 6 Plan: CLI and Package Readiness

## Goal

Prepare RTLER for practical use outside the development repo: documented CLI behavior, installation guidance, CI checks, release packaging, and clear caveats.

This MVP should happen after Arabic, Urdu, Persian, and mixed Arabic reliability work has enough fixture coverage.

## Scope

### In scope

- CLI help/version polish.
- README usage documentation.
- Installation instructions.
- CI for formatting, tests, clippy, and fixture diffs.
- Release packaging strategy.
- Documented limitations and workflow guidance for design tools.
- Optional strict/warning behavior if it remains useful.

### Out of scope

- GUI or web app.
- HarfBuzz/vector fallback.
- Full package manager publishing if release binaries are enough for the first public cut.
- Major public API changes.

## Public interface

Keep the library API stable unless a small additive change is clearly needed:

```rust
pub fn transform(input: &str) -> TransformResult
```

CLI should remain:

```bash
rtler "..."
echo "..." | rtler
```

## TDD / test-first slices

Use tests where practical. For docs and CI, validate with commands rather than only inspection.

### Slice 1 — CLI help and version

Behavior:

- `rtler --help` prints usage.
- `rtler --version` prints package version.
- Existing text argument and stdin behavior remain unchanged.

Tests:

- CLI integration tests for `--help`.
- CLI integration tests for `--version`.
- Regression tests for direct argument and stdin remain green.

Implementation options:

- Keep dependency-free manual arg parsing, or
- Add a small CLI crate such as `clap` if the interface grows.

Acceptance:

- CLI tests pass.

### Slice 2 — warning/strict behavior

Behavior options to decide before implementation:

- Default: warnings to stderr, output still succeeds.
- `--strict`: unsupported Arabic-script characters cause non-zero exit.
- `--quiet` or `--no-warnings`: suppress warnings.

Recommended MVP 6 default:

- Add `--strict` only if unsupported-character warnings are still meaningful after MVPs 4 and 5.
- Avoid `--quiet` unless warning noise becomes a real problem.

Tests:

- Unsupported char exits non-zero in strict mode.
- Default mode remains non-failing.

Acceptance:

- Behavior is documented and tested.

### Slice 3 — README

Add a complete root `README.md` covering:

- What RTLER does.
- Why RTL/non-shaping design tools need this workaround.
- Install/build instructions.
- CLI examples.
- Library API example.
- Before/after examples.
- Fixture/manual QA workflow.
- Limitations:
  - visual compatibility text, not semantic Unicode
  - not a replacement for real RTL support
  - not Nastaliq-faithful
  - no HarfBuzz/vector fallback yet

Acceptance:

- README examples are command-checked where practical.

### Slice 4 — CI

Add GitHub Actions workflow for:

```bash
cargo fmt -- --check
cargo test
cargo clippy --all-targets --all-features -- -D warnings
cargo run --quiet < fixtures/arabic-smoke-input.txt | diff -u fixtures/arabic-smoke-expected.txt -
cargo run --quiet < fixtures/mixed-arabic-smoke-input.txt | diff -u fixtures/mixed-arabic-smoke-expected.txt -
```

After MVPs 4 and 5, include Urdu and Persian fixture diffs too.

Acceptance:

- CI passes on GitHub.

### Slice 5 — release packaging

Decide initial release path:

Recommended first release path:

- GitHub Releases with built binaries for common platforms.
- Keep crates.io publishing as a follow-up unless users need `cargo install rtler`.

Potential targets:

- macOS arm64
- macOS x86_64
- Linux x86_64
- Windows x86_64

Acceptance:

- A documented local release command or CI release workflow exists.

### Slice 6 — project metadata

Review and update:

- `Cargo.toml` description
- license
- repository URL
- keywords/categories
- README reference

Acceptance:

- Package metadata is ready for release.

## Done criteria

MVP 6 is done when:

- `rtler --help` and `rtler --version` work.
- README explains install, CLI, library use, limitations, and design-tool workflow.
- CI runs formatting, tests, clippy, and fixture diffs.
- Release/package metadata is present.
- A release packaging path is documented.
- Existing Arabic, mixed Arabic, Urdu, and Persian fixtures remain green.

## Follow-up after MVP 6

Potential post-MVP 6 work:

1. HarfBuzz/rustybuzz vector fallback.
2. Web UI or tiny desktop UI.
3. Clipboard workflow.
4. Full Unicode Bidirectional Algorithm integration for broader mixed-script text.
5. More language-specific fixture packs.
