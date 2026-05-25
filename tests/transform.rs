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
fn preserves_digit_runs_in_left_to_right_order() {
    let result = transform("سلام 123");

    assert_eq!(result.output, "123 ﻡﻼﺳ");
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
