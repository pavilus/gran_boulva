#!/usr/bin/env bash
set -euo pipefail

DEVICE_ID="${1:-}"

if [[ -z "$DEVICE_ID" ]]; then
  echo "Usage: scripts/test_ios_smoke.sh <ios-device-or-simulator-id>"
  echo
  flutter devices
  exit 2
fi

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/onboarding_auth_smoke_test.dart \
  --publish-port \
  -d "$DEVICE_ID"
