#!/bin/bash

# KubeCon Schedule Monitor - Local Version (Orchestrator)
# Run this script to check for schedule updates and commit changes
# This script calls download-schedule.sh followed by compare-schedule.sh

set -e  # Exit on any error

echo "🔍 KubeCon EU 2026 Schedule Monitor (Orchestrator)"
echo "================================================"

# Set timezone to conference location (Amsterdam)
export TZ="Europe/Amsterdam"

CURRENT_DATE=$(date '+%A %H:%M')

echo "Current time (Amsterdam): $CURRENT_DATE"
echo ""

echo "📥 Step 1: Downloading schedule..."
echo "================================="
if ! ./download-schedule.sh; then
  echo "❌ Download failed!"
  exit 1
fi

echo ""
echo "🔍 Step 2: Comparing with baseline..."
echo "===================================="
./compare-schedule.sh

echo ""
echo "🏁 Orchestration completed successfully!"
echo "Monitor completed at $(date '+%Y-%m-%d %H:%M:%S')"