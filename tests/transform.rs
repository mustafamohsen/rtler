use rtler::transform;

#[test]
fn shapes_and_reverses_a_pure_arabic_word() {
    let result = transform("سلام");

    assert_eq!(result.output, "ﻡﻼﺳ");
    assert!(result.warnings.is_empty());
}

#[test]
fn covers_common_arabic_letters_in_real_sentence() {
    let result = transform("هذا ليس من شأنك! اذهب في كتبك الآن! لنْ نَلين");

    assert_eq!(
        result.output,
        "ﻦﻴﻠﻧَ ﻦْﻟ !ﻥﻵﺍ ﻚﺒﺘﻛ ﻲﻓ ﺐﻫﺫﺍ !ﻚﻧﺄﺷ ﻦﻣ ﺲﻴﻟ ﺍﺬﻫ"
    );
    assert!(result.warnings.is_empty());
}

#[test]
fn covers_comprehensive_arabic_smoke_string() {
    let result = transform(
        "ء آ أ ؤ إ ئ ا ب ة ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ى ي لا لأ لإ لآ 123 (اختبار)",
    );

    assert_eq!(
        result.output,
        "(ﺭﺎﺒﺘﺧﺍ) 123 ﻵ ﻹ ﻷ ﻻ ﻱ ﻯ ﻭ ﻩ ﻥ ﻡ ﻝ ﻙ ﻕ ﻑ ﻍ ﻉ ﻅ ﻁ ﺽ ﺹ ﺵ ﺱ ﺯ ﺭ ﺫ ﺩ ﺥ ﺡ ﺝ ﺙ ﺕ ﺓ ﺏ ﺍ ﺉ ﺇ ﺅ ﺃ ﺁ ﺀ"
    );
    assert!(result.warnings.is_empty());
}

#[test]
fn shapes_persian_letters() {
    let result = transform("فارسی");

    assert_eq!(result.output, "ﯽﺳﺭﺎﻓ");
    assert!(result.warnings.is_empty());
}

#[test]
fn shapes_common_urdu_letters() {
    let result = transform("اردو");

    assert_eq!(result.output, "ﻭﺩﺭﺍ");
    assert!(result.warnings.is_empty());
}

#[test]
fn passes_through_unsupported_arabic_script_characters_with_warning() {
    let result = transform("سݨ");

    assert_eq!(result.output, "ݨﺱ");
    assert_eq!(result.warnings.len(), 1);
    assert_eq!(result.warnings[0].character, 'ݨ');
}

#[test]
fn keeps_basic_marks_attached_to_their_base_letters() {
    let result = transform("سَلَام");

    assert_eq!(result.output, "ﻡﻼَﺳَ");
    assert!(result.warnings.is_empty());
}

#[test]
fn handles_arabic_punctuation_without_warnings() {
    let result = transform("هل تكتب؟ نعم، أكتب؛ الآن.");

    assert_eq!(result.output, ".ﻥﻵﺍ ؛ﺐﺘﻛﺃ ،ﻢﻌﻧ ؟ﺐﺘﻜﺗ ﻞﻫ");
    assert!(result.warnings.is_empty());
}

#[test]
fn preserves_digit_runs_in_left_to_right_order() {
    let result = transform("سلام 123");

    assert_eq!(result.output, "123 ﻡﻼﺳ");
    assert!(result.warnings.is_empty());
}

#[test]
fn preserves_common_numeric_runs_in_arabic_text() {
    let result = transform("السعر ١٢٫٥٠ والخصم 50% في 2026/05/25");

    assert_eq!(result.output, "2026/05/25 ﻲﻓ 50% ﻢﺼﺨﻟﺍﻭ ١٢٫٥٠ ﺮﻌﺴﻟﺍ");
    assert!(result.warnings.is_empty());
}

#[test]
fn mirrors_paired_brackets_when_reordering() {
    let result = transform("(سلام)");

    assert_eq!(result.output, "(ﻡﻼﺳ)");
    assert!(result.warnings.is_empty());
}

#[test]
fn transforms_each_explicit_line_independently() {
    let result = transform("سلام\nسم");

    assert_eq!(result.output, "ﻡﻼﺳ\nﻢﺳ");
    assert!(result.warnings.is_empty());
}

#[test]
fn emits_lam_alef_ligatures_for_common_alef_variants() {
    assert_eq!(transform("لا").output, "ﻻ");
    assert_eq!(transform("لأ").output, "ﻷ");
    assert_eq!(transform("لإ").output, "ﻹ");
    assert_eq!(transform("لآ").output, "ﻵ");
}
