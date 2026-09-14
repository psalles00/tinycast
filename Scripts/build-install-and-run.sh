#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
derived_data="$project_root/build/DerivedData"
installed_app="/Applications/Tinycast.app"
staged_app="/Applications/.Tinycast.installing.app"
previous_app="$project_root/build/previous/Tinycast.app"
developer_dir="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}"
signing_identity="${TINYCAST_SIGNING_IDENTITY:-Tinycast Self-Signed}"
launch_after_install=1

if [[ "${1:-}" == "--no-launch" ]]; then
    launch_after_install=0
elif [[ $# -gt 0 ]]; then
    print -u2 "Usage: $0 [--no-launch]"
    exit 64
fi

if [[ ! -x "$developer_dir/usr/bin/xcodebuild" ]]; then
    print -u2 "Xcode 26 is required at $developer_dir. Set DEVELOPER_DIR to its Contents/Developer path."
    exit 1
fi

if ! security find-identity -v -p codesigning | grep -Fq "\"$signing_identity\""; then
    signing_identity=$(security find-identity -v -p codesigning \
        | sed -n 's/.*"\(Apple Development:.*\)"/\1/p' | head -n 1)
fi
if [[ -z "$signing_identity" ]]; then
    print -u2 "No usable code-signing identity is available. Set TINYCAST_SIGNING_IDENTITY first."
    exit 1
fi

DEVELOPER_DIR="$developer_dir" xcodebuild \
    -project "$project_root/Tinycast.xcodeproj" \
    -scheme Tinycast \
    -configuration Release \
    -derivedDataPath "$derived_data" \
    CODE_SIGN_IDENTITY="$signing_identity" \
    build

product_dir=$(DEVELOPER_DIR="$developer_dir" xcodebuild \
    -project "$project_root/Tinycast.xcodeproj" \
    -scheme Tinycast \
    -configuration Release \
    -derivedDataPath "$derived_data" \
    CODE_SIGN_IDENTITY="$signing_identity" \
    -showBuildSettings | sed -n 's/^[[:space:]]*TARGET_BUILD_DIR = //p')
product="$product_dir/Tinycast.app"

if [[ ! -d "$product" ]]; then
    print -u2 "Release build completed without Tinycast.app at $product."
    exit 1
fi

rm -rf "$staged_app"
ditto "$product" "$staged_app"
codesign --verify --strict --deep "$staged_app"

if pgrep -x Tinycast >/dev/null; then
    pkill -x Tinycast
fi

if [[ -d "$installed_app" ]]; then
    rm -rf "$previous_app"
    mkdir -p "${previous_app:h}"
    ditto "$installed_app" "$previous_app"
fi

rm -rf "$installed_app"
mv "$staged_app" "$installed_app"
if (( launch_after_install )); then
    open -n "$installed_app"
fi
