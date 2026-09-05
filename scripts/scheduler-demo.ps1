# EventFlow Scheduler Demo Wrapper
# This script forwards arguments to the cross-platform TypeScript implementation.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$tsScript = Join-Path $scriptDir "scheduler-demo.ts"

npx tsx $tsScript @args
