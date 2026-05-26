# RTLer

<p align="center">
  <img src="assets/logo/rtler-logo.svg" alt="RTLer logo" width="112" height="112">
</p>

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

RTLer is a small tool for the annoying cases where Arabic-script text breaks after you paste it into a design or publishing app.

It takes normal Unicode text and turns it into visual-order, pre-shaped compatibility text. In plain English: if the target app refuses to handle right-to-left layout or Arabic shaping properly, RTLer gives you text that is more likely to look right anyway.

It works with Arabic, Urdu, and Persian.

## When to use it

Use RTLer when your text shows up reversed, disconnected, or scrambled in the app you actually need to use.

Typical cases:

- Posters, social graphics, and presentation slides.
- Design tools with weak RTL support.
- Publishing workflows where the final output matters more than editable source text.
- Mixed Arabic-script text with URLs, emails, numbers, or filenames.

## What it does

- Shapes Arabic-script letters into Unicode presentation forms.
- Reorders text for visual right-to-left display.
- Leaves common left-to-right runs, such as URLs and emails, in a usable order.
- Handles the core Arabic, Persian, and Urdu cases covered by the test suite.
- Ships as a Rust CLI/library, with a beta macOS app for selected-text workflows.

## Keep the original text

RTLer output is meant for compatibility, not clean editing.

Keep a copy of your original text somewhere safe. The transformed version may look right, but it is not what you want for search, spellcheck, screen readers, linguistic processing, or later editing.

Think of RTLer output as paste-ready artwork text, not your source of truth.

## macOS app beta

The macOS beta adds a small floating button. Select text in another app, click the button, and RTLer replaces the selection with the transformed version.

To try it:

1. Download the latest beta from GitHub Releases.
2. Unzip `RTLer.app`.
3. Open it.
4. Grant Accessibility permission when macOS asks.

The app uses the clipboard to copy and paste the selected text. That makes it work across many apps, but it also means some apps will behave differently. Clipboard preservation currently focuses on plain text.

## CLI usage

Build from source:

```bash
cargo build --release
```

Run a few examples:

```bash
cargo run -- "سلام"
echo "هذا نص عربي" | cargo run --quiet
cargo run -- --help
```

If you have installed it as `rtler`:

```bash
rtler "سلام"
echo "هذا نص عربي" | rtler
```

Warnings go to stderr. The transformed text goes to stdout.

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

RTLer is beta software. The Rust transform has automated test coverage. The macOS app is still experimental and needs real use in design tools to shake out rough edges.

See `DESIGN.md` for implementation notes and tradeoffs.
