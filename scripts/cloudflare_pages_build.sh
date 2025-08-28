#!/usr/bin/env bash
set -euo pipefail
set -x

# Cloudflare Pages build for Flutter Web (consolidated)
# Produces build/web and writes _redirects for SPA fallback

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_VERSION_PIN="${FLUTTER_VERSION:-3.35.1}"

echo "Downloading Flutter ${FLUTTER_VERSION_PIN} (${FLUTTER_CHANNEL})"
mkdir -p .flutter-sdk
curl -L "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION_PIN}-${FLUTTER_CHANNEL}.tar.xz" -o flutter.tar.xz
tar -xf flutter.tar.xz -C .flutter-sdk
export PATH="$PWD/.flutter-sdk/flutter/bin:$PATH"

# Avoid git safe.directory warnings inside CI
git config --global --add safe.directory "$PWD/.flutter-sdk/flutter" || true

export PUB_CACHE="$PWD/.pub-cache"

flutter config --enable-web --no-analytics --no-cli-animations
flutter --version
flutter pub get

# Build web (disable service worker caching to avoid stale deploys)
flutter build web --release --no-tree-shake-icons --pwa-strategy=none

# Cloudflare SPA fallback
printf "/*\t/index.html\t200\n" > build/web/_redirects

du -sh build/web || true
echo "Cloudflare Pages build complete"
