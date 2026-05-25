use rtler::transform;

#[test]
fn shapes_and_reverses_a_pure_arabic_word() {
    let result = transform("سلام");

    assert_eq!(result.output, "ﻡﻼﺳ");
    assert!(result.warnings.is_empty());
}
