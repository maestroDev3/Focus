# Accessibility API declaration

Play Console → App content → Sensitive app permissions / Accessibility API.

**Is your app an accessibility tool?** No.

**Core functionality that uses the API (paste):**

Focus is a focus timer that pauses apps the user chose (e.g. social media)
while a focus session or a scheduled focus time runs. The accessibility
service only listens for window-state changes to learn the package name of
the app in the foreground. When it is a paused app during a session or focus
time, Focus brings the user back to its own “resting” screen. Outside sessions
it can optionally show a short breathing pause first. The service never reads
screen content or input, and no data is stored or leaves the device.

**Prominent disclosure:** before the settings open, Focus shows a full-screen
explanation of what is accessed and why, with “Agree and open settings” and
“Not now” (Home → “Allow app blocking”).

**Video for the review (record on the phone, ≤ 1 min):**
1. Home → “Allow app blocking” → show the disclosure → “Agree and open settings”.
2. Switch on “Focus app pause” in the Android settings.
3. Start a session, open a paused app → Focus' resting screen appears.
Upload it as an unlisted YouTube video and paste the link.

**Exact alarm (`USE_EXACT_ALARM`):** Focus is a timer app; the exact alarm
delivers the end-of-session notification on time (Android 12 falls back to
`SCHEDULE_EXACT_ALARM`, otherwise an inexact alarm).
