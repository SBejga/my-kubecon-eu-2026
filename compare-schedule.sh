#!/bin/bash

# KubeCon Schedule Comparator
# Compares downloaded schedule with baseline and updates logs

set -e  # Exit on any error

echo "🔍 KubeCon EU 2026 Schedule Comparator"
echo "====================================="

# baseline file name
export BASELINE_FILE="latest.ics"

# Set timezone to conference location (Amsterdam)
export TZ="Europe/Amsterdam"
CURRENT_DATE=$(date '+%A %H:%M')
CURRENT_ISO=$(date '+%Y-%m-%d %H:%M')

format_event_day() {
  local dtstart_line="$1"
  local raw_value date_part

  raw_value="${dtstart_line#*:}"
  date_part="${raw_value%%T*}"
  date_part="${date_part%% *}"

  if [ -z "$date_part" ] || [ "${#date_part}" -lt 8 ]; then
    echo "Unknown day"
    return
  fi

  date_part="${date_part:0:8}"

  if formatted_day=$(date -j -f '%Y%m%d' "$date_part" '+%A %Y-%m-%d' 2>/dev/null); then
    echo "$formatted_day"
  elif formatted_day=$(date -d "$date_part" '+%A %Y-%m-%d' 2>/dev/null); then
    echo "$formatted_day"
  else
    echo "${date_part:0:4}-${date_part:4:2}-${date_part:6:2}"
  fi
}

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
  
  # Generate comprehensive diff analysis
  echo "Generating detailed change analysis..."
  
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
  
  # Extract event details for comparison
  echo "📊 Analyzing individual event changes..."
  
  # Create temporary files for parsed events
  BASELINE_EVENTS_FILE="baseline_events.tmp"
  CURRENT_EVENTS_FILE="current_events.tmp"
  
  # Parse baseline events (UID -> properties)
  awk '/BEGIN:VEVENT/,/END:VEVENT/ {
    if ($0 ~ /^UID:/) uid = substr($0, 5)
    else if ($0 ~ /^SUMMARY:/) summary = substr($0, 9)
    else if ($0 ~ /^DESCRIPTION:/) description = substr($0, 13)
    else if ($0 ~ /^DTSTART/) dtstart = $0
    else if ($0 ~ /^DTEND/) dtend = $0
    else if ($0 ~ /^LOCATION:/) location = substr($0, 10)
    else if ($0 ~ /END:VEVENT/) {
      print uid "|" summary "|" description "|" dtstart "|" dtend "|" location
      uid = summary = description = dtstart = dtend = location = ""
    }
  }' "$BASELINE_FILE" > "$BASELINE_EVENTS_FILE"
  
  # Parse current events (UID -> properties)
  awk '/BEGIN:VEVENT/,/END:VEVENT/ {
    if ($0 ~ /^UID:/) uid = substr($0, 5)
    else if ($0 ~ /^SUMMARY:/) summary = substr($0, 9)
    else if ($0 ~ /^DESCRIPTION:/) description = substr($0, 13)
    else if ($0 ~ /^DTSTART/) dtstart = $0
    else if ($0 ~ /^DTEND/) dtend = $0
    else if ($0 ~ /^LOCATION:/) location = substr($0, 10)
    else if ($0 ~ /END:VEVENT/) {
      print uid "|" summary "|" description "|" dtstart "|" dtend "|" location
      uid = summary = description = dtstart = dtend = location = ""
    }
  }' "current-schedule.ics" > "$CURRENT_EVENTS_FILE"
  
  # Initialize counters and results
  ADDED_COUNT=0
  REMOVED_COUNT=0
  MODIFIED_COUNT=0
  SUMMARY_CHANGES=0
  DESCRIPTION_CHANGES=0
  TIME_CHANGES=0
  LOCATION_CHANGES=0
  
  # Initialize result files
  > added_events.txt
  > removed_events.txt  
  > modified_events.txt
  > summary_changes.txt
  > description_changes.txt
  > time_changes.txt
  > location_changes.txt
  
  # Find added and modified events
  while IFS='|' read -r uid summary description dtstart dtend location; do
    if [ -n "$uid" ]; then
      # Check if this UID exists in baseline
      baseline_data=$(grep "^$uid|" "$BASELINE_EVENTS_FILE" || echo "")
      
      if [ -z "$baseline_data" ]; then
        # New event
        echo "$summary" >> added_events.txt
        ADDED_COUNT=$((ADDED_COUNT + 1))
      else
        # Compare properties
        IFS='|' read -r b_uid b_summary b_description b_dtstart b_dtend b_location <<< "$baseline_data"
        
        changes=""
        if [ "$summary" != "$b_summary" ]; then
          echo "$uid: '$b_summary' → '$summary'" >> summary_changes.txt
          changes="$changes SUMMARY"
          SUMMARY_CHANGES=$((SUMMARY_CHANGES + 1))
        fi
        
        if [ "$description" != "$b_description" ]; then
          echo "$uid: Description changed" >> description_changes.txt
          changes="$changes DESCRIPTION"
          DESCRIPTION_CHANGES=$((DESCRIPTION_CHANGES + 1))
        fi
        
        if [ "$dtstart$dtend" != "$b_dtstart$b_dtend" ]; then
          echo "$uid: '$b_dtstart $b_dtend' → '$dtstart $dtend'" >> time_changes.txt
          changes="$changes TIME"
          TIME_CHANGES=$((TIME_CHANGES + 1))
        fi
        
        if [ "$location" != "$b_location" ]; then
          echo "$uid: '$b_location' → '$location'" >> location_changes.txt
          changes="$changes LOCATION"
          LOCATION_CHANGES=$((LOCATION_CHANGES + 1))
        fi
        
        if [ -n "$changes" ]; then
          event_day=$(format_event_day "$dtstart")
          echo "$summary [$event_day] ($changes )" >> modified_events.txt
          MODIFIED_COUNT=$((MODIFIED_COUNT + 1))
        fi
      fi
    fi
  done < "$CURRENT_EVENTS_FILE"
  
  # Find removed events
  while IFS='|' read -r uid summary description dtstart dtend location; do
    if [ -n "$uid" ]; then
      if ! grep -q "^$uid|" "$CURRENT_EVENTS_FILE"; then
        echo "$summary" >> removed_events.txt
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
      fi
    fi
  done < "$BASELINE_EVENTS_FILE"
  
  # Report detailed changes
  echo ""
  echo "📋 Change Summary:"
  echo "  🆕 Added events: $ADDED_COUNT"
  echo "  ❌ Removed events: $REMOVED_COUNT"  
  echo "  📝 Modified events: $MODIFIED_COUNT"
  echo ""
  echo "📊 Property Changes:"
  echo "  📰 Summary changes: $SUMMARY_CHANGES"
  echo "  📄 Description changes: $DESCRIPTION_CHANGES"
  echo "  ⏰ Time changes: $TIME_CHANGES"
  echo "  📍 Location changes: $LOCATION_CHANGES"
  
  # Save size diff info
  SIZE_DIFF=$((CURRENT_SIZE - BASELINE_SIZE))
  
  # Set flags for report generation
  NEW_EVENTS_FOUND=false
  if [ -s added_events.txt ]; then
    NEW_EVENTS_FOUND=true
  fi
  
  MODIFIED_EVENTS_FOUND=false
  if [ -s modified_events.txt ]; then
    MODIFIED_EVENTS_FOUND=true
  fi
  
  DETAILED_CHANGES_FOUND=false
  if [ -s summary_changes.txt ] || [ -s description_changes.txt ] || [ -s time_changes.txt ] || [ -s location_changes.txt ]; then
    DETAILED_CHANGES_FOUND=true
  fi
  
  # Clean up temporary files
  rm -f "$BASELINE_EVENTS_FILE" "$CURRENT_EVENTS_FILE"
  
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
  
  # Prepare comprehensive change entry
  CHANGE_ENTRY=$(cat << EOF

## $CURRENT_DATE ($CURRENT_ISO)

**Schedule Update Detected:**

- **Total Events**: $CURRENT_EVENTS (was $BASELINE_EVENTS, $EVENT_DIFF net change)
- **File Size**: $(numfmt --to=iec $CURRENT_SIZE) ($SIZE_DIFF bytes difference)
- **Detection Time**: $CURRENT_ISO (Amsterdam time)
- **Detection Source**: 🖥️ bash script (compare-schedule.sh)

**Change Details:**
- 🆕 Added events: $ADDED_COUNT
- ❌ Removed events: $REMOVED_COUNT
- 📝 Modified events: $MODIFIED_COUNT

**Property Changes:**
- 📰 Summary changes: $SUMMARY_CHANGES
- 📄 Description changes: $DESCRIPTION_CHANGES
- ⏰ Time changes: $TIME_CHANGES
- 📍 Location changes: $LOCATION_CHANGES
EOF
)
  
  # Add added events if available
  if [ -s added_events.txt ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**🆕 Added Events:**\n'
    while IFS= read -r event; do
      CHANGE_ENTRY="$CHANGE_ENTRY"$'\n'"- $event"
    done < added_events.txt
  fi
  
  # Add removed events if available
  if [ -s removed_events.txt ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**❌ Removed Events:**\n'
    while IFS= read -r event; do
      CHANGE_ENTRY="$CHANGE_ENTRY"$'\n'"- $event"
    done < removed_events.txt
  fi
  
  # Add modified events if available  
  if [ -s modified_events.txt ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**📝 Modified Events:**\n'
    while IFS= read -r event; do
      CHANGE_ENTRY="$CHANGE_ENTRY"$'\n'"- $event"
    done < modified_events.txt
  fi
  
  # Add specific property changes (limited to first 10 for readability)
  if [ -s summary_changes.txt ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**📰 Title Changes:**\n'
    head -10 summary_changes.txt | while IFS= read -r change; do
      CHANGE_ENTRY="$CHANGE_ENTRY"$'\n'"- $change"
    done
    if [ $(wc -l < summary_changes.txt) -gt 10 ]; then
      remaining=$(($(wc -l < summary_changes.txt) - 10))
      CHANGE_ENTRY="$CHANGE_ENTRY"$'\n'"- ... and $remaining more title changes"
    fi
  fi
  
  if [ -s time_changes.txt ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**⏰ Schedule Changes:**\n'  
    head -10 time_changes.txt | while IFS= read -r change; do
      CHANGE_ENTRY="$CHANGE_ENTRY"$'\n'"- $change"
    done
    if [ $(wc -l < time_changes.txt) -gt 10 ]; then
      remaining=$(($(wc -l < time_changes.txt) - 10))
      CHANGE_ENTRY="$CHANGE_ENTRY"$'\n'"- ... and $remaining more schedule changes"
    fi
  fi
  
  if [ -s location_changes.txt ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**📍 Location Changes:**\n'
    head -10 location_changes.txt | while IFS= read -r change; do
      CHANGE_ENTRY="$CHANGE_ENTRY"$'\n'"- $change"
    done
    if [ $(wc -l < location_changes.txt) -gt 10 ]; then
      remaining=$(($(wc -l < location_changes.txt) - 10))
      CHANGE_ENTRY="$CHANGE_ENTRY"$'\n'"- ... and $remaining more location changes"
    fi
  fi
  
  # Add overall summary
  if [ $ADDED_COUNT -gt 0 ] && [ $REMOVED_COUNT -gt 0 ] && [ $MODIFIED_COUNT -gt 0 ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**Summary**: 🔄 Schedule updates: '$ADDED_COUNT' added, '$REMOVED_COUNT' removed, '$MODIFIED_COUNT' modified'
  elif [ $ADDED_COUNT -gt 0 ] && [ $MODIFIED_COUNT -gt 0 ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**Summary**: 🆕 '$ADDED_COUNT' new events added, '$MODIFIED_COUNT' events updated'
  elif [ $ADDED_COUNT -gt 0 ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**Summary**: 🆕 '$ADDED_COUNT' new events added to schedule'
  elif [ $REMOVED_COUNT -gt 0 ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**Summary**: ❌ '$REMOVED_COUNT' events removed from schedule'  
  elif [ $MODIFIED_COUNT -gt 0 ]; then
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**Summary**: 📝 '$MODIFIED_COUNT' events modified (details, timing, or location changes)'
  else
    CHANGE_ENTRY="$CHANGE_ENTRY"$'\n\n**Summary**: 📝 Schedule file updated (minor changes detected)'
  fi
  
  # Append the new entry to the end of the file
  echo "$CHANGE_ENTRY" >> updates.md
  
  echo "✅ Updated updates.md"
  
  
  # Clean up temporary files
  rm -f added_events.txt removed_events.txt modified_events.txt
  rm -f summary_changes.txt description_changes.txt time_changes.txt location_changes.txt
  
else
  echo ""
  echo "✅ No changes to commit"
fi

# Summary
echo ""
echo "🎯 Summary:"
if [ "$HAS_CHANGES" = "true" ]; then
  echo "Changes detected and logged to updates.md"
  echo "📊 Event changes: +$ADDED_COUNT/-$REMOVED_COUNT/~$MODIFIED_COUNT (added/removed/modified)"
  echo "📝 Property changes: $SUMMARY_CHANGES titles, $DESCRIPTION_CHANGES descriptions, $TIME_CHANGES times, $LOCATION_CHANGES locations"
  echo "💾 Size change: $SIZE_DIFF bytes"
  echo "⚠️  Manual git commit required"
else
  echo "No changes detected in schedule"
fi
echo ""
echo "Comparison completed at $(date '+%Y-%m-%d %H:%M:%S')"
