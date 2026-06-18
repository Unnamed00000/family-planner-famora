# Family Planner

Flutter + Firebase application for a family task planner with authentication, family members, shared task board, statistics, achievements and announcements.

## What is included

- Email/password login and family-login alias lookup.
- Firestore models for members, tasks, announcements and history.
- Firebase Storage photo upload for member profiles.
- Admin tools for members, tasks and announcements.
- Realtime home dashboard, family board, task list, family newspaper, calendar, statistics and profile.
- Light/dark Material 3 theme.
- Russian, Danish and English UI strings.
- PDF export for statistics.
- Firebase rules drafts for Firestore and Storage.

## Setup

This workspace did not have Flutter installed, so platform folders could not be generated here. After installing Flutter, run:

```powershell
flutter create --platforms=android,ios,web .
flutterfire configure
flutter pub get
flutter run
```

`flutterfire configure` should replace `lib/firebase_options.dart` with real Firebase project values.
For Web push notifications, also replace the placeholder Firebase values in `web/firebase-messaging-sw.js`.

Enable these Firebase products on the free Spark plan:

- Authentication: Email/password provider.
- Firestore Database.
- Storage.
- Cloud Messaging for push-token storage and notification delivery.

## First administrator

Bootstrap the first administrator manually once:

1. Create an email/password user in Firebase Authentication.
2. Copy that user's UID.
3. Create `members/{UID}` in Firestore:

```json
{
  "name": "Admin",
  "age": 35,
  "role": "admin",
  "authUid": "THE_AUTH_UID",
  "completedTasks": 0,
  "missedTasks": 0,
  "points": 0
}
```

After that, the administrator can manage members, tasks, announcements and photos from the app.

Deploy rules when ready:

```powershell
firebase deploy --only firestore:rules,storage
```

## Data model

- `members/{memberId}`: family profiles and scores.
- `tasks/{taskId}`: assigned tasks, due dates, statuses and points.
- `announcements/{announcementId}`: family news and reminders.
- `familyLogins/{login}`: local login aliases. Each document stores `email` and `memberId`.
- `history/{historyId}`: audit trail for task/member/announcement changes.

The local family login flow maps a short login to a Firebase Auth email account, then signs in with the supplied password.
