use std::ffi::{CStr, CString};

#[test]
fn ffi_transforms_utf8_text() {
    let input = CString::new("سلام").unwrap();

    let output = rtler::rtler_transform_text(input.as_ptr());

    assert!(!output.is_null());
    let output_text = unsafe { CStr::from_ptr(output).to_str().unwrap().to_owned() };
    rtler::rtler_free_string(output);

    assert_eq!(output_text, "ﻡﻼﺳ");
}

#[test]
fn ffi_returns_null_for_null_input() {
    let output = rtler::rtler_transform_text(std::ptr::null());

    assert!(output.is_null());
}
