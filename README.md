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

### Local Scripts

The local monitoring system consists of three modular bash scripts:

#### 1. Main Orchestrator (`check-ics-updates.sh`)
The main entry point that:
- **🎯 Orchestrates** the complete monitoring workflow
- **📥 Calls** download-schedule.sh to fetch the latest schedule
- **🔍 Calls** compare-schedule.sh to analyze changes
- **⚠️ Requires manual commit** - files are prepared but not automatically committed

#### 2. Download Script (`download-schedule.sh`)
Specialized downloader that:
- **📥 Downloads** the latest schedule from https://kccnceu2026.sched.com/all.ics (ICS format)
- **⚡ Smart downloading** - only downloads when remote file has been modified
- **💾 Keeps local copy** - maintains `current-schedule.ics` for future comparisons
- **🔄 Conditional downloads** - uses curl's `-z` flag to check modification times
- **🕸️ Browser simulation** - includes proper headers to avoid blocking

#### 3. Comparison Script (`compare-schedule.sh`)
Analysis engine that:
- **🔍 Compares** downloaded schedule with the baseline
- **📝 Logs changes** to [updates.md](updates.md) with detailed information
- **📦 Archives** each version with timestamps (e.g., `2026-03-22-1408-all.ics`)
- **📊 Event counting** - tracks additions, removals, and modifications
- **🏷️ Change categorization** - identifies new events vs. updates

### Running the monitor

```bash
# Make sure the scripts are executable (one time setup)
chmod +x *.sh

# Run the complete monitoring workflow
./check-ics-updates.sh

# Or run individual components:
./download-schedule.sh    # Just download
./compare-schedule.sh     # Just compare (requires existing current-schedule.ics)

# If changes are detected, manually commit them:
git add updates.md *-all.ics
git commit -m "📅 Schedule update detected"
git push
```

### Benefits

- **Automated monitoring** - GitHub Actions runs every 4 hours and commits changes automatically  
- **Manual verification** - Local scripts allow you to review changes before committing
- **Modular architecture** - Separate scripts for downloading and comparing enable flexible usage
- **Efficient downloads** - Only downloads when remote files have actually changed
- **Complete history** - every schedule version is archived with timestamps
- **Detailed change tracking** - see exactly what changed and when
- **Timezone awareness** - all timestamps use Amsterdam time (conference timezone)
- **Dual format support** - HTML (GitHub Actions) and ICS (local scripts) monitoring
- **Local control** - no dependency on GitHub Actions infrastructure
- **Component isolation** - Download failures don't affect comparison logic

The scripts include retry logic and browser-like headers to avoid rate limiting issues.

## Build & Usage

All Events available via: https://kccnceu2026.sched.com/all.ics 

My private sched availabble via https://kccnceu2026.sched.com/sebastianbejga.ics (auth required)