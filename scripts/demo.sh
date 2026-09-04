#!/usr/bin/env bash
# AdaptQ Interactive Terminal Presentation Demo
# Usage: ./scripts/demo.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(dirname "$DIR")"

cd "$ROOT_DIR"
dart run scripts/demo.dart
