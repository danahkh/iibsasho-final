#!/usr/bin/env bash
set -euo pipefail
set -x

# Fail fast if flutter already built (cache reuse)
if [ -d build/web ]; then
  echo "Reusing existing build/web directory";
  exit 0;
fi

FLUTTER_CHANNEL="stable"
FLUTTER_VERSION="3.24.0"

echo "Downloading Flutter $FLUTTER_VERSION ($FLUTTER_CHANNEL)";
mkdir -p .flutter-sdk
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -o flutter.tar.xz
# Extract using GNU tar (available on Vercel). If -J is unsupported, try generic -xf.
if tar --help 2>/dev/null | grep -q "-J"; then
  tar -xJf flutter.tar.xz -C .flutter-sdk
else
  tar -xf flutter.tar.xz -C .flutter-sdk || (echo "tar extraction failed" && exit 1)
fi
export PATH="$PWD/.flutter-sdk/flutter/bin:$PATH"

flutter config --enable-web
flutter --version

# Fetch dependencies
flutter pub get

# Build web release
flutter build web --release --no-tree-shake-icons

# Print size summary
du -sh build/web || true

# Vercel expects output in build/web (configured via vercel.json)
echo "Build complete." 
