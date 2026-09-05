#!/bin/bash

# Navigate to the script's directory so it can find the TS file
cd "$(dirname "$0")"

# Run the TypeScript chaos demo
npx tsx chaos-demo.ts "$@"
