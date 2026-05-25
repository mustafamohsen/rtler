use rtler::transform;

#[test]
fn shapes_and_reverses_a_pure_arabic_word() {
    let result = transform("سلام");

    assert_eq!(result.output, "ﻡﻼﺳ");
    assert!(result.warnings.is_empty());
}

#[test]
fn emits_lam_alef_ligatures_for_common_alef_variants() {
    assert_eq!(transform("لا").output, "ﻻ");
    assert_eq!(transform("لأ").output, "ﻷ");
    assert_eq!(transform("لإ").output, "ﻹ");
    assert_eq!(transform("لآ").output, "ﻵ");
}
