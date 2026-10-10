#!/usr/bin/env bash
# Cloud Agent install script for the MagicKit Flutter monorepo.
# Idempotent: safe to run repeatedly and on a snapshot that already has the toolchain.
set -euo pipefail

FLUTTER_VERSION="3.47.5"
FLUTTER_DIR="/opt/flutter"
FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_ARCHIVE}"

log() { printf '\n=== %s ===\n' "$1"; }

# 1. Install the pinned Flutter SDK (bundles Dart) if it is not already present.
if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
  log "Installing Flutter ${FLUTTER_VERSION}"
  tmp="$(mktemp -d)"
  curl -fSL -o "${tmp}/${FLUTTER_ARCHIVE}" "${FLUTTER_URL}"
  sudo rm -rf "${FLUTTER_DIR}"
  sudo mkdir -p /opt
  sudo tar -C /opt -xf "${tmp}/${FLUTTER_ARCHIVE}"
  sudo chown -R "$(id -u):$(id -g)" "${FLUTTER_DIR}"
  rm -rf "${tmp}"
else
  log "Flutter already present at ${FLUTTER_DIR}"
fi

# 2. Expose flutter/dart on PATH without mutating shell profiles.
sudo ln -sf "${FLUTTER_DIR}/bin/flutter" /usr/local/bin/flutter
sudo ln -sf "${FLUTTER_DIR}/bin/dart" /usr/local/bin/dart

# git operates inside the SDK checkout, so mark it as a safe directory.
git config --global --add safe.directory "${FLUTTER_DIR}" || true

export PATH="${FLUTTER_DIR}/bin:${HOME}/.pub-cache/bin:${PATH}"

log "Toolchain versions"
flutter --version
dart --version

# 3. Configure Flutter for headless web development (Chrome is the runnable target).
flutter config --no-analytics >/dev/null 2>&1 || true
dart --disable-analytics >/dev/null 2>&1 || true
flutter config --enable-web >/dev/null 2>&1 || true

# 4. Provide the `melos` executable on PATH (repo pins melos ^7 as a workspace
#    dev_dependency; the global wrapper defers to that pinned version in-repo).
log "Activating melos"
dart pub global activate melos >/dev/null 2>&1 || dart pub global activate melos
sudo ln -sf "${HOME}/.pub-cache/bin/melos" /usr/local/bin/melos

# 5. Resolve all workspace package dependencies (pub workspace root resolution).
log "Resolving workspace dependencies"
cd "$(dirname "$0")/.."
flutter pub get

log "Install complete"
