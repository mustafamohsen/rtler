# RTLer

[![CI](https://github.com/mustafamohsen/rtler/actions/workflows/ci.yml/badge.svg)](https://github.com/mustafamohsen/rtler/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/mustafamohsen/rtler?include_prereleases&label=release)](https://github.com/mustafamohsen/rtler/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Rust](https://img.shields.io/badge/core-Rust-orange.svg)
![macOS beta](https://img.shields.io/badge/macOS-beta-111827.svg)
![Arabic script](https://img.shields.io/badge/script-Arabic%20%7C%20Urdu%20%7C%20Persian-38BDF8.svg)

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ar.md">العربية</a> ·
  <a href="README.ur.md">اُردو</a>
</p>

RTLer converts Arabic-script text from normal logical Unicode into visual-order, pre-shaped compatibility text for apps that do not properly support right-to-left layout or Arabic shaping.

It is intended for design and publishing workflows where Arabic, Urdu, or Persian text appears disconnected, reversed, or otherwise broken after pasting into the target app.

## What it does

- Shapes Arabic-script letters into Unicode presentation forms.
- Reorders text for visual right-to-left display.
- Preserves common left-to-right runs such as URLs, emails, numbers, and filenames.
- Supports Arabic, Persian, and Urdu core text cases.
- Provides both a Rust CLI/library and an experimental macOS app.

## Important caveat

RTLer output is **visual compatibility text**. It is meant to look correct in apps with poor RTL support, not to remain semantically clean Unicode.

Keep your original source text. The transformed output is not ideal for editing, searching, spellchecking, accessibility, or linguistic processing.

## macOS app beta

The macOS beta provides a small floating button for transforming selected text in the frontmost app.

Download the latest beta from GitHub Releases, unzip `RTLer.app`, open it, and grant Accessibility permission when prompted.

The app uses clipboard-mediated copy/paste automation, so behavior may vary by target application. Clipboard preservation currently targets plain text.

## CLI usage

Build from source:

```bash
cargo build --release
```

Run examples:

```bash
cargo run -- "سلام"
echo "هذا نص عربي" | cargo run --quiet
cargo run -- --help
```

If installed as `rtler`:

```bash
rtler "سلام"
echo "هذا نص عربي" | rtler
```

Warnings are printed to stderr. Transformed text is printed to stdout.

## Rust library usage

```rust
let result = rtler::transform("سلام");
assert_eq!(result.output, "ﻡﻼﺳ");
assert!(result.warnings.is_empty());
```

## Development

```bash
cargo fmt -- --check
cargo test
cargo clippy --all-targets --all-features -- -D warnings
```

Fixture checks:

```bash
cargo run --quiet < fixtures/arabic-smoke-input.txt | diff -u fixtures/arabic-smoke-expected.txt -
cargo run --quiet < fixtures/mixed-arabic-smoke-input.txt | diff -u fixtures/mixed-arabic-smoke-expected.txt -
cargo run --quiet < fixtures/urdu-smoke-input.txt | diff -u fixtures/urdu-smoke-expected.txt -
cargo run --quiet < fixtures/persian-smoke-input.txt | diff -u fixtures/persian-smoke-expected.txt -
```

## Project status

RTLer is in beta. The core transform is covered by automated tests, and the macOS app is available as an experimental beta for real-world testing in design tools.

See `DESIGN.md` for implementation notes and tradeoffs.
