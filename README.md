# My KubeCon EU 2026 schedule

This is my schedule for KubeCon EU 2026. It includes the sessions I plan to attend, as well as some notes on each session.

## Automated Schedule Monitoring

This repository includes an automated GitHub Actions workflow that monitors the KubeCon EU 2026 schedule for changes and updates.

### How it works

The **Schedule Monitor** GitHub Action (`schedule-monitor.yml`) automatically:

- **🕒 Runs every hour** to check for schedule changes
- **📥 Downloads** the latest schedule from https://kccnceu2026.sched.com/all.ics
- **🔍 Compares** it with the baseline schedule to detect changes
- **📝 Logs changes** to [updates.md](updates.md) with detailed information including:
  - Event count changes (additions/removals)
  - File size differences
  - Timestamps in Amsterdam timezone
  - List of new events when applicable
- **📦 Archives** each version with timestamps (e.g., `2026-03-22-1408-all.ics`)
- **🚀 Commits & pushes** changes automatically to the main branch

### Benefits

- **No manual checking needed** - get notified of schedule updates automatically
- **Complete history** - every schedule version is archived with timestamps
- **Detailed change tracking** - see exactly what changed and when
- **Timezone awareness** - all timestamps use Amsterdam time (conference timezone)

You can trigger the workflow manually from the Actions tab or wait for the hourly automatic runs.

## Build & Usage

All Events available via: https://kccnceu2026.sched.com/all.ics 

My private sched availabble via https://kccnceu2026.sched.com/sebastianbejga.ics (auth required)