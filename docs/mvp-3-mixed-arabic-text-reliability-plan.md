# MVP 3 Plan: Mixed Arabic Text Reliability

## Goal

Make RTLER reliable for common Arabic text that contains LTR tokens such as English words, URLs, emails, versions, filenames, dates, and prices.

The output remains a visual-order, presentation-form compatibility string for non-RTL/non-shaping environments.

## Scope

### In scope

- Preserve existing Arabic-only behavior from MVP 2.
- Keep obvious LTR token runs intact while reversing surrounding Arabic text.
- Support common LTR token categories:
  - ASCII words and product names
  - URLs
  - email addresses
  - usernames/handles and hashtags
  - versions such as `v1.2.3`
  - filenames such as `guide-v1.pdf`
  - existing numeric/date/price runs
- Add golden fixtures for mixed Arabic/LTR sentences.
- Keep CLI/library API stable.

### Out of scope

- Full general-purpose Unicode Bidirectional Algorithm correctness for every script and embedding control.
- Rich text, font shaping, HarfBuzz/vector fallback.
- GUI.

## TDD slices

Follow vertical slices: one failing behavior test, minimal implementation, then refactor while green.

### Slice 1 — ASCII word runs

Behavior: ASCII word/product runs keep left-to-right character order inside Arabic text.

Examples:

- `Adobe يدعم العربية` → `ﺔﻴﺑﺮﻌﻟﺍ ﻢﻋﺪﻳ Adobe`
- `RTLER متاح الآن` → `ﻥﻵﺍ ﺡﺎﺘﻣ RTLER`

### Slice 2 — URL and email runs

Behavior: URL and email tokens are preserved intact.

Examples:

- `زر https://example.com الآن`
- `راسل test@example.com الآن`

### Slice 3 — handles, hashtags, filenames, versions

Behavior: common technical tokens remain intact.

Examples:

- `تابع @rtler و #Arabic`
- `افتح guide-v1.2.pdf الآن`

### Slice 4 — fixture file

Add `fixtures/mixed-arabic-smoke-input.txt` and expected output with a test that compares the fixture.

## Done criteria

- `cargo test` passes.
- `cargo fmt -- --check` passes.
- `cargo clippy --all-targets --all-features -- -D warnings` passes.
- Existing Arabic-only fixture remains green.
- Mixed Arabic fixture emits no warnings.
