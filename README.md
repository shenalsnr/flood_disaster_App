# WeSafe – Flood Disaster Management App

SLIIT **IT3060 – Human Computer Interaction**, Group **WD_12**.
A Flutter + Firebase mobile app that connects flood-affected citizens, volunteers, relief camps and emergency dispatchers in one dark-theme, low-stress interface.

## Problem

During floods, citizens do not know the nearest open shelter, hazard reports reach dispatchers unsorted, and relief camps cannot show live capacity or supplies. WeSafe closes that loop: citizens get safe routes and alerts, volunteers report hazards in one tap, camp leaders track people and supplies, and dispatchers triage by severity.

## Roles

| Role | Lands on | Main purpose |
|------|----------|--------------|
| Citizen | Citizen Dashboard | Safe route to nearest open shelter, alerts, evacuation checklist, safe-arrival check-in |
| Volunteer | Quick Hazard Report | 1-tap hazard report with GPS and photo |
| Camp Leader | Camp Dashboard | Headcount, open/closed state, rations, equipment, chat |
| DMC Officer | Supply Admin Dashboard | Supply requests, dispatch, truck tracking |
| Responder / Dispatcher | Alert Dashboard | Severity triage, zone alerts, assign unit, live tracking, resolve |
| Admin | Admin Panel | Create staff, assign camps, place safe zones on the map |

Login is custom (Firestore `users/{email}`), the session is kept with `shared_preferences`, and `StartupGate` shows the login page first when nobody is signed in.

## Team

| Member | Name | IT Number | Component |
|--------|------|-----------|-----------|
| Member 1 | K.B.G.L. Ravihara | IT23820678 | Component 1 – Evacuation and Safe Routing |
| Member 2 | Viduranga R.A.D | IT23808898 | Component 2 – Hazard Reporting |
| Member 3 | R P S N Rajapaksha | IT23818866 | Component 3 – Shelter Relief Tracker |
| Member 4 | Nimantha L.N.A.I | IT23821040 | Component 4 – Responder Control Center |

## Components

| # | Component | Member | Folder | Key requirements |
|---|-----------|--------|--------|------------------|
| 1 | Evacuation and Safe Routing | Member 1 | `lib/features/component1_evacuation/` | Safe route, nearest open shelter, alerts, check-in |
| 2 | Hazard Reporting | Member 2 | `lib/features/component2_reporting/` | 1-tap report with GPS and photo |
| 3 | Shelter Relief Tracker | Member 3 | `lib/features/component3_relief_tracking/` | Camp capacity, rations, equipment, trucks |
| 4 | Responder Control Center | Member 4 | `lib/features/component4_control_center/` | FR10 severity triage, FR11 zone broadcast, FR12 incident lifecycle, NFR5 live map |

See `lib/features/component4_control_center/README.md` for the Component 4 detail.

## How the components connect

- **Admin (C4) → Citizen (C1):** the admin places safe zones on a map (Admin Panel → Safe zones). They are saved to Firestore `camps`.
- **Camp Leader (C3) → Citizen (C1):** the leader's headcount and close/open switch write to `campStatus`. The citizen's Safe Route map listens live and **reroutes automatically** when the nearest shelter is closed or full.
- **Volunteer (C2) → Dispatcher (C4):** hazard reports feed the severity-sorted queue (currently seeded demo data in C4, see Limitations).
- **DMC (C3) ↔ Camps:** supply requests go through `dmcDispatchRequests`.

## Firestore collections

| Collection | Purpose |
|------------|---------|
| `users/{email}` | name, password, role, floodZone, isActive |
| `camps/{slug}` | name, lat, lng, capacity |
| `campStatus/{slug}` | evacueeCount, maxCapacity, isShelterClosed, supplyItems |
| `dmcDispatchRequests`, `leaderChat`, `warnings` | supply requests, camp chat, alerts |

Camp id = slug of the camp name.

## Tech stack

Flutter (Dart SDK ^3.13), `firebase_core`, `cloud_firestore`, `firebase_auth`, `flutter_map` + `latlong2` (OpenStreetMap), `geolocator`, `image_picker`, `shared_preferences`, `url_launcher`, `intl`. Place search uses OpenStreetMap Nominatim.

## Design

- Strict dark theme (background `#0B101D`, card `#131A2A`, accent `#FF5252`, green `#30D158`, orange `#FF9F0A`), large touch targets for stress use.
- Figma high-fidelity: https://www.figma.com/design/SzySYxx7GVdk8fABxgBQ1n/Main-App-Interface?node-id=0-1
- Figma low-fidelity: same file, `node-id=51-2`
- Evaluation: moderated usability testing, 5 participants, think-aloud, issues rated High / Medium / Low.

## Getting started

1. Install Flutter and an Android device or emulator (USB debugging on).
2. Clone and fetch packages:
   ```
   git clone <repo-url>
   cd flood_disaster
   flutter pub get
   ```
3. Firebase is configured in `lib/firebase_options.dart`. Use your own project if needed and make sure Firestore rules allow the collections above.
4. Run:
   ```
   flutter run
   ```
5. Sign in with an account created from Admin Panel → ADD STAFF (create the first admin directly in the `users` collection).

## Project structure

```
lib/
├── main.dart                     # starts at StartupGate (login first)
├── firebase_options.dart
├── core/                         # shared theme
└── features/
    ├── component1_evacuation/
    ├── component2_reporting/
    ├── component3_relief_tracking/
    └── component4_control_center/
```

## Known limitations

- Component 4 incidents and response teams are in-memory demo data; list order is not yet auto-sorted by severity (filter chips and colours work).
- Zone broadcast is local only, not yet written to `warnings`.
- The safe-route line is straight, not road routing.
- Passwords are stored in plain text in `users` (prototype only; hash for production).
- Shelters without a location do not appear on the citizen map.
- Map tiles and place search need internet.

