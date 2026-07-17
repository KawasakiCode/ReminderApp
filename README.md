# Reminder — offline calendar todo app (Android)

A fully **offline**, Samsung-Calendar-style todo/reminder app built with
Flutter. No backend, no account, no internet permission — everything lives in
a local SQLite database on the device.

**Features**

- Swipeable month calendar (One-UI look): today highlighted, indicator dot on
  days with todos, per-day todo list with add / edit / complete / delete.
- **Exact-time wake-up reminders** — full-screen, alarm-style notifications
  that light up the lock screen, survive reboots, and honor Android 12/13/14+
  permission rules, with a "Mark as done" action.
- **Persistent checkable notification** — an optional ongoing notification
  listing today's unfinished todos; checking a row marks it done without
  opening the app.
- **Home-screen widget** — resizable "today" list; tapping a row toggles its
  done state. Both surfaces roll over to the new day at midnight.

---

## Setup

Prereqs: Flutter ≥ 3.41 (stable), Android SDK 36, JDK 17. Android only —
there is no iOS code.

```bash
# One-time machine setup: package:sqlite3 v3 ships libsqlite3.so through
# Dart build hooks ("native assets"). Without this flag the APK builds
# fine but crashes at runtime with "libsqlite3.so not found".
flutter config --enable-native-assets

flutter pub get

# Generate the Drift database code (required after any schema change;
# the generated file is committed, so a fresh checkout builds without it):
dart run build_runner build --delete-conflicting-outputs

# Run on a connected device:
flutter run

# Release build:
flutter build apk --release
```

Unit tests: `flutter test`.

> Test reminders on a **physical device**. Emulators often skip Doze/OEM
> battery behavior, and full-screen intents behave differently.

## Architecture (short version)

```
presentation (Flutter + Riverpod)  ──watch──▶  data (Drift/SQLite = source of truth)
        │                                            │ every mutation
        ▼                                            ▼
services (notifications, permissions)   SnapshotService → JSON "today" snapshot
                                                     │  (home_widget SharedPreferences)
                     native surfaces read ONLY the snapshot, never SQLite:
                     ├── TodoWidgetProvider + RemoteViewsFactory (widget)
                     └── TodoForegroundService (persistent notification)
                                    │ user checks a row
                                    ▼
      TodoActionReceiver ─▶ home_widget background Dart isolate ─▶ Drift mutation
                                    └▶ snapshot rewritten ─▶ both surfaces refresh
```

- The Drift database is opened with `shareAcrossIsolates: true`; the UI
  isolate, widget callbacks, WorkManager's midnight task and the
  notification-action handler all share one connection.
- Midnight rollover: a self-re-arming WorkManager one-off task rewrites the
  snapshot at 00:00; the snapshot carries its `dayKey`, so if Doze delays the
  task the native renderers show an empty "new day" state rather than
  yesterday's list. The foreground service additionally re-renders itself at
  midnight.
- One deliberate platform deviation: the notification's checkable list is
  built with dynamic `RemoteViews.addView` rows (max 6 + "+N more"), **not** a
  `RemoteViewsService` — notification hosts can't bind RemoteViews adapters
  (app-widget hosts only), and expanded notifications are height-capped, so a
  "scrollable" notification list does not exist on Android. The
  `RemoteViewsService`/`RemoteViewsFactory` pattern is used where it works:
  the widget's list.

## Permissions (and how to justify them in Play review)

| Permission | Why |
|---|---|
| `POST_NOTIFICATIONS` (13+) | Show reminders and the optional persistent today-list notification. Requested in-app on first run / when enabling either feature. |
| `USE_EXACT_ALARM` (13+) | Reminders must fire at the user-chosen minute. Play policy allows it only when exact scheduling is the app's **core function** (calendar/alarm apps) — this app is exactly that; state it in the Play declaration. |
| `SCHEDULE_EXACT_ALARM` (12/12L only, `maxSdkVersion="32"`) | Same purpose on Android 12, where the user can grant/revoke it in "Alarms & reminders". The app checks `canScheduleExactNotifications()` and **falls back to inexact scheduling with an in-app notice** when revoked. |
| `USE_FULL_SCREEN_INTENT` | Reminders behave like alarm clocks: wake screen + show over lock screen. On 14+ users can revoke it (Settings → Full screen notifications); the app offers the deep link and degrades to a heads-up notification. |
| `RECEIVE_BOOT_COMPLETED` | Re-register alarms and restart the (user-enabled) persistent notification after reboot. |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE` | The persistent checkable notification is a user-toggled foreground service; `specialUse` subtype declared in the manifest `<property>` for review. |
| `WAKE_LOCK`, `VIBRATE` | Used by flutter_local_notifications / WorkManager to deliver reminders and the midnight refresh. |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Optional, user-initiated from Settings: exempts the app from Doze so exact alarms stay reliable on aggressive OEM builds. |

No `INTERNET` permission — verifiable in the merged manifest.

## Known caveats

- **Samsung ~500 alarm cap.** Samsung silently drops alarms once an app has
  ~500 pending. The app only schedules **future** reminders and refuses new
  alarms past 450 (`NotificationIds.maxScheduledAlarms`), telling the user.
- **Battery optimization.** Samsung/Xiaomi/etc. may delay alarms for
  "optimized" apps, especially after days of non-use. Settings → "Battery
  optimization → Allow" fires the system exemption dialog. Worst case without
  it: reminders arrive minutes late.
- **Exact-alarm UX on Android 12.** If the user revokes "Alarms &
  reminders", reminders silently become inexact; the app shows a notice when
  saving such a reminder and a warning row in Settings.
- **Android 14+ can swipe away FGS notifications.** The service keeps
  running and the notification reappears on the next data change / app start;
  this is OS behavior and cannot be prevented.
- **Midnight + Doze.** The WorkManager midnight task can be delayed a few
  minutes in deep Doze; until it runs, widget & notification show an empty
  "new day" state (never yesterday's data), then refresh.
- The `recurrenceRule` column exists in the schema but recurrence is
  intentionally **not implemented** in v1.
