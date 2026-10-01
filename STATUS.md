# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-10-01

## In progress

- #107 Updates install over the previous version – release key created from your secret, signed releases since build 188; waiting for your update test with build 193.

## Up next

1. #96 Include paused apps in backups (`backlog`).
2. #6 Timer survives app switch and restart → #105 Live countdown in the notification bar.
3. Epic #123 Final features: #119 Mindful opening of paused apps first.

## Backlog by initiative → epic

**#138 Focus experience**

| Epic | State | Stories (in order) |
|---|---|---|
| #4 Focus timer | 2 of 4 closed | #6 Timer survives app switch and restart (`backlog`) → #105 Live countdown in the notification bar (`backlog`) |
| #123 Final features | 0 of 4 closed | #119 Mindful opening of paused apps → #120 Home screen widget → #121 Intention and reflection → #122 Ambient sounds (all `backlog`) |

**#139 Distraction blocking**

| Epic | State | Stories (in order) |
|---|---|---|
| #20 Distraction blocking | 4 of 5 closed | #96 Include paused apps in backups (`backlog`) |

**#140 Release & platform**

| Epic | State | Stories (in order) |
|---|---|---|
| #1 Foundation | 4 of 5 closed | #107 Updates install over the previous version (`in-progress`) |

## Recently done

- Planning structure Initiative → Epic → Story → Task set up: initiatives #138–#140, issue templates, rules in CLAUDE.md
- Epic #115 Focus times done: #116 plan focus times, #117 blocking during focus times, #118 reminder with one-tap start
- Decision: ambient sounds yes; new epic #123 Final features (#119–#122) next to #115 Focus times
- #112 App icons in the paused apps list
- Epic #20 Distraction blocking merged into `main` (PR #82, on your request before a dedicated phone test)

## Open decisions (user only)

- New initiatives #138 Focus experience, #139 Distraction blocking, #140 Release & platform – please confirm or re-sort.
- Epic #123 “Final features” is a grab-bag without one outcome (0 of 4 done). Proposal: split into outcome-based epics, e.g. “Mindful access to paused apps” (#119, under #139) and “Session ritual” (#121, #122) plus “Home screen widget” (#120) under #138 – or keep #123 as is.
