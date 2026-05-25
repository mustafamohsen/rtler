# MVP 5 Plan: Persian Core Reliability

## Goal

Make RTLER reliably produce readable connected compatibility text for common Persian prose.

Persian comes after Urdu in project priority, but should be easier because RTLER already supports many Persian letters and Persian shaping expectations are closer to standard Arabic-script joining than Urdu/Nastaliq.

## Scope

### In scope

- Persian-specific letters and variants:
  - `پ`
  - `چ`
  - `ژ`
  - `ک`
  - `گ`
  - `ی`
- Persian digits:
  - `۰۱۲۳۴۵۶۷۸۹`
- Persian punctuation and spacing patterns.
- Persian ezafe/zero-width joiner cases only where they appear in ordinary fixtures.
- Golden fixtures for common Persian prose.
- No warnings for normal Persian fixture text.

### Out of scope

- Full Unicode bidi support beyond MVP 3 token preservation.
- Advanced typography or font-specific mark placement.
- HarfBuzz/vector fallback.
- Complex orthographic normalization beyond conservative presentation-form normalization.

## Public interface

Keep the existing API stable:

```rust
pub fn transform(input: &str) -> TransformResult
```

Keep CLI behavior unchanged.

## TDD slices

Follow vertical slices: one failing behavior test, minimal implementation, then refactor while green.

### Slice 1 — Persian character coverage

Behavior: Persian-specific letters shape without warnings.

Target letters:

- `پ`
- `چ`
- `ژ`
- `ک`
- `گ`
- `ی`

Tests:

- Table-driven isolated examples.
- Representative joining examples where applicable.

Acceptance:

- No warnings for supported Persian-specific letters.
- Existing Arabic and Urdu tests remain green.

### Slice 2 — Persian digits and numeric runs

Behavior: Persian digit runs preserve character identity and left-to-right order.

Examples:

- `۱۲۳۴۵۶۷۸۹۰`
- `۱۴۰۳/۰۲/۰۶`
- `۱۲٫۵۰`
- `۵۰٪`

Acceptance:

- Golden outputs pass.
- Persian digits are not converted to Arabic-Indic or Latin digits.
- Digit order remains intact.

### Slice 3 — common Persian words

Behavior: common Persian words shape and visually reorder consistently.

Candidate fixtures:

- `فارسی`
- `سلام`
- `دنیا`
- `کتاب`
- `ایران`
- `پژوهش`
- `چگونه`

Acceptance:

- Golden outputs pass.
- No warnings.

### Slice 4 — common Persian sentences

Behavior: ordinary Persian prose produces stable output.

Candidate fixtures:

- `سلام دنیا`
- `این یک متن فارسی است.`
- `کتاب‌ها روی میز هستند.`
- `قیمت ۱۲٫۵۰ است.`
- `نسخه v1.0 آماده است.`

Acceptance:

- Golden outputs pass.
- No warnings for ordinary Persian prose.
- Mixed token behavior from MVP 3 remains intact.

### Slice 5 — Persian smoke fixture

Add:

- `fixtures/persian-smoke-input.txt`
- `fixtures/persian-smoke-expected.txt`

Update:

- `fixtures/README.md`

Acceptance:

- Fixture diff passes:

```bash
cargo run --quiet < fixtures/persian-smoke-input.txt | diff -u fixtures/persian-smoke-expected.txt -
```

## Done criteria

MVP 5 is done when:

- `cargo test` passes.
- `cargo fmt -- --check` passes.
- `cargo clippy --all-targets --all-features -- -D warnings` passes.
- Persian smoke fixture diff passes.
- No warnings are emitted for ordinary Persian fixture text.
- Arabic, mixed Arabic, and Urdu fixtures remain green.

## Known caveat to document

RTLER preserves Persian digits and text as compatibility output. It does not produce semantically clean logical-order Unicode after transformation, and it does not guarantee typography beyond readable connected text.
