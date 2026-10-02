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

## Structure: Initiative → Epic → Story → Task

Everything lives in GitHub issues, linked via sub-issues and told apart by labels
(personal account → no issue types):

| Level | Label | Content |
|---|---|---|
| Initiative | `initiative` | Long-lived theme; epics as sub-issues |
| Epic | `epic` | Finite piece of work with an outcome; stories as sub-issues, order listed in the description |
| Story | `story` | User-visible feature; tasks as sub-issues |
| Task | `task` | Exactly one PR, TDD, testable acceptance criteria |

Story status (label, exactly one; done = closed):
- `backlog` – idea, roughly described, **no tasks yet**
- `ready` – refined, tasks with acceptance criteria exist
- `in-progress` – currently being implemented (only one story at a time)

Rules:
- Tasks are only written when a story moves from `backlog` to `ready`.
- When a story is closed, remove its status label (closed = done, no label).
- The user decides which story comes next; without guidance, take the next
  `ready` story in epic order.

### Initiatives

- Long-lived themes with a target picture: Why · Value · In scope / Out of scope ·
  Epics · “Done when” (1–3 rough statements). No status label, no order, no
  progress value (GitHub's progress bar only counts direct children – ignore it).
- Current initiatives: **Focus experience**, **Distraction blocking**,
  **Release & platform** (numbers in `STATUS.md`).
- Without open epics an initiative is **dormant** and stays open.
- **Only the user closes initiatives.** Claude suggests it when all epics are
  closed and “Done when” is met. Follow-up work to a closed initiative becomes a
  **new** initiative with its own outcome-based title (no “v2”) and “Related: #old”.

### Epics

- **Finite.** Outcome-based title, never “… II” or numbers. Closed as soon as all
  stories are closed; the closing comment names follow-up epics, if any.
- **Exactly one initiative as parent**, chosen by main value. If it also fits a
  second one, that one gets “See also: #nr”. Closed epics may be attached to an
  open initiative – that is not reopening.
- No grab-bag epics (“Misc”, “Final features”): every epic has one outcome.

### All levels

- **Closed stays closed.** Claude **never** reopens a closed issue – initiative,
  epic, story or task. New work on something done becomes a **new** issue with
  “Related: #nr”.
- **No orphans:** every story has exactly one epic, every epic exactly one
  initiative (as sub-issue parent).
- **New idea:** `backlog` story in an open epic that pursues exactly this
  outcome → otherwise a new epic in the matching open initiative → otherwise a
  new initiative. Claude creates it right away (no blocking question) and lists
  everything new above story level in `STATUS.md` under “Open decisions”
  (“created – please confirm or re-sort”).

### Issue templates

Every issue says **what it is for**, **what value it brings** and **when it is
done**. Templates: `.github/ISSUE_TEMPLATE/` (initiative, epic, story, task). When
creating issues via the API, Claude always follows that outline and sets the
labels itself (template `labels:` only apply in the browser).

- **Story:** goal as “As a user I want …, so that …”, value, out of scope,
  **acceptance criteria from the user's point of view** (checkable on the phone),
  decisions (links to “Decisions” below), tasks, `Epic: #nr`.
- **Task:** purpose (which story criterion), implementation, **technical
  acceptance criteria – each gets at least one test**, depends on, `Story: #nr`.
  Definition of done by reference, not copied.
- **Epic:** outcome, value, scope / out of scope, stories (order), “Done when”
  as a reference to “Merging”, `Initiative: #nr`.
- No Gherkin (with TDD the tests are the given/when/then); for behaviour use
  “When …, then …”.
- **Catching up:** backlog stories get the full template when moving to
  `ready`. Closed issues are never edited.

## First start (once)

While there are no issues yet:
1. Create labels: `initiative`, `epic`, `story`, `task`, `backlog`, `ready`, `in-progress`.
2. Create the epics and stories from `STATUS.md` (“Planned epics”) as issues,
   stories as sub-issues of their epic, all stories `backlog`.
3. Run the **Scaffold** workflow (`.github/workflows/scaffold.yml`) via
   `workflow_dispatch` → generates the Flutter project. CI must be green afterwards.
4. Refine the first story of the “Foundation” epic to `ready`.
5. Update `STATUS.md` with the real issue numbers.

## Keeping the status (`STATUS.md`)

`STATUS.md` is the short summary of the project state. The user and Claude read
it at the start of every conversation (see below). It must always match the issues.

- Claude updates `STATUS.md` whenever any of it changes: a story changes status
  (`backlog`/`ready`/`in-progress`) or is closed, a new story, epic or
  initiative, order changes, a decision is made.
- Content: In progress · Up next · Backlog by initiative → epic (open epics
  with “x of y stories closed”, dormant initiatives under “Dormant”) · Recently
  done (max. 5, newest first) · Open decisions · “Last updated” date.
- When closing a story, the update belongs in the story's last PR. Pure status
  changes without a PR: direct commit to `main` (`docs: update status`).
- Keep it short: number + title, no task details.
- **The repo is the only source.** `CLAUDE.md` and `STATUS.md` live only here;
  the Claude project “Focus” keeps no copies. At the start of a conversation
  read both from `main` – from the checkout (after `git pull`) when the repo is
  attached, otherwise from
  `https://raw.githubusercontent.com/maestroDev3/Focus/main/CLAUDE.md` and
  `…/main/STATUS.md`. Never create or update copies in the project knowledge.

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
  `QUERY_ALL_PACKAGES`. Exact alarm (`USE_EXACT_ALARM`, Android 12:
  `SCHEDULE_EXACT_ALARM`) only for the on-time session-end notification. No
  foreground service as long as the timestamp-based approach is enough.
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
  in epic #123 (now “Session ritual”).
- 2026-10-01 – Planning structure Initiative → Epic → Story → Task: finite
  epics, closed issues are never reopened, no orphans, issue templates per
  level; three initiatives (Focus experience, Distraction blocking,
  Release & platform).
- 2026-10-02 – Initiatives confirmed. Epic #123 “Final features” split into
  #123 Session ritual, #141 Mindful access to paused apps, #142 Home screen
  widget.
- 2026-10-02 – Named block lists (epic #143): the current list becomes the
  default list; each focus time can use one named list (without a choice the
  default list applies); a label can only **add** a list to the default list,
  never block less; a session during a focus time blocks the union; the
  blocked screen names the active list.
- 2026-10-02 – The repo is the only source for `CLAUDE.md` and `STATUS.md`;
  the Claude project keeps no copies and reads them from GitHub.
- 2026-10-02 – Home screen widget (#120) comes right after the live countdown:
  one tap starts a session with the defaults, without opening the app.
- 2026-10-02 – The session-end notification comes on time: Focus may use the
  exact alarm permission for timer apps (falls back to an inexact alarm if
  it isn't granted).
- 2026-10-02 – Order: #159 filter → #105 live countdown → #120 widget.
  Live countdown: no buttons (tap opens the session), focus sessions only
  (break countdown later as its own story). Widget: one tap starts the
  session in the background (app stays closed) with the defaults and the
  label of the last session (none if there is none).
