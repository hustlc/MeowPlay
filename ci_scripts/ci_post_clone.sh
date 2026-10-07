#!/bin/bash
set -euo pipefail

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
  exit 0
fi

if command -v brew >/dev/null 2>&1; then
  brew install xcodegen
  xcodegen generate
  exit 0
fi

echo "XcodeGen is required to generate MeowPlay.xcodeproj from project.yml." >&2
exit 1
