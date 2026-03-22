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

The local bash script (`monitor-schedule.sh`) can be run manually and:

- **📥 Downloads** the latest schedule from https://kccnceu2026.sched.com/all.ics (ICS format)
- **🔍 Compares** it with the baseline schedule to detect changes  
- **📝 Logs changes** to [updates.md](updates.md) with detailed information
- **📦 Archives** each version with timestamps (e.g., `2026-03-22-1408-all.ics`)
- **🚀 Commits & pushes** changes automatically to the main branch

### Running the monitor

```bash
# Make sure the script is executable (one time setup)
chmod +x monitor-schedule.sh

# Run the monitor
./monitor-schedule.sh
```

### Benefits

- **Run when needed** - execute manually or set up your own cron schedule
- **Complete history** - every schedule version is archived with timestamps
- **Detailed change tracking** - see exactly what changed and when
- **Timezone awareness** - all timestamps use Amsterdam time (conference timezone)
- **Local control** - no dependency on GitHub Actions infrastructure

The script includes retry logic and browser-like headers to avoid rate limiting issues.

## Build & Usage

All Events available via: https://kccnceu2026.sched.com/all.ics 

My private sched availabble via https://kccnceu2026.sched.com/sebastianbejga.ics (auth required)