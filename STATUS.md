# Status

Current project state for planning and Claude projects. Maintained by Claude
after every status change (see CLAUDE.md, “Keeping the status”).
The GitHub issues are authoritative; this file is the summary.

**Last updated:** 2026-09-30

## In progress

- Nothing. All stories without an open decision are done.
- **Waiting for your phone test:** PR #82 – epic #20 Distraction blocking, already merged with the latest `main`, so its APK (Actions artifact `focus_timer-apk` of the PR) contains the complete app. Test steps in the PR.

## Up next

1. After your test: merge PR #82 into `main`.
2. #96 Include paused apps in backups (`backlog`, small follow-up after the merge).
3. #6 once the decision about leaving the app is made.

## Backlog by epic

| Epic | Stories (in order) |
|---|---|
| #4 Focus timer | #6 Timer survives app switch and restart (`backlog`, waits for a decision) → ~~#7 Configurable durations and breaks~~ (done) |
| #20 Distraction blocking | #21 → #22 → #23 done on `epic/distraction-blocking`, PR #82 waits for the phone test → #96 Include paused apps in backups (`backlog`) |

## Recently done

- #16 Backup and export – epic #15 Data safety complete
- #14 Streaks – epic #11 Statistics complete
- #13 Breakdown by label (week / month)
- #12 Focus time per day and week (statistics screen)
- #10 Daily focus goal with progress ring – epic #8 Labels and goals complete

## Open decisions (user only)

- Design direction: A “Noir & Champagne” is implemented as default; B “Ivory Atelier” and C “Emerald Salon” are alternatives on the design canvas.
- Does leaving the app during a session count as cancelling, or only the cancel button?
- Optional ambient sounds (rain, white noise) – yes/no?
- Android only, or iOS later?
