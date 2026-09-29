# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-29

## In progress

- Nothing yet.

## Up next

- #2 Project setup (`ready`, tasks #17, #18, #19)

## Backlog by epic

| Epic | Stories (in order) |
|---|---|
| #1 Foundation | #2 Project setup (`ready`) → #3 Home screen with a big start button |
| #4 Focus timer | #5 Start, pause and cancel a session → #6 Timer survives app switch and restart → #7 Configurable durations and breaks (Pomodoro cycle) |
| #20 Distraction blocking | #21 Choose apps to block → #22 Block selected apps during a focus session → #23 Hold back notifications of blocked apps |
| #8 Labels and goals | #9 Labels for sessions → #10 Daily focus goal with progress ring |
| #11 Statistics | #12 Focus time per day and week → #13 Breakdown by label → #14 Streaks |
| #15 Data safety | #16 Backup and export |

All stories are `backlog` unless marked otherwise.

## Recently done

- Decision: distraction blocking is strict while a session runs, cancelling releases the apps; may use accessibility + notification access
- New epic #20 Distraction blocking (app blocking during sessions)
- Flutter project scaffolded (Scaffold workflow), CI green on `main`
- Labels, epics and stories created as issues
- Repo created with CLAUDE.md, STATUS.md, Flutter skill and CI

## Open decisions (user only)

- Does leaving the app during a session count as cancelling, or only the cancel button?
- Optional ambient sounds (rain, white noise) – yes/no?
- Android only, or iOS later?
