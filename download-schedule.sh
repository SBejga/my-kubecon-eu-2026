#!/bin/bash

# KubeCon Schedule Downloader
# Downloads the latest schedule from sched.com

set -e  # Exit on any error

echo "🔍 KubeCon EU 2026 Schedule Downloader"
echo "======================================"

# Set timezone to conference location (Amsterdam)
export TZ="Europe/Amsterdam"

echo "Current time (Amsterdam): $(date '+%A %H:%M')"
echo ""

# Download current schedule
echo "📥 Downloading latest schedule from sched.com..."

# Try download with browser headers and retry logic
DOWNLOAD_OCCURRED=false
for attempt in 1 2 3; do
  echo "Attempt $attempt/3..."
  
  # Check if we already have a current schedule file
  if [ -f "current-schedule.ics" ]; then
    echo "📄 Found existing current-schedule.ics, checking if remote file is newer..."
    # Get file size before potential download
    OLD_SIZE=$(wc -c < "current-schedule.ics" 2>/dev/null || echo "0")
  else
    echo "📄 No existing schedule file, downloading fresh copy..."
    OLD_SIZE=0
  fi
  
  # Use curl with conditional download (-z) and preserve timestamps (-R)
  HTTP_CODE=$(curl -w "%{http_code}" -o "current-schedule.ics" -f -L -z "current-schedule.ics" -R --compressed \
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
    "https://kccnceu2026.sched.com/all.ics" 2>/dev/null)
  
  CURL_EXIT_CODE=$?
  
  if [ $CURL_EXIT_CODE -eq 0 ]; then
    # Check if file was actually updated by comparing size
    NEW_SIZE=$(wc -c < "current-schedule.ics" 2>/dev/null || echo "0")
    
    if [ "$HTTP_CODE" = "304" ] || [ "$OLD_SIZE" = "$NEW_SIZE" ] && [ -f "current-schedule.ics" ]; then
      echo "✅ Remote file not modified - no download needed"
      DOWNLOAD_OCCURRED=false
    else
      echo "✅ Download successful (HTTP $HTTP_CODE)"
      DOWNLOAD_OCCURRED=true
    fi
    break
  else
    echo "❌ Attempt $attempt failed (exit code: $CURL_EXIT_CODE, HTTP: $HTTP_CODE)"
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
done

# Get file size for logging
CURRENT_SIZE=$(wc -c < current-schedule.ics)
echo "Downloaded schedule size: $CURRENT_SIZE bytes"

# If no download occurred, we can exit early
if [ "$DOWNLOAD_OCCURRED" = "false" ]; then
  echo ""
  echo "✅ Remote file not modified - no new download"
  echo ""
  echo "🎯 Summary: No remote changes detected"
  echo ""
  echo "Download completed at $(date '+%Y-%m-%d %H:%M:%S')"
  exit 0
fi

echo ""
echo "🎯 Summary: Download completed successfully"
echo "📁 File: current-schedule.ics ($CURRENT_SIZE bytes)"
echo ""
echo "Download completed at $(date '+%Y-%m-%d %H:%M:%S')"