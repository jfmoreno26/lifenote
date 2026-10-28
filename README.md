# LifeNote

Notes, activities, projects and water tracking in one Flutter app, backed by Firebase Auth and Cloud Firestore.

## Features

- **Home**: water-intake card, pinned notes, today's activities
- **Notes**: create, edit, pin, delete, color and tag notes; search, category filter, grid or list view
- **Calendar**: month view with activity dots; add, edit, complete and delete activities (date, optional time, category)
- **Projects**: projects with task checklists, progress bars and percent complete
- **Water tracker**: daily glasses, an adjustable goal and glass size, and a 7-day chart
- **Accounts**: email/password sign-up and sign-in, password reset, change name, email or password, delete account (removes all data)
- **Roles**: `user` and `admin`. Admins get a User management screen where they can list users, change roles and see per-user counts. Firestore rules enforce this.
- **Analytics and alerts**: a reports screen with 7/30/90-day stats, charts and insights. Automated in-app alerts cover water pace, upcoming and overdue activities, and projects that are almost done.
- **Reports and export**: generate a text report (copy or share), or export all data as CSV or JSON
- **Dark mode**: System, Light or Dark, saved per device

## Setup

1. In the Firebase console for project `lifenote-f61c3`:
   - Authentication → Sign-in method → enable **Email/Password**
   - Firestore Database → create a database
2. Deploy the security rules:
   ```sh
   firebase deploy --only firestore:rules
   ```
3. Run the app: `flutter run`

### Making the first admin

New accounts always start as `user`, and users cannot change their own role. To create the first admin, open
Firestore → `users/{uid}` and set `role` to `admin`. After that, admins can promote other users in the app
(Account → User management).

## Data model

```
users/{uid}                 name, email, role, waterGoal, glassMl, createdAt
users/{uid}/notes/{id}      title, body, category, color, pinned, createdAt, updatedAt
users/{uid}/activities/{id} title, date, hasTime, category, done
users/{uid}/projects/{id}   title, category, tasks[{id,title,done}], createdAt
users/{uid}/water/{yyyy-MM-dd}  date, glasses
```

## Notes

- `pubspec.yaml` overrides `path_provider_foundation` to 2.5.1. Newer versions use `objective_c`, and its native-asset
  build hook fails when the Flutter SDK is installed in a path that contains spaces. If you move the SDK to a path
  without spaces (for example `C:\src\flutter`), you can remove the override.
- Alerts are in-app: a toast appears when an alert first triggers, and the alert list is behind the bell icon. They are
  not OS push notifications.
