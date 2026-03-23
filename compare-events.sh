#!/bin/bash

# Compare events between ICS and YAML files
# Shows events present in ICS but missing from data.yaml

ICS_FILE="current-schedule.ics"
YAML_FILE="data.yaml"

echo "🔍 Comparing events between ICS and YAML files..."
echo "📅 ICS file: $ICS_FILE"
echo "📊 YAML file: $YAML_FILE"
echo ""

# Check if files exist
if [[ ! -f "$ICS_FILE" ]]; then
    echo "❌ Error: $ICS_FILE not found"
    exit 1
fi

if [[ ! -f "$YAML_FILE" ]]; then
    echo "❌ Error: $YAML_FILE not found"
    exit 1
fi

# Extract event titles from ICS file
echo "🔍 Extracting events from ICS..."
ics_events=$(mktemp)
awk '
BEGIN { in_event = 0; summary = "" }
/^BEGIN:VEVENT/ { in_event = 1; summary = "" }
/^END:VEVENT/ { 
    if (in_event && summary != "") {
        print summary
    }
    in_event = 0; summary = ""
}
/^SUMMARY:/ && in_event {
    summary = substr($0, 9)  # Remove "SUMMARY:" prefix
    # Handle escaped characters
    gsub(/\\n/, "\n", summary)
    gsub(/\\,/, ",", summary)
    gsub(/\\;/, ";", summary)
}
' "$ICS_FILE" > "$ics_events"

ics_count=$(wc -l < "$ics_events")
echo "   Found $ics_count events in ICS"

# Extract event titles from YAML file
echo "🔍 Extracting events from YAML..."
yaml_events=$(mktemp)
awk '
/^  title:/ {
    title = substr($0, 9)  # Remove "  title: " prefix (8 chars + space)
    # Remove leading/trailing quotes if present
    gsub(/^["'"'"']|["'"'"']$/, "", title)
    print title
}
' "$YAML_FILE" > "$yaml_events"

yaml_count=$(wc -l < "$yaml_events")
echo "   Found $yaml_count events in YAML"
echo ""

# Find events in ICS but not in YAML
echo "🔍 Finding events in ICS but missing from YAML..."
missing_events=$(mktemp)
missing_count=0

while IFS= read -r ics_event; do
    # Normalize both for comparison (remove extra spaces, case-insensitive)
    ics_normalized=$(echo "$ics_event" | sed 's/[[:space:]]\+/ /g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')
    
    found=false
    while IFS= read -r yaml_event; do
        yaml_normalized=$(echo "$yaml_event" | sed 's/[[:space:]]\+/ /g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')
        
        # Check for exact match or partial match (in case titles are slightly different)
        if [[ "$ics_normalized" == "$yaml_normalized" ]] || [[ "$yaml_normalized" == *"$ics_normalized"* ]] || [[ "$ics_normalized" == *"$yaml_normalized"* ]]; then
            found=true
            break
        fi
    done < "$yaml_events"
    
    if [[ "$found" == false ]]; then
        echo "$ics_event" >> "$missing_events"
        ((missing_count++))
    fi
done < "$ics_events"

# Display results
echo "📊 COMPARISON RESULTS:"
echo "====================="
echo "Events in ICS:        $ics_count"
echo "Events in YAML:       $yaml_count"
echo "Missing from YAML:    $missing_count"
echo ""

if [[ $missing_count -gt 0 ]]; then
    echo "❌ EVENTS IN ICS BUT MISSING FROM YAML:"
    echo "========================================"
    
    counter=1
    while IFS= read -r missing_event; do
        echo "$counter. $missing_event"
        ((counter++))
    done < "$missing_events"
    echo ""
    
    echo "💡 TIP: These events might need to be added to $YAML_FILE"
    echo "    or they might be administrative events that can be ignored."
else
    echo "✅ All ICS events are represented in YAML file!"
fi

# Also check for events in YAML but not in ICS (reverse check)
echo ""
echo "🔄 Reverse check: Events in YAML but missing from ICS..."
reverse_missing=$(mktemp)
reverse_count=0

while IFS= read -r yaml_event; do
    yaml_normalized=$(echo "$yaml_event" | sed 's/[[:space:]]\+/ /g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')
    
    found=false
    while IFS= read -r ics_event; do
        ics_normalized=$(echo "$ics_event" | sed 's/[[:space:]]\+/ /g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')
        
        if [[ "$yaml_normalized" == "$ics_normalized" ]] || [[ "$ics_normalized" == *"$yaml_normalized"* ]] || [[ "$yaml_normalized" == *"$ics_normalized"* ]]; then
            found=true
            break
        fi
    done < "$ics_events"
    
    if [[ "$found" == false ]]; then
        echo "$yaml_event" >> "$reverse_missing"
        ((reverse_count++))
    fi
done < "$yaml_events"

if [[ $reverse_count -gt 0 ]]; then
    echo "⚠️  EVENTS IN YAML BUT MISSING FROM ICS:"
    echo "========================================"
    
    counter=1
    while IFS= read -r missing_event; do
        echo "$counter. $missing_event"
        ((counter++))
    done < "$reverse_missing"
    echo ""
    echo "💡 TIP: These might be manually added events or the ICS might be outdated."
else
    echo "✅ All YAML events are present in ICS file!"
fi

# Cleanup temporary files
rm -f "$ics_events" "$yaml_events" "$missing_events" "$reverse_missing"

echo ""
echo "🎯 Summary: $missing_count events need attention (ICS→YAML), $reverse_count events are YAML-only"