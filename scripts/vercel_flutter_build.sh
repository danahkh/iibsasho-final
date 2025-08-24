#!/usr/bin/env bash
set -euo pipefail
set -x

# Fail fast if flutter already built (cache reuse)
if [ -d build/web ]; then
  echo "Reusing existing build/web directory";
  exit 0;
fi

FLUTTER_CHANNEL="stable"
# Use a Flutter version that includes Dart >= 3.8.1
FLUTTER_VERSION="3.35.1"

echo "Downloading Flutter $FLUTTER_VERSION ($FLUTTER_CHANNEL)";
mkdir -p .flutter-sdk
curl -L "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" -o flutter.tar.xz
# Extract (GNU tar on Vercel supports xz with -xf)
tar -xf flutter.tar.xz -C .flutter-sdk || (echo "tar extraction failed" && exit 1)
export PATH="$PWD/.flutter-sdk/flutter/bin:$PATH"
# Silence git 'dubious ownership' warning inside Flutter SDK
git config --global --add safe.directory "$PWD/.flutter-sdk/flutter" || true

flutter config --enable-web --no-analytics --no-cli-animations
flutter --version

# Fetch dependencies
flutter pub get

# Build web release
flutter build web --release --no-tree-shake-icons

# Print size summary
du -sh build/web || true

# Vercel expects output in build/web (configured via vercel.json)
echo "Build complete." 
