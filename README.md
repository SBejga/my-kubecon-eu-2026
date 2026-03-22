# My KubeCon EU 2026 schedule

This is my schedule for KubeCon EU 2026. It includes the sessions I plan to attend, as well as some notes on each session.

## Automated Schedule Monitoring

This repository includes both a GitHub Actions workflow and a local bash script for monitoring the KubeCon EU 2026 schedule for changes.

### GitHub Actions Workflow

The **Schedule Monitor** GitHub Action (`schedule-monitor.yml`) automatically:

- **🕒 Runs every 4 hours** to check for schedule changes
- **📥 Downloads** the latest schedule from https://kccnceu2026.sched.com/print (HTML format)
- **🔍 Compares** it with the baseline schedule to detect changes
- **📝 Logs changes** to [updates.md](updates.md) with detailed information
- **📦 Archives** each version with timestamps (e.g., `2026-03-22-1408-print.html`)
- **🚀 Commits & pushes** changes automatically to the main branch

### Local Script

The local bash script (`check-ics-updates.sh`) can be run manually and:

- **📥 Downloads** the latest schedule from https://kccnceu2026.sched.com/all.ics (ICS format)
- **⚡ Smart downloading** - only downloads when remote file has been modified
- **💾 Keeps local copy** - maintains `current-schedule.ics` for future comparisons
- **🔍 Compares** it with the baseline schedule to detect changes  
- **📝 Logs changes** to [updates.md](updates.md) with detailed information
- **📦 Archives** each version with timestamps (e.g., `2026-03-22-1408-all.ics`)
- **⚠️ Requires manual commit** - files are prepared but not automatically committed

### Running the monitor

```bash
# Make sure the script is executable (one time setup)
chmod +x check-ics-updates.sh

# Run the monitor
./check-ics-updates.sh

# If changes are detected, manually commit them:
git add updates.md *-all.ics
git commit -m "📅 Schedule update detected"
git push
```

### Benefits

- **Automated monitoring** - GitHub Actions runs every 4 hours and commits changes automatically  
- **Manual verification** - Local script allows you to review changes before committing
- **Efficient downloads** - Only downloads when remote files have actually changed
- **Complete history** - every schedule version is archived with timestamps
- **Detailed change tracking** - see exactly what changed and when
- **Timezone awareness** - all timestamps use Amsterdam time (conference timezone)
- **Dual format support** - HTML (GitHub Actions) and ICS (local script) monitoring
- **Local control** - no dependency on GitHub Actions infrastructure

The script includes retry logic and browser-like headers to avoid rate limiting issues.

## Build & Usage

All Events available via: https://kccnceu2026.sched.com/all.ics 

My private sched availabble via https://kccnceu2026.sched.com/sebastianbejga.ics (auth required)