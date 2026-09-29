# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-29

## In progress

- #5 Start, pause and cancel a session (tasks #36–#39)

## Up next

- #7 Configurable durations and breaks (needs refinement; #6 waits for the open decision about leaving the app)

## Backlog by epic

| Epic | Stories (in order) |
|---|---|
| #4 Focus timer | #5 Start, pause and cancel a session (`in-progress`) → #6 Timer survives app switch and restart → #7 Configurable durations and breaks (Pomodoro cycle) |
| #20 Distraction blocking | #21 Choose apps to block → #22 Block selected apps during a focus session → #23 Hold back notifications of blocked apps |
| #8 Labels and goals | #9 Labels for sessions → #10 Daily focus goal with progress ring |
| #11 Statistics | #12 Focus time per day and week → #13 Breakdown by label → #14 Streaks |
| #15 Data safety | #16 Backup and export |

All stories are `backlog` unless marked otherwise.

## Recently done

- #3 Home screen with a big start button – epic #1 Foundation complete
- #27 Luxury look: Noir & Champagne (fonts, dark/light palettes, pill buttons)
- #2 Project setup (Clock/dayOf, localization, app shell with light/dark theme, `pumpApp`)
- Decision: distraction blocking is strict while a session runs, cancelling releases the apps; may use accessibility + notification access
- New epic #20 Distraction blocking (app blocking during sessions)

## Open decisions (user only)

- Design direction: A “Noir & Champagne” is implemented as default; B “Ivory Atelier” and C “Emerald Salon” are alternatives on the design canvas.
- Does leaving the app during a session count as cancelling, or only the cancel button?
- Optional ambient sounds (rain, white noise) – yes/no?
- Android only, or iOS later?
