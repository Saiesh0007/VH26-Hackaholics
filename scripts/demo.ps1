# AdaptQ Interactive Terminal Presentation Demo
# Usage: .\scripts\demo.ps1

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = Split-Path -Parent $scriptDir

Set-Location $rootDir
dart run scripts/demo.dart
