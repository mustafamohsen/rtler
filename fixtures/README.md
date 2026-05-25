# Arabic Smoke Fixture

This fixture is a manual visual QA sample for Affinity-like tools that do not support RTL layout or Arabic shaping.

## Regenerate expected output

```bash
cargo run --quiet < fixtures/arabic-smoke-input.txt > /tmp/rtler-output.txt
diff -u fixtures/arabic-smoke-expected.txt /tmp/rtler-output.txt
```

## Manual visual check

1. Open `fixtures/arabic-smoke-input.txt` in an RTL-capable editor or browser.
2. Generate RTLER output with the command above.
3. Paste the generated output into the non-RTL/non-shaping target tool.
4. Compare visual reading order and joining against the RTL-capable rendering.

Known limitation: this is a presentation-form text workaround. It is not semantically clean Unicode and does not guarantee font-specific mark placement or typographic fidelity.
