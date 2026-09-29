# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-29

## In progress

- Nothing yet – the repo only contains the working rules, skill and CI.

## Up next

- “First start” from CLAUDE.md: create labels, epics and stories as issues,
  run the Scaffold workflow, refine the first story “Project setup”.

## Planned epics (no issue numbers yet)

| Epic | Stories (in order) |
|---|---|
| Foundation | Project setup (scaffold, green CI, theme, `pumpApp`) → Home screen with a big start button |
| Focus timer | Start, pause and cancel a session → Timer survives app switch and restart (notification when done) → Configurable durations and breaks (Pomodoro cycle) |
| Labels and goals | Labels for sessions → Daily focus goal with progress ring |
| Statistics | Focus time per day and week → Breakdown by label → Streaks (days in a row with goal reached) |
| Data safety | Backup and export |

## Recently done

- Repo created with CLAUDE.md, STATUS.md, Flutter skill and CI

## Open decisions (user only)

- Does leaving the app during a session count as cancelling, or only the cancel button?
- Optional ambient sounds (rain, white noise) – yes/no?
- Android only, or iOS later?
