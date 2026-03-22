#!/bin/bash

# KubeCon Schedule Monitor - Local Version
# Run this script to check for schedule updates and commit changes

set -e  # Exit on any error

echo "🔍 KubeCon EU 2026 Schedule Monitor"
echo "=================================="

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

# Download current schedule
echo "📥 Downloading latest schedule from sched.com..."

# Check if we already have a current schedule file
if [ -f "current-schedule.ics" ]; then
  echo "📄 Found existing current-schedule.ics, checking for updates..."
  CONDITIONAL_FLAG="-z current-schedule.ics"
else
  echo "📄 No existing schedule file, downloading fresh copy..."
  CONDITIONAL_FLAG=""
fi

# Try download with browser headers and retry logic
DOWNLOAD_OCCURRED=false
for attempt in 1 2 3; do
  echo "Attempt $attempt/3..."
  
  if curl -o "current-schedule.ics" -f -L $CONDITIONAL_FLAG \
    --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
    --header "Accept: text/calendar,application/octet-stream,*/*;q=0.9" \
    --header "Accept-Language: en-US,en;q=0.9" \
    --header "Accept-Encoding: gzip, deflate, br" \
    --header "Cache-Control: no-cache" \
    --header "Pragma: no-cache" \
    --connect-timeout 30 \
    --max-time 120 \
    --retry 2 \
    --retry-delay 5 \
    "https://kccnceu2026.sched.com/all.ics"; then
    
    echo "✅ Download successful"
    DOWNLOAD_OCCURRED=true
    break
  else
    CURL_EXIT_CODE=$?
    if [ $CURL_EXIT_CODE -eq 22 ]; then
      echo "✅ Remote file not modified since last download"
      DOWNLOAD_OCCURRED=false
      break
    else
      echo "❌ Attempt $attempt failed (exit code: $CURL_EXIT_CODE)"
      if [ $attempt -eq 3 ]; then
        echo "🚨 All download attempts failed. Possible causes:"
        echo "- IP range blocked by sched.com"
        echo "- Rate limiting"
        echo "- Service temporarily unavailable"
        exit 1
      fi
      echo "Waiting 10 seconds before retry..."
      sleep 10
    fi
  fi
done

# Get file size for logging
CURRENT_SIZE=$(wc -c < current-schedule.ics)
echo "Downloaded schedule size: $CURRENT_SIZE bytes"

# If no download occurred, we can skip comparison if we want
if [ "$DOWNLOAD_OCCURRED" = "false" ]; then
  echo ""
  echo "✅ Remote file not modified - no comparison needed"
  echo ""
  echo "🎯 Summary: No remote changes detected"
  echo ""
  echo "Monitor completed at $(date '+%Y-%m-%d %H:%M:%S')"
  exit 0
fi

# Compare with baseline
echo ""
echo "🔍 Comparing with baseline..."

if [ ! -f "$BASELINE_FILE" ]; then
  echo "❌ Baseline file $BASELINE_FILE not found!"
  exit 1
fi

BASELINE_SIZE=$(wc -c < "$BASELINE_FILE")

echo "Baseline size: $BASELINE_SIZE bytes"
echo "Current size:  $CURRENT_SIZE bytes"

HAS_CHANGES=false

if ! cmp -s "$BASELINE_FILE" "current-schedule.ics"; then
  echo "📅 Changes detected in KubeCon schedule!"
  HAS_CHANGES=true
  
  # Generate diff summary
  echo "Generating change summary..."
  
  # Count event changes
  BASELINE_EVENTS=$(grep -c "BEGIN:VEVENT" "$BASELINE_FILE" || echo "0")
  CURRENT_EVENTS=$(grep -c "BEGIN:VEVENT" "current-schedule.ics" || echo "0")
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

- **Events**: $CURRENT_EVENTS (was $BASELINE_EVENTS, ${EVENT_DIFF:+0} change)
- **File Size**: $(numfmt --to=iec $CURRENT_SIZE) (${SIZE_DIFF:+0} bytes difference)
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
echo "Monitor completed at $(date '+%Y-%m-%d %H:%M:%S')"