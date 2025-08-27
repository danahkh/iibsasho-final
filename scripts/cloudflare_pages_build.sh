#!/usr/bin/env bash
set -euo pipefail

# Cloudflare Pages build script for Flutter Web
# - Uses existing Flutter if available; otherwise installs the requested version/channel
# - Builds web release
# - Ensures SPA routing via _redirects (/*    /index.html   200)

echo "[build] Starting Cloudflare Pages Flutter Web build"

# Allow pinning Flutter version or channel via FLUTTER_VERSION env (e.g. 'stable' or '3.24.3')
FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"

if command -v flutter >/dev/null 2>&1; then
  echo "[build] Using preinstalled Flutter: $(flutter --version 2>/dev/null | head -n 1)"
else
  echo "[build] Installing Flutter (${FLUTTER_VERSION})"
  git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git "$PWD/.flutter-sdk"
  export PATH="$PWD/.flutter-sdk/bin:$PATH"
  flutter --version
fi

echo "[build] Flutter doctor (brief)"
flutter --version
flutter config --no-analytics || true

echo "[build] Pub get"
flutter pub get

echo "[build] Building web release"
flutter build web --release

# Ensure SPA redirects (Cloudflare Pages)
echo "[build] Writing SPA _redirects"
mkdir -p build/web
cat > build/web/_redirects <<'REDIRECTS'
/*    /index.html   200
REDIRECTS

echo "[build] Done. Output: build/web"
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
