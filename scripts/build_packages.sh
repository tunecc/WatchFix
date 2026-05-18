#!/bin/bash
set -euo pipefail

# Official packaging entry for this repository:
# - rootless: native Theos rootless scheme
# - roothide: native roothide-theos scheme
#
# Local environment workaround support:
# If the active SDK is missing required private framework stubs, this script can
# generate local empty .tbd placeholders and enable dynamic lookup for linking.
# That workaround is only for local compilation on incomplete SDK setups and is
# not part of the formal release packaging semantics.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
BUILD_DIR="$ROOT_DIR/.build/package_build"
STUB_DIR="$BUILD_DIR/private_framework_stubs"
THEOS_LIB_DIR="$BUILD_DIR/theos_library"
PACKAGE_DIR_ROOT="$BUILD_DIR/packages"
OUT_DIR="$ROOT_DIR/out"
UNPACK_DIR="$BUILD_DIR/unpacked"

SDK_VERSION="${WATCHFIX_SDK_VERSION:-16.2}"
MIN_OS_VERSION="${WATCHFIX_MIN_OS_VERSION:-15.0}"
TARGET_SPEC="iphone:clang:${SDK_VERSION}:${MIN_OS_VERSION}"
WORKAROUND_MODE="${WATCHFIX_LOCAL_PRIVATE_FRAMEWORK_WORKAROUND:-auto}"

DEFAULT_SCHEMES=(rootless roothide)
PRIVATE_FRAMEWORKS=(
  AppSupport
  BridgePreferences
  ControlCenterUIKit
  IDS
  NanoLeash
  NanoRegistry
  NanoSystemSettings
  NanoTimeKit
  NanoTimeKitCompanion
  PBBridgeSupport
  Preferences
  ProtocolBuffer
  RunningBoardServices
  SoftwareUpdateBridge
  Symbolication
  VisualPairing
)

note() {
  printf '[build_packages] %s\n' "$*"
}

fail() {
  printf '[build_packages] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

validate_scheme() {
  case "$1" in
    rootless|roothide) ;;
    *) fail "unsupported scheme: $1" ;;
  esac
}

resolve_schemes() {
  if [ "$#" -eq 0 ]; then
    printf '%s\n' "${DEFAULT_SCHEMES[@]}"
    return
  fi

  local scheme
  for scheme in "$@"; do
    validate_scheme "$scheme"
    printf '%s\n' "$scheme"
  done
}

active_sdk_path() {
  xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || true
}

sdk_has_private_framework_stubs() {
  local sdk_path="$1"
  local framework_name

  [ -n "$sdk_path" ] || return 1
  for framework_name in "${PRIVATE_FRAMEWORKS[@]}"; do
    if [ ! -e "$sdk_path/System/Library/PrivateFrameworks/${framework_name}.framework" ]; then
      return 1
    fi
  done
  return 0
}

should_use_local_workaround() {
  case "$WORKAROUND_MODE" in
    force) return 0 ;;
    off) return 1 ;;
    auto)
      local sdk_path
      sdk_path="$(active_sdk_path)"
      sdk_has_private_framework_stubs "$sdk_path" && return 1 || return 0
      ;;
    *)
      fail "WATCHFIX_LOCAL_PRIVATE_FRAMEWORK_WORKAROUND must be one of: auto, force, off"
      ;;
  esac
}

create_framework_stub() {
  local framework_name="$1"
  local framework_dir="$STUB_DIR/${framework_name}.framework"
  local stub_path="$framework_dir/${framework_name}.tbd"

  mkdir -p "$framework_dir"
  cat >"$stub_path" <<EOF
--- !tapi-tbd
tbd-version: 4
targets: [ arm64-ios, arm64e-ios ]
install-name: /System/Library/PrivateFrameworks/${framework_name}.framework/${framework_name}
current-version: 1
compatibility-version: 1
exports:
  - targets: [ arm64-ios, arm64e-ios ]
    symbols: [ ]
...
EOF
}

