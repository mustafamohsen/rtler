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

#[test]
fn cli_prints_help() {
    let output = Command::new(env!("CARGO_BIN_EXE_rtler"))
        .arg("--help")
        .output()
        .expect("run rtler --help");

    assert!(output.status.success());
    let stdout = String::from_utf8(output.stdout).unwrap();
    assert!(stdout.contains("Usage:"));
    assert!(stdout.contains("rtler [TEXT]"));
    assert!(stdout.contains("Developed by Mustafa Mohsen"));
    assert!(stdout.contains("MIT License"));
}

#[test]
fn cli_prints_version() {
    let output = Command::new(env!("CARGO_BIN_EXE_rtler"))
        .arg("--version")
        .output()
        .expect("run rtler --version");

    assert!(output.status.success());
    assert_eq!(String::from_utf8(output.stdout).unwrap(), "rtler 0.1.0\n");
}
