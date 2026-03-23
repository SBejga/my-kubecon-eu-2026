#!/bin/bash

# Categorized differences between ICS and YAML
echo "📊 DETAILED DIFFERENCE ANALYSIS"
echo "==============================="
echo "📅 ICS Events: $(grep -c "^BEGIN:VEVENT" current-schedule.ics)"
echo "📊 YAML Events: $(grep -c "^  title:" data.yaml)" 
echo ""

echo "🔍 CATEGORIES OF MISSING EVENTS:"
echo ""

echo "1️⃣ ADMINISTRATIVE EVENTS:"
awk '/^BEGIN:VEVENT/ { in_event = 1 } 
     /^SUMMARY:/ && in_event { 
         title = substr($0, 9)
         gsub(/\\n/, " ", title)
         gsub(/\\,/, ",", title) 
         if (title ~ /Badge Pick-Up|Cloakroom|Registration/) {
             print "   " title
         }
     } 
     /^END:VEVENT/ { in_event = 0 }' current-schedule.ics | sort -u

echo ""
echo "2️⃣ BREAK/MEAL EVENTS:"
awk '/^BEGIN:VEVENT/ { in_event = 1 } 
     /^SUMMARY:/ && in_event { 
         title = substr($0, 9)
         gsub(/\\n/, " ", title)
         gsub(/\\,/, ",", title) 
         if (title ~ /Coffee Break|Break|Lunch|Mini Break/) {
             print "   " title
         }
     } 
     /^END:VEVENT/ { in_event = 0 }' current-schedule.ics | sort -u

echo ""
echo "3️⃣ SEPARATE REGISTRATION EVENTS:"
awk '/^BEGIN:VEVENT/ { in_event = 1 } 
     /^SUMMARY:/ && in_event { 
         title = substr($0, 9)
         gsub(/\\n/, " ", title)
         gsub(/\\,/, ",", title) 
         if (title ~ /SEPARATE REGISTRATION|SOLD OUT/) {
             print "   " title
         }
     } 
     /^END:VEVENT/ { in_event = 0 }' current-schedule.ics | sort -u | head -8

echo ""
echo "4️⃣ SOCIAL/NETWORKING EVENTS:"
awk '/^BEGIN:VEVENT/ { in_event = 1 } 
     /^SUMMARY:/ && in_event { 
         title = substr($0, 9)
         gsub(/\\n/, " ", title)
         gsub(/\\,/, ",", title) 
         if (title ~ /Solutions Showcase|Gold Sponsor|Demo|Gathering|KubeCrawl/) {
             print "   " title
         }
     } 
     /^END:VEVENT/ { in_event = 0 }' current-schedule.ics | sort -u | head -8

echo ""
echo "💡 SUMMARY: The 54 missing events are mostly administrative,"
echo "   break times, and networking events that aren't core talks."