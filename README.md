# PetSignal

PetSignal is an iOS community platform for reporting missing or potentially
abandoned domestic animals, sharing sightings, and connecting related reports.

## Initial Product Goals

- Report a missing animal with photos, identifying traits, and a last-seen area.
- Report a sighting with a photo, time, location, and condition details.
- Display active reports and sightings on a privacy-conscious map.
- Suggest potential matches using location, time, traits, and image similarity.
- Let community members follow reports, receive alerts, and coordinate safely.

## Current Prototype

The first native SwiftUI milestone includes:

- A MapKit view with missing-pet and sighting filters.
- A community report feed and report details.
- Photo selection and an explicit map-pin location picker.
- Local sample data and in-memory report creation.
- Explainable candidate matching based on species, distance, time, and text traits.
- Unit tests for matching and geographic distance calculations.

## Stack

- SwiftUI and MapKit
- Supabase with PostgreSQL, PostGIS, Storage, and Realtime (planned)
- Apple Push Notification Service (planned)
- Server-side image embeddings and pgvector for candidate matching (planned)

## Open In Xcode

The project definition uses [XcodeGen](https://github.com/yonaskolb/XcodeGen)
so generated Xcode project files do not need to be committed.

```sh
brew install xcodegen
xcodegen generate
open PetSignal.xcodeproj
```

The app targets iOS 17 or newer and currently has no third-party runtime
dependencies. Select an iPhone simulator, then build and run the `PetSignal`
scheme. Tests are available through `Product > Test`.

The current reports are intentionally stored in memory. Backend persistence,
authentication, messaging, moderation, and push notifications are subsequent
milestones.