prepare_private_framework_stubs() {
  rm -rf "$STUB_DIR"
  mkdir -p "$STUB_DIR"

  local framework_name
  for framework_name in "${PRIVATE_FRAMEWORKS[@]}"; do
    create_framework_stub "$framework_name"
  done
}

clean_build_state() {
  rm -rf "$ROOT_DIR/.theos" "$ROOT_DIR/_" "$ROOT_DIR/packages" "$THEOS_LIB_DIR"
}

build_native_package() {
  local scheme="$1"
  local package_dir="$PACKAGE_DIR_ROOT/$scheme"
  local -a make_args

  note "building native ${scheme} package"
  clean_build_state
  mkdir -p "$package_dir" "$THEOS_LIB_DIR"

  make_args=(
    clean package
    FINALPACKAGE=1
    GO_EASY_ON_ME=1
    "THEOS_PACKAGE_SCHEME=${scheme}"
    "THEOS_LIBRARY_PATH=${THEOS_LIB_DIR}"
    "THEOS_PACKAGE_DIR=${package_dir}"
    "TARGET=${TARGET_SPEC}"
  )

  if should_use_local_workaround; then
    note "using local private framework stub workaround for ${scheme}"
    prepare_private_framework_stubs
    make_args+=(
      "TARGET_PRIVATE_FRAMEWORK_PATH=${STUB_DIR}"
      "ADDITIONAL_LDFLAGS=-Wl,-undefined,dynamic_lookup"
    )
  fi

  (
    cd "$ROOT_DIR"
    make "${make_args[@]}"
  )
}

copy_built_package() {
  local scheme="$1"
  local expected_arch="$2"
  local package_dir="$PACKAGE_DIR_ROOT/$scheme"
  local built_deb output_path unpack_root control_architecture

  built_deb="$(find "$package_dir" -maxdepth 1 -name '*.deb' | head -n 1)"
  [ -n "$built_deb" ] || fail "no ${scheme} deb found in ${package_dir}"

  mkdir -p "$OUT_DIR"
  output_path="$OUT_DIR/$(basename "$built_deb")"
  rm -f "$output_path"
  cp "$built_deb" "$output_path"

  unpack_root="$UNPACK_DIR/$scheme"
  rm -rf "$unpack_root"
  mkdir -p "$unpack_root"
  dpkg-deb -R "$output_path" "$unpack_root" >/dev/null

  control_architecture="$(awk -F': ' '/^Architecture:/{print $2; exit}' "$unpack_root/DEBIAN/control")"
  [ "$control_architecture" = "$expected_arch" ] || fail "${scheme} deb architecture mismatch: ${control_architecture}"

  case "$scheme" in
    rootless)
      [ -d "$unpack_root/var/jb/Applications" ] || fail "rootless package does not contain /var/jb/Applications"
      ;;
    roothide)
      [ -d "$unpack_root/Applications" ] || fail "roothide package does not contain /Applications"
      [ ! -d "$unpack_root/var/jb" ] || fail "roothide package still exposes /var/jb as install root"
      ;;
  esac

  printf '%s\n' "$output_path"
}

main() {
  require_command make
  require_command dpkg-deb
  require_command xcrun

  mkdir -p "$BUILD_DIR" "$PACKAGE_DIR_ROOT" "$UNPACK_DIR" "$OUT_DIR"
  rm -f "$OUT_DIR"/cn.fkj233.watchfix.mod_*native-roothide*.deb

  local -a schemes=()
  while IFS= read -r scheme; do
    [ -n "$scheme" ] && schemes+=("$scheme")
  done < <(resolve_schemes "$@")

  local scheme
  for scheme in "${schemes[@]}"; do
    build_native_package "$scheme"
  done

  local built_path
  note "built packages:"
  for scheme in "${schemes[@]}"; do
    case "$scheme" in
      rootless) built_path="$(copy_built_package "$scheme" iphoneos-arm64)" ;;
      roothide) built_path="$(copy_built_package "$scheme" iphoneos-arm64e)" ;;
      *) fail "unexpected scheme during copy: $scheme" ;;
    esac
    printf '%s\n' "$built_path"
  done
}

main "$@"
