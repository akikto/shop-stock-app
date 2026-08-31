#!/usr/bin/env bash
# Regenerates launcher icons from assets/icon/app_icon.png using
# flutter_launcher_icons. Requires Flutter SDK + `flutter pub get` first.
set -euo pipefail
cd "$(dirname "$0")/.."
dart run flutter_launcher_icons
