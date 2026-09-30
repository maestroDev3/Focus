# Focus – How Claude works in this repo

Android app (Flutter): a clean, distraction-free Pomodoro focus timer with daily goals, labels and statistics.
Claude works in this repo **autonomously**. This file is binding.

## Language

- Everything in the repo is **English**: code, comments, UI texts, docs, issues,
  commit messages and PR descriptions (the app is meant to be marketable
  internationally).
- UI texts go through Flutter localization (`flutter_localizations` + ARB files,
  `app_en.arb` as the template) from day one, so more languages can be added later.
- Chat with the user may be in German; answer in the user's language.

## Product vision

Focus is a calm, minimal focus timer. Start a session (e.g. 25 minutes), take
short and long breaks following the Pomodoro rhythm, and optionally tag what you
worked on. While a session runs, apps you selected (e.g. social media) are
blocked and their notifications held back until the session ends. A daily
focus goal and simple statistics (per day, week and label, plus streaks) show
your progress. No gamification, no clutter – just focus.
Domain terms:

- **Session** – `FocusSession` – planned duration, start, end, label, outcome (sealed `SessionOutcome`: completed, cancelled)
- **Break** – `BreakSession` – short/long break following the Pomodoro rule
- **Label** – `FocusLabel` – what the session was about (e.g. “Study”, “Work”)
- **Daily goal** – `DailyGoal` – target focus minutes per day

## Structure: Epic → Story → Task

Everything lives in GitHub issues, linked via sub-issues:

| Level | Label | Content |
|---|---|---|
| Epic | `epic` | Big goal; stories as sub-issues, order listed in the description |
| Story | `story` | User-visible feature; tasks as sub-issues |
| Task | `task` | Exactly one PR, TDD, testable acceptance criteria |

Story status (label, exactly one; done = closed):
- `backlog` – idea, roughly described, **no tasks yet**
- `ready` – refined, tasks with acceptance criteria exist
- `in-progress` – currently being implemented (only one story at a time)

Rules:
- Tasks are only written when a story moves from `backlog` to `ready`.
- New ideas from the user become a `backlog` story in the matching epic.
- The user decides which story comes next; without guidance, take the next
  `ready` story in epic order.

## First start (once)

While there are no issues yet:
1. Create labels: `epic`, `story`, `task`, `backlog`, `ready`, `in-progress`.
2. Create the epics and stories from `STATUS.md` (“Planned epics”) as issues,
   stories as sub-issues of their epic, all stories `backlog`.
3. Run the **Scaffold** workflow (`.github/workflows/scaffold.yml`) via
   `workflow_dispatch` → generates the Flutter project. CI must be green afterwards.
4. Refine the first story of the “Foundation” epic to `ready`.
5. Update `STATUS.md` with the real issue numbers.

## Keeping the status (`STATUS.md`)

`STATUS.md` is the short summary of the project state. The user reads it as
context in a Claude project. It must always match the issues.

- Claude updates `STATUS.md` whenever any of it changes: a story changes status
  (`backlog`/`ready`/`in-progress`) or is closed, a new story or epic, order
  changes, a decision is made.
- Content: In progress · Up next · Backlog by epic · Recently done (max. 5,
  newest first) · Open decisions · “Last updated” date.
- When closing a story, the update belongs in the story's last PR. Pure status
  changes without a PR: direct commit to `main` (`docs: update status`).
- Keep it short: number + title, no task details.
- `CLAUDE.md` and `STATUS.md` are also stored as docs in the Claude project
  “Focus”. When the session is attached to that project, update the project
  copy whenever the file changes on `main`.

## Workflow: Story → sub-issues

1. Every functional requirement is a **story** (issue with label `story`).
2. The story is split into **sub-issues** (label `task`), linked via GitHub's
   sub-issue feature. Each sub-issue is small enough for one PR and contains
   **acceptance criteria as testable statements**.
3. Independent sub-issues may be worked on in parallel (subagents).
   Dependencies are listed in the issue under “Depends on”.
4. The story is closed when all its sub-issues are closed.

## TDD per sub-issue (mandatory)

1. Branch `task/<issue-nr>-<short-name>` from the current `main`.
2. **Red:** First write tests for the acceptance criteria, commit
   (`test: … (#nr)`), push and open the PR right away with “(WIP)” in the
   title (CI runs only on pull requests and `main`; no draft PRs – Claude's
   environment can't mark them ready). CI must fail because of these tests; wait
   for the red run to finish before pushing the next commit (a newer push
   cancels it).
3. **Green:** Write the minimal code until `flutter test` passes (`feat: … (#nr)`).
4. **Refactor:** Clean up, tests stay green (`refactor: … (#nr)`).
5. Finish the PR: final title without “(WIP)”, `Closes #nr` in the body.
   Description: what, why, which tests.

## Merging

- Claude may **squash-merge PRs into `main` itself** once CI (analyze + test)
  is green. Never merge with red or running CI.
- Larger epics may be collected on a branch `epic/<name>`; it is merged into
  `main` only after green CI and a test by the user (APK on the phone).
- No direct push to `main` except for repo infrastructure (CI, this file,
  `STATUS.md`).
- Delete the branch after merging.

## Tech

**Binding:** Before any work on `.dart` files, tests, `pubspec.yaml` or Android
configuration, load and follow the skill `.claude/skills/flutter-dart/SKILL.md`
(architecture, state, style, widgets, tests, definition of done).

- Flutter (stable), Dart, Android as the only target platform for now.
- Package name `focus_timer`, organization `de.maestrodev`.
- Structure: `lib/domain` (pure Dart logic, no Flutter imports),
  `lib/data` (repositories, persistence, platform services), `lib/ui` (screens, widgets),
  `lib/l10n` (ARB files).
- Domain logic is pure Dart and covered by unit tests; UI by widget tests.
  Time is always passed in via an injectable `Clock`, never `DateTime.now()`
  directly in logic.
- Data access only through repository interfaces, so a backend or sync can be
  added later.
- Permissions: `POST_NOTIFICATIONS` (session finished); for distraction blocking
  an `AccessibilityService` (blocked app in foreground) and a
  `NotificationListenerService` (hold back notifications) – both approved by
  the user. App list via a launcher-intent `<queries>` entry, not
  `QUERY_ALL_PACKAGES`. No foreground service as long as the timestamp-based
  approach is enough.
- `flutter analyze` must report no issues.

## Environment note

Flutter cannot be installed in Claude's cloud environment (download servers
blocked). Tests therefore run via **GitHub Actions** (`.github/workflows/ci.yml`);
results are read via the GitHub API (on failure, CI posts the output as a
commit comment).

## Open decisions (only the user decides)

- None at the moment.

## Decisions (made by the user)

- 2026-09-29 – Distraction blocking may use the accessibility service and
  notification access.
- 2026-09-29 – Distraction blocking is **strict while a session runs**
  (including pauses): no temporary unlock, the block list can't be reduced.
  Apps and their notifications are released as soon as the session ends –
  timer finished or session deliberately cancelled.
- 2026-09-30 – Leaving the app does **not** cancel a session; only the
  cancel button (“End session”) does.
- 2026-09-30 – Android first. iOS comes later, once the Android app is
  complete; until then no iOS-specific work.
- 2026-09-30 – Design: “Noir & Champagne” (dark, champagne accent; ivory in
  light mode) with the **Ring** app icon, noir splash with “FOCUS” intro and a
  subtle champagne glow behind the main screens.
- 2026-09-30 – Ambient sounds: yes (bundled sounds, no internet) – story #122
  in epic #123 “Final features”.
