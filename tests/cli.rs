use std::io::Write;
use std::process::{Command, Stdio};

#[test]
fn cli_transforms_direct_text_argument_to_stdout() {
    let output = Command::new(env!("CARGO_BIN_EXE_rtler"))
        .arg("سلام")
        .output()
        .expect("run rtler");

    assert!(output.status.success());
    assert_eq!(String::from_utf8(output.stdout).unwrap(), "ﻡﻼﺳ\n");
    assert_eq!(String::from_utf8(output.stderr).unwrap(), "");
}

#[test]
fn cli_transforms_stdin_to_stdout() {
    let mut child = Command::new(env!("CARGO_BIN_EXE_rtler"))
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("spawn rtler");

    child
        .stdin
        .as_mut()
        .expect("stdin")
        .write_all("سلام".as_bytes())
        .expect("write stdin");

    let output = child.wait_with_output().expect("wait");

    assert!(output.status.success());
    assert_eq!(String::from_utf8(output.stdout).unwrap(), "ﻡﻼﺳ");
    assert_eq!(String::from_utf8(output.stderr).unwrap(), "");
}
