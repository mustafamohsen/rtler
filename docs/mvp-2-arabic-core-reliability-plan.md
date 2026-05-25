# MVP 2 Plan: Arabic Core Reliability

## Goal

Make RTLER reliable for common Arabic prose before expanding deeper into Urdu and Persian.

MVP 2 should convert normal logical-order Arabic text into visual-order, presentation-form compatibility text with no warnings for ordinary Arabic input, while preserving the existing CLI/library interface.

## Scope

### In scope

- Common Arabic letters and hamza/alef variants.
- Arabic punctuation and paired bracket behavior.
- Arabic tashkeel/combining marks as order-preserving clusters.
- Numeric runs, including Latin and Arabic-Indic digits.
- Explicit line-by-line transformation.
- Conservative normalization of existing Arabic Presentation Forms back to base letters.
- A broader Arabic fixture suite with golden outputs.
- Manual visual QA fixtures for Affinity-like non-RTL/non-shaping environments.

### Out of scope

- Full mixed LTR/RTL Unicode Bidirectional Algorithm behavior beyond obvious numeric runs.
- HarfBuzz/rustybuzz vector fallback.
- Typographically faithful Quranic mark placement.
- Nastaliq-quality Urdu rendering.
- Browser/desktop GUI.

## Public interface

Keep the existing API stable:

```rust
pub fn transform(input: &str) -> TransformResult
```

```rust
pub struct TransformResult {
    pub output: String,
    pub warnings: Vec<Warning>,
}
```

Keep the existing CLI behavior:

- `rtler "..."` writes transformed text plus a newline to stdout.
- `echo "..." | rtler` transforms stdin to stdout without adding an extra newline.
- warnings go to stderr.

## TDD implementation strategy

Follow vertical slices: one failing behavior test, minimal implementation, then refactor only while green.

### Slice 1 — character coverage table tests

Behavior: every supported Arabic base character has the expected isolated/final/initial/medial presentation forms.

Tests:

- Add table-driven tests for Arabic letters and hamza/alef variants.
- Include joining behavior examples for right-joining and dual-joining letters.

Implementation:

- Refactor the hand-written `forms_for` mapping into a clearer static-style mapping function or table.
- Keep unsupported Arabic-script warning behavior.

Acceptance:

- No warnings for standard Arabic alphabet input.

### Slice 2 — real Arabic prose fixtures

Behavior: common Arabic sentences produce stable visual-order golden output with no warnings.

Tests:

- Modern Standard Arabic prose.
- Sentences with `،`, `؛`, `؟`, `!`, `.`, quotes, parentheses.
- Existing regression sentence from the user remains green.

Implementation:

- Add missing punctuation/bracket handling only when a fixture proves it is needed.

Acceptance:

- Golden fixtures pass.
- No warnings for normal Arabic prose.

### Slice 3 — tashkeel and combining mark fixtures

Behavior: common marks stay attached to their base letters through shaping and reversal.

Tests:

- Fatha, damma, kasra, sukun, shadda, tanween.
- Multi-mark clusters such as shadda + vowel.
- Short fully vocalized words.

Implementation:

- Refine cluster collection if needed.
- Do not attempt font-specific visual mark positioning.

Acceptance:

- Mark order is stable and attached to the intended base cluster.

### Slice 4 — digit and punctuation fixtures

Behavior: numeric runs preserve digit characters and left-to-right order inside Arabic text.

Tests:

- Latin digits: `123`.
- Arabic-Indic digits: `١٢٣`.
- Eastern Arabic/Persian digits: `۱۲۳`.
- Dates/prices: `2026/05/25`, `١٢٫٥٠`, `50%`.

Implementation:

- Extend numeric-run detection only as needed.

Acceptance:

- Digits are not reversed.
- Surrounding Arabic remains visually ordered.

### Slice 5 — conservative normalization

Behavior: already-shaped Arabic Presentation Forms can be accepted and reshaped consistently.

Tests:

- Presentation-form input normalizes back to base forms before transform.
- Normal Arabic input remains unchanged in behavior.

Implementation:

- Add Arabic-presentation-form-to-base normalization for supported characters.
- Avoid full NFKC over the whole input.

Acceptance:

- Already-shaped Arabic does not cause double-shaping surprises.

### Slice 6 — manual visual QA fixtures

Behavior: maintain a repeatable manual smoke test for design tools.

Files:

- `fixtures/arabic-smoke-input.txt`
- `fixtures/arabic-smoke-expected.txt`
- `fixtures/README.md`

Acceptance:

- `cargo run -- < fixtures/arabic-smoke-input.txt` matches expected output.
- README explains how to paste output into Affinity-like tools and compare against RTL-enabled rendering.

## Refactoring opportunities after green tests

- Separate tokenization/clustering, shaping, and visual ordering into small modules.
- Move form mapping data away from transformation control flow.
- Add helper constructors for warnings and form definitions.
- Keep public API unchanged.

## Done criteria

MVP 2 is done when:

- `cargo test` passes.
- No warnings are emitted for the Arabic fixture suite.
- The user-provided real sentence remains green.
- Comprehensive Arabic alphabet and punctuation fixtures are present.
- Manual visual QA fixtures exist.
- Existing CLI/library behavior remains backwards compatible.

## Follow-up after MVP 2

1. Urdu-focused reliability MVP.
2. Persian-focused reliability MVP.
3. Mixed LTR/RTL support using `unicode-bidi`.
4. Optional high-fidelity HarfBuzz/rustybuzz vector fallback.
