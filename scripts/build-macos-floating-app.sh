#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="RTLer"
BUNDLE_NAME="${APP_NAME}.app"
DIST_DIR="${ROOT_DIR}/dist"
APP_DIR="${DIST_DIR}/${BUNDLE_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
FRAMEWORKS_DIR="${CONTENTS_DIR}/Frameworks"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
SWIFT_DIR="${ROOT_DIR}/apps/macos-floating"
CONFIGURATION="${RTLER_BUILD_CONFIGURATION:-debug}"

if [[ "${1:-}" == "--release" || "${1:-}" == "--configuration=release" ]]; then
  CONFIGURATION="release"
fi

if [[ "${CONFIGURATION}" == "release" ]]; then
  CARGO_PROFILE="release"
  SWIFT_CONFIGURATION="release"
  SWIFT_BUILD_DIR="${SWIFT_DIR}/.build/release"
else
  CARGO_PROFILE="debug"
  SWIFT_CONFIGURATION="debug"
  SWIFT_BUILD_DIR="${SWIFT_DIR}/.build/debug"
fi

cd "${ROOT_DIR}"
if [[ "${CARGO_PROFILE}" == "release" ]]; then
  cargo build --release
else
  cargo build
fi

cd "${SWIFT_DIR}"
swift build -c "${SWIFT_CONFIGURATION}"

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${FRAMEWORKS_DIR}" "${RESOURCES_DIR}"
cp "${SWIFT_BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
cp "${SWIFT_DIR}/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"
cp "${SWIFT_DIR}/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
cp "${SWIFT_DIR}/Resources/MenuBarIconTemplate.png" "${RESOURCES_DIR}/MenuBarIconTemplate.png"

RUST_LIB="$(find "${ROOT_DIR}/target/${CARGO_PROFILE}" "${ROOT_DIR}/target/${CARGO_PROFILE}/deps" -maxdepth 1 -name 'librtler.dylib' -print -quit)"
if [[ -z "${RUST_LIB}" ]]; then
  echo "error: librtler.dylib not found under target/${CARGO_PROFILE}" >&2
  exit 1
fi
cp "${RUST_LIB}" "${FRAMEWORKS_DIR}/librtler.dylib"
install_name_tool -id "@executable_path/../Frameworks/librtler.dylib" "${FRAMEWORKS_DIR}/librtler.dylib" || true
LINKED_RUST_LIB="$(otool -L "${MACOS_DIR}/${APP_NAME}" | awk '/librtler\.dylib/ {print $1; exit}')"
if [[ -n "${LINKED_RUST_LIB}" ]]; then
  install_name_tool -change "${LINKED_RUST_LIB}" "@executable_path/../Frameworks/librtler.dylib" "${MACOS_DIR}/${APP_NAME}"
fi

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "${APP_DIR}" >/dev/null
fi

printf 'Built %s\n' "${APP_DIR}"
