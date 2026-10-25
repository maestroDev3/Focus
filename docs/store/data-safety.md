# Data safety form – answers

Play Console → App content → Data safety.

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | Not applicable – no data is transmitted (no `INTERNET` permission) |
| Do you provide a way for users to request that their data is deleted? | Data exists only on the device: uninstalling or “Clear data” deletes it |

Why “no”: Google counts data as *collected* only when it leaves the device.
Focus keeps sessions, labels, settings, block lists and focus times in its
private storage; the accessibility service and notification access are used
on the device only (see `privacy-policy.md`). Backups are written to a file
the user picks.

Privacy policy URL: https://github.com/maestroDev3/Focus/blob/main/docs/store/privacy-policy.md
