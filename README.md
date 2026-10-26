# Focus

**A calm, minimal focus timer for Android.** Tap the ring and your session
begins. While you focus, the apps you chose stay closed and their
notifications wait until you're done. No account, no ads, no tracking – all
your data stays on your phone.

[**Download the latest APK**](https://github.com/maestroDev3/Focus/releases/download/latest/focus_timer.apk)
· [User guide](docs/user-guide.md) · [Anleitung (Deutsch)](docs/user-guide.de.md)
· [Privacy policy](docs/store/privacy-policy.md)

## What Focus does

- **Pomodoro rhythm** – focus sessions with short and long breaks; lengths and
  rhythm are yours to set.
- **One ring to start** – the golden ring shows today's focus against your daily
  goal; tap it to begin, hold it to change the goal.
- **Pause distracting apps** – chosen apps stay closed during a session, their
  notifications are held back and delivered afterwards. Strict on purpose: no
  unlocking until the session ends.
- **Focus times** – block apps on fixed days and hours (e.g. weekdays 7–10),
  with your default list or a named block list.
- **Mindful opening** – outside your focus, a short breathing pause before a
  paused app opens.
- **Labels with goals** – tag what you worked on; give a label a total goal
  and/or a weekly goal.
- **Session ritual** – an intention before, a short reflection after, calm
  ambient sounds or your own music app.
- **Honest statistics** – today, week and month, tappable days, labels,
  protected time, paused apps and a calm rhythm instead of pressure.
- **Always at hand** – home screen widget, quick settings tile, countdown on
  the lock screen (Live Update on Android 16).
- **Calm, living design** – Noir & Champagne, a breathing ring and living
  backgrounds to choose from (or none).
- **Languages** – English, Deutsch, Русский (switchable in the app).

## Install

Focus is not on Google Play yet. Download
[`focus_timer.apk`](https://github.com/maestroDev3/Focus/releases/download/latest/focus_timer.apk)
on your Android phone and open it. Updates install over the
existing app – your data stays. See the [user guide](docs/user-guide.md#install)
for the one-time “restricted settings” step Android asks for with apps from
outside the Play Store.

## Permissions and privacy

| Permission | Why |
|---|---|
| Accessibility service (“Focus app pause”) | Notices only *which* app is opened, to bring you back when it's paused. Never reads your screen. |
| Notification access (“Focus notification hold”) | Holds back notifications of paused apps until the session ends. Content is not read. |
| Notifications | Session end and focus time reminders |
| Exact alarms | The end-of-session notification arrives on time |
| Run at startup | Restores scheduled reminders after a restart |

Focus has no internet permission. Details: [privacy policy](docs/store/privacy-policy.md).

## Development

Flutter app, Android first. Built and tested on every pull request by GitHub
Actions; every APK is start-tested on an emulator before it is published.

- Working rules: [CLAUDE.md](CLAUDE.md) · Current status: [STATUS.md](STATUS.md)
- Flutter/Dart conventions: [.claude/skills/flutter-dart/SKILL.md](.claude/skills/flutter-dart/SKILL.md)
- Planning: GitHub issues Initiative → Epic → Story → Task (sub-issues), templates in `.github/ISSUE_TEMPLATE/`
- Releases: “latest” (main: APK + app bundle), “preview” (epic branches for testing)
- Play Store preparation: [`docs/store/`](docs/store/)
