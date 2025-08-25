#!/usr/bin/env bash
set -euo pipefail
set -x

# Cloudflare Pages build for Flutter Web
# Produces build/web and writes _redirects for SPA fallback

FLUTTER_CHANNEL="stable"
FLUTTER_VERSION="3.35.1" # Dart >= 3.8, matches pubspec

echo "Downloading Flutter $FLUTTER_VERSION ($FLUTTER_CHANNEL)"
mkdir -p .flutter-sdk
curl -L "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" -o flutter.tar.xz
tar -xf flutter.tar.xz -C .flutter-sdk
export PATH="$PWD/.flutter-sdk/flutter/bin:$PATH"

# Avoid git safe.directory warnings inside CI
git config --global --add safe.directory "$PWD/.flutter-sdk/flutter" || true

export PUB_CACHE="$PWD/.pub-cache"

flutter config --enable-web --no-analytics --no-cli-animations
flutter --version
flutter pub get

# Build
flutter build web --release --no-tree-shake-icons

# Cloudflare SPA fallback
printf "/*\t/index.html\t200\n" > build/web/_redirects

du -sh build/web || true
echo "Cloudflare Pages build complete"
