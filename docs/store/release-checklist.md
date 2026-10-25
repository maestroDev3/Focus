# Play Store release checklist

Prepared in the repo (story #351); the steps below are done in the Play
Console by the developer.

1. **Developer account** – create it (one-time fee) and verify your identity.
2. **Create app** – name “Focus – Calm Focus Timer”, default language English,
   app, free.
3. **App bundle** – download `focus_timer.aab` from the latest release
   (https://github.com/maestroDev3/Focus/releases/tag/latest).
   Enable *Play App Signing*; the bundle is signed with the Focus release key
   as **upload key** – keep `focus-release.jks` and its password safe.
4. **Testing first** – upload to *Internal testing*, add yourself as tester,
   install from Play and run through the app. New personal accounts must run a
   *closed test* with at least 12 testers for 14 days before production.
5. **Store listing** – texts from `listing-en.md`, `listing-de.md`,
   `listing-ru.md`. Graphics:
   - App icon 512 × 512 (Ring icon)
   - Feature graphic 1024 × 500
   - At least 2 phone screenshots: home with ring, session, statistics,
     settings → background, blocked screen
6. **App content**
   - Privacy policy URL: see `data-safety.md`
   - Data safety: answers in `data-safety.md`
   - Accessibility API + exact alarm: `accessibility-declaration.md` (with video)
   - Ads: no · Target audience: 13+ · Content rating questionnaire: utility, no
     violence or user interaction → rating “Everyone”
   - Government app / financial features / health: no
7. **Release** – after the closed test, promote the build to production with
   release notes, e.g. “First release of Focus.”
