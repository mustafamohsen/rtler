# MVP 4 Plan: Urdu Core Reliability

## Goal

Make RTLER reliably produce readable connected compatibility text for common Urdu prose.

The goal is **readability in non-RTL/non-shaping environments**, not Nastaliq-faithful typography. Output remains visual-order Unicode text using Arabic Presentation Forms where possible.

## Priority

Urdu is the next priority after Arabic because the project priority order is:

1. Arabic
2. Urdu
3. Persian

## Scope

### In scope

- Common Urdu letters and variants.
- Urdu-specific joining behavior where Unicode presentation forms exist.
- Aspirated letter sequences using `ھ`.
- Urdu punctuation and Arabic-script marks already handled by the Arabic core.
- Urdu digits/numeric runs where they overlap existing numeric handling.
- Golden fixtures for ordinary Urdu prose.
- No warnings for normal Urdu fixture text.

### Out of scope

- Nastaliq-quality typography.
- Font-specific mark placement.
- HarfBuzz/vector fallback.
- Full mixed Urdu/English bidi correctness beyond the token-preservation behavior from MVP 3.

## Public interface

Keep the existing API stable:

```rust
pub fn transform(input: &str) -> TransformResult
```

Keep CLI behavior unchanged.

## TDD slices

Follow vertical slices: one failing behavior test, minimal implementation, then refactor while green.

### Slice 1 — Urdu character coverage

Behavior: common Urdu-specific characters shape without warnings.

Target characters:

- `ٹ`
- `ڈ`
- `ڑ`
- `ں`
- `ہ`
- `ھ`
- `ے`
- `ۓ`
- common shared letters used in Urdu words

Tests:

- Table-driven smoke tests for isolated examples.
- Representative joining examples for dual-joining characters.

Acceptance:

- No warnings for supported Urdu characters.
- Existing Arabic tests remain green.

### Slice 2 — common Urdu words

Behavior: common Urdu words shape and visually reorder consistently.

Candidate fixtures:

- `اردو`
- `پاکستان`
- `کتاب`
- `کتابیں`
- `میں`
- `ہے`
- `ہیں`

Acceptance:

- Golden outputs pass.
- No warnings.

### Slice 3 — common Urdu sentences

Behavior: ordinary Urdu prose produces stable output.

Candidate fixtures:

- `یہ ایک اردو جملہ ہے`
- `میں نے کتاب پڑھی`
- `آپ کیسے ہیں؟`
- `پاکستان میں اردو بولی جاتی ہے۔`

Acceptance:

- Golden outputs pass.
- No warnings.

### Slice 4 — aspirated sequences

Behavior: common aspirated sequences preserve readable connected order.

Candidate examples:

- `بھ`
- `پھ`
- `تھ`
- `ٹھ`
- `جھ`
- `چھ`
- `دھ`
- `ڈھ`
- `کھ`
- `گھ`

Acceptance:

- Golden outputs pass.
- No warnings.

### Slice 5 — Urdu smoke fixture

Add:

- `fixtures/urdu-smoke-input.txt`
- `fixtures/urdu-smoke-expected.txt`

Update:

- `fixtures/README.md`

Acceptance:

- Fixture diff passes:

```bash
cargo run --quiet < fixtures/urdu-smoke-input.txt | diff -u fixtures/urdu-smoke-expected.txt -
```

## Done criteria

MVP 4 is done when:

- `cargo test` passes.
- `cargo fmt -- --check` passes.
- `cargo clippy --all-targets --all-features -- -D warnings` passes.
- Urdu smoke fixture diff passes.
- No warnings are emitted for ordinary Urdu fixture text.
- Arabic and mixed Arabic fixtures remain green.

## Known caveat to document

RTLER's Urdu mode is a plain-text compatibility workaround. It does not produce Nastaliq-faithful glyph positioning or calligraphy. High-fidelity Urdu output remains a future HarfBuzz/vector fallback concern.
