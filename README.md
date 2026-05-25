# RTLER

RTLER converts logical-order Arabic-script text into visual-order, pre-shaped Unicode compatibility text for tools that do not support RTL layout or Arabic shaping.

It is useful for pasting Arabic, Urdu, or Persian text into Affinity-like design tools where normal RTL text appears disconnected or reversed.

## Important caveat

RTLER output is **visual compatibility text**, not semantically clean Unicode. Keep your original source text. The transformed output is intended for display in non-RTL/non-shaping environments, not editing, searching, spellchecking, or linguistic processing.

RTLER does not provide Nastaliq-faithful Urdu typography or HarfBuzz/vector shaping yet.

## Build

```bash
cargo build --release
```

## CLI usage

```bash
rtler "سلام"
echo "هذا نص عربي" | rtler
rtler --help
rtler --version
```

Warnings for unsupported Arabic-script characters are printed to stderr. Transformed text is printed to stdout.

## Library usage

```rust
let result = rtler::transform("سلام");
assert_eq!(result.output, "ﻡﻼﺳ");
assert!(result.warnings.is_empty());
```

## Fixture checks

```bash
cargo run --quiet < fixtures/arabic-smoke-input.txt | diff -u fixtures/arabic-smoke-expected.txt -
cargo run --quiet < fixtures/mixed-arabic-smoke-input.txt | diff -u fixtures/mixed-arabic-smoke-expected.txt -
cargo run --quiet < fixtures/urdu-smoke-input.txt | diff -u fixtures/urdu-smoke-expected.txt -
cargo run --quiet < fixtures/persian-smoke-input.txt | diff -u fixtures/persian-smoke-expected.txt -
```

## Development checks

```bash
cargo fmt -- --check
cargo test
cargo clippy --all-targets --all-features -- -D warnings
```
