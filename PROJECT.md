# Focus – texts to copy

## GitHub repository

- **Repository name:** `Focus`
- **Description:** Minimal focus timer: Pomodoro sessions, daily goals and honest statistics.
- **Topics:** `flutter` `dart` `android` `tdd` `focus`

## Claude project

**Project name:** 🎯 Focus

**Project description:**
Android app (Flutter): a clean, distraction-free Pomodoro focus timer with daily goals, labels and statistics.

**Project instructions (custom instructions):**

```
This project belongs to the app “Focus” – Minimal focus timer: Pomodoro sessions, daily goals and honest statistics.
Repository (public): https://github.com/maestroDev3/Focus

The repo is the only source of truth – this project keeps no copies.
- At the start of every conversation, read the current files from `main`:
  - https://raw.githubusercontent.com/maestroDev3/Focus/main/CLAUDE.md (working rules, binding)
  - https://raw.githubusercontent.com/maestroDev3/Focus/main/STATUS.md (current state)
  With the repo attached, read them from the checkout instead (after `git pull`).
- If they can't be read, say so instead of guessing the state.
- Never upload or update copies of CLAUDE.md or STATUS.md in the project knowledge.
- Everything in the repo is English; you may talk to me in German.
- Never make the open decisions listed in STATUS.md yourself – present them to me.
```

**Project knowledge:** none needed – CLAUDE.md and STATUS.md are read from the repo.

## First message to Claude (session with the repo attached)

```
The attached ZIP contains the starter files for Focus. Extract its contents
into the root of github.com/maestroDev3/Focus (create the repo if it does not exist yet,
private, default branch main), commit ("chore: add working rules, skill and CI")
and push to main.
Then run the "First start" from CLAUDE.md: create labels, create epics and stories
from STATUS.md as issues (with sub-issues), run the Scaffold workflow, get CI green,
refine the first story and update STATUS.md with the issue numbers.
```
