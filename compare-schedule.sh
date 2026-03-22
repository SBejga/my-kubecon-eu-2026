#!/bin/bash

# KubeCon Schedule Comparator
# Compares downloaded schedule with baseline and updates logs

set -e  # Exit on any error

echo "🔍 KubeCon EU 2026 Schedule Comparator"
echo "====================================="

# baseline file name
export BASELINE_FILE="2026-03-22-1408-all.ics"

# Set timezone to conference location (Amsterdam)
export TZ="Europe/Amsterdam"

# Format current date and time
CURRENT_DATE=$(date '+%A %H:%M')
CURRENT_ISO=$(date '+%Y-%m-%d %H:%M')
CURRENT_FILENAME=$(date '+%Y-%m-%d-%H%M')

echo "Current time (Amsterdam): $CURRENT_DATE"
echo ""

# Check if downloaded file exists
if [ ! -f "current-schedule.ics" ]; then
  echo "❌ No current-schedule.ics file found!"
  echo "Please run download-schedule.sh first"
  exit 1
fi

# Compare with baseline
echo "🔍 Comparing with baseline..."

if [ ! -f "$BASELINE_FILE" ]; then
  echo "❌ Baseline file $BASELINE_FILE not found!"
  exit 1
fi

BASELINE_SIZE=$(wc -c < "$BASELINE_FILE")
CURRENT_SIZE=$(wc -c < current-schedule.ics)

echo "Baseline size: $BASELINE_SIZE bytes"
echo "Current size:  $CURRENT_SIZE bytes"

HAS_CHANGES=false

if ! cmp -s "$BASELINE_FILE" "current-schedule.ics"; then
  echo "📅 Changes detected in KubeCon schedule!"
  HAS_CHANGES=true
  
  # Generate diff summary
  echo "Generating change summary..."
  
  # Count event changes
  BASELINE_EVENTS=$(grep -c "BEGIN:VEVENT" "$BASELINE_FILE" 2>/dev/null || echo "0")
  CURRENT_EVENTS=$(grep -c "BEGIN:VEVENT" "current-schedule.ics" 2>/dev/null || echo "0")
  
  # Ensure we have valid numbers
  BASELINE_EVENTS=${BASELINE_EVENTS:-0}
  CURRENT_EVENTS=${CURRENT_EVENTS:-0}
  
  # Remove any whitespace/newlines
  BASELINE_EVENTS=$(echo "$BASELINE_EVENTS" | tr -d '[:space:]')
  CURRENT_EVENTS=$(echo "$CURRENT_EVENTS" | tr -d '[:space:]')
  
  EVENT_DIFF=$((CURRENT_EVENTS - BASELINE_EVENTS))
  
  echo "Events - Baseline: $BASELINE_EVENTS, Current: $CURRENT_EVENTS, Diff: $EVENT_DIFF"
  
  # Generate detailed diff for new events if any added
  NEW_EVENTS_FOUND=false
  if [ $EVENT_DIFF -gt 0 ]; then
    echo "📝 Extracting new events..."
    
    # Extract new event summaries (this is a simple approach)
    diff -u "$BASELINE_FILE" "current-schedule.ics" | \
      grep "^+SUMMARY:" | \
      sed 's/^+SUMMARY://' | \
      head -20 > new_events.txt
      
    if [ -s new_events.txt ]; then
      NEW_EVENTS_FOUND=true
    fi
  fi
  
  # Save size diff info
  SIZE_DIFF=$((CURRENT_SIZE - BASELINE_SIZE))
  
else
  echo "✅ No changes detected in schedule"
fi

# Update changes log if there are changes
if [ "$HAS_CHANGES" = "true" ]; then
  echo ""
  echo "📝 Updating updates.md with detected changes..."
  
  # Create updates.md if it doesn't exist
  if [ ! -f "updates.md" ]; then
    cat > updates.md << 'EOF'
# KubeCon EU 2026 Schedule Updates

This file tracks changes to the conference schedule detected by automated monitoring.

---

EOF
  fi
  
  # Prepare change entry
  CHANGE_ENTRY=$(cat << EOF

## $CURRENT_DATE ($CURRENT_ISO)

**Schedule Update Detected:**

- **Events**: $CURRENT_EVENTS (was $BASELINE_EVENTS, $EVENT_DIFF change)
- **File Size**: $(numfmt --to=iec $CURRENT_SIZE) ($SIZE_DIFF bytes difference)
- **Detection Time**: $CURRENT_ISO (Amsterdam time)
EOF
)
  
  # Add new events info if available
  if [ "$NEW_EVENTS_FOUND" = "true" ] && [ -f new_events.txt ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**New Events Added:**\n'
    while IFS= read -r event; do
      CHANGE_ENTRY="$CHANGE_ENTRY"$'\n'"- $event"
    done < new_events.txt
  fi
  
  # Add change summary
  if [ $EVENT_DIFF -gt 0 ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**Summary**: 🆕 '"$EVENT_DIFF new events added to schedule"
  elif [ $EVENT_DIFF -lt 0 ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**Summary**: ❌ '$((-EVENT_DIFF))' events removed from schedule'
  else
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**Summary**: 📝 Event details updated (same event count)'
  fi
  
  # Insert the new entry after the header (line 5)
  {
    head -5 updates.md
    echo "$CHANGE_ENTRY"
    tail -n +6 updates.md
  } > updates_temp.md
  
  mv updates_temp.md updates.md
  
  echo "✅ Updated updates.md"
  
  # Archive current schedule  
  echo ""
  echo "📦 Archiving current schedule..."
  cp current-schedule.ics "${CURRENT_FILENAME}-all.ics"
  echo "📦 Archived current schedule as ${CURRENT_FILENAME}-all.ics"
  
  echo ""
  echo "✅ Changes detected and logged to updates.md"
  echo "⚠️  Manual commit required - files staged but not committed:"
  echo "   - updates.md"
  echo "   - ${CURRENT_FILENAME}-all.ics"
  
  # Clean up temporary files
  rm -f new_events.txt
  
else
  echo ""
  echo "✅ No changes to commit"
fi

# Summary
echo ""
echo "🎯 Summary:"
if [ "$HAS_CHANGES" = "true" ]; then
  echo "Changes detected and logged to updates.md"
  echo "📊 Event change: $EVENT_DIFF events"
  echo "💾 Size change: $SIZE_DIFF bytes"
  echo "⚠️  Manual git commit required"
else
  echo "No changes detected in schedule"
fi
echo ""
echo "Comparison completed at $(date '+%Y-%m-%d %H:%M:%S')"