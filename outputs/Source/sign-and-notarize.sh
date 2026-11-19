#!/bin/bash
set -euo pipefail
# Use existing keychain credentials; never put passwords in this file.
: "${SIGN_IDENTITY:?Set SIGN_IDENTITY to the Developer ID Application identity}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to a notarytool keychain profile}"
release_root="$(cd "$(dirname "$0")/.." && pwd)"
input_archive="${INPUT_ARCHIVE:-$release_root/Brushes Preview-macOS-0.2.4.zip}"
release_stage="$(mktemp -d -t brushes-preview-notary)"
trap 'rm -rf "$release_stage"' EXIT
app_bundle="$release_stage/Brushes Preview.app"
ditto -x -k "$input_archive" "$release_stage"
for relative_path in Contents/MacOS/BrushPreview Contents/PlugIns/Preview.appex/Contents/MacOS/Preview Contents/PlugIns/Thumbnail.appex/Contents/MacOS/Thumbnail; do
 test -x "$app_bundle/$relative_path" || { echo "Missing executable permission: $relative_path" >&2; exit 1; }
done
for extension_name in Preview Thumbnail; do
 codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp --entitlements "$release_root/Source/extension.entitlements" "$app_bundle/Contents/PlugIns/$extension_name.appex"
done
codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp "$app_bundle"
codesign --verify --deep --strict "$app_bundle"
ditto -c -k --keepParent --norsrc "$app_bundle" "$release_stage/notarization.zip"
xcrun notarytool submit "$release_stage/notarization.zip" --keychain-profile "$NOTARY_PROFILE" --wait --output-format json > "$release_root/Apple公證結果.json"
python3 - "$release_root/Apple公證結果.json" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]));print('Notarization:',r.get('status'),r.get('id'))
if r.get('status')!='Accepted':raise SystemExit('Notarization not accepted; review the submission log before distributing.')
PY
xcrun stapler staple "$app_bundle"
xcrun stapler validate "$app_bundle"
spctl --assess --type execute --verbose "$app_bundle"
ditto -c -k --keepParent --norsrc "$app_bundle" "$release_root/Brushes Preview-macOS-notarized.zip"
echo "Verified notarized release: $release_root/Brushes Preview-macOS-notarized.zip"
