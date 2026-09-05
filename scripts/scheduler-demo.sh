#!/bin/bash
# EventFlow Scheduler Demo Wrapper
# This script forwards arguments to the cross-platform TypeScript implementation.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
npx tsx "$DIR/scheduler-demo.ts" "$@"
