# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-30

## In progress

- #22 Block selected apps during a focus session (on `epic/distraction-blocking`)

## Up next

1. #21 → #22 → #23 Distraction blocking (native Android; collected on `epic/distraction-blocking`, merged after a test on the phone).
2. #9 Labels → #10 Daily goal → #12 → #13 → #14 Statistics → #16 Backup.

## Backlog by epic

| Epic | Stories (in order) |
|---|---|
| #4 Focus timer | #6 Timer survives app switch and restart (`backlog`, waits for a decision) → ~~#7 Configurable durations and breaks~~ (done) |
| #20 Distraction blocking | ~~#21 Choose apps to block~~ (done on epic branch) → #22 Block selected apps during a focus session (`in-progress`) → #23 Hold back notifications of blocked apps (`ready`) |
| #8 Labels and goals | #9 Labels for sessions (`ready`) → #10 Daily focus goal with progress ring (`ready`) |
| #11 Statistics | #12 Focus time per day and week (`ready`) → #13 Breakdown by label (`ready`) → #14 Streaks (`ready`) |
| #15 Data safety | #16 Backup and export (`ready`) |

## Recently done

- #21 Choose apps to block (on `epic/distraction-blocking`)
- #7 Configurable durations and breaks (Pomodoro settings, breaks, settings screen)
- Decision: repository is public (free GitHub Actions minutes)
- #5 Start, pause and cancel a session (FocusSession, repository, FocusTimer, session screen)
- #3 Home screen with a big start button – epic #1 Foundation complete

## Open decisions (user only)

- Design direction: A “Noir & Champagne” is implemented as default; B “Ivory Atelier” and C “Emerald Salon” are alternatives on the design canvas.
- Does leaving the app during a session count as cancelling, or only the cancel button?
- Optional ambient sounds (rain, white noise) – yes/no?
- Android only, or iOS later?
