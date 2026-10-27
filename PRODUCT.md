# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

Pet owners, nearby neighbors, and volunteers or rescuers have equal priority. They use PetSignal during a time-sensitive, stressful event to publish a useful local signal, recognize a relevant report, or coordinate a safe follow-up quickly.

## Product Purpose

PetSignal helps a community report missing or potentially abandoned domestic animals, share sightings, connect related reports, and close the loop when an animal is reunited or safe. Success means people can publish or act on trustworthy local information within minutes without exposing an exact private location.

## Positioning

PetSignal combines privacy-rounded map areas, safety guidance, connected follow-up reports, and explainable candidate matching. Matches are presented as suggestions with visible reasons rather than identity confirmations.

## Operating Context

The app is used on an iPhone, often outdoors or under stress. Core workflows are scanning active reports on a map or feed, publishing a missing-pet or sighting report with a photo and approximate area, opening a report to understand what action is safe, submitting a connected follow-up, saving a report, sharing it, and recording a resolved outcome.

## Capabilities and Constraints

- Native SwiftUI app targeting iOS 17 or newer.
- Current data is local sample data plus in-memory report creation; authentication, messaging, moderation, push notifications, and backend persistence are future milestones.
- Public coordinates are placed on an approximately 300-metre privacy grid.
- Photos are resized and stripped of location metadata before publication.
- Candidate matching uses species, distance, time, and shared text traits and must remain explainable.
- Privacy-first approximate locations, safety guidance, and explainable matches are durable commitments.
- Existing core workflows and data models may be improved when the change supports the product purpose.

## Brand Commitments

The product name is PetSignal. The voice is calm, direct, useful, and community-minded. The app must not feel generic or template-like, and it must not trivialize a stressful situation.

## Evidence on Hand

- Product goals and current milestone notes: `README.md`.
- Existing SwiftUI implementation under `PetSignal/`.
- App icon source: `Design/AppIcon.svg`; shipping icon: `PetSignal/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
- Local sample reports in `PetSignal/Services/ReportStore.swift`.
- No real customer claims, testimonials, usage metrics, or production backend evidence are available and none should be fabricated.

## Product Principles

- Make the next safe action obvious.
- Preserve location and photo privacy by default.
- Explain why reports may be connected; never imply certainty without evidence.
- Serve owners, neighbors, and rescuers without privileging one workflow at the expense of the others.
- Use calm urgency: fast and legible without gamification or alarmism.

## Accessibility & Inclusion

Use native iOS semantics and controls, support VoiceOver and Dynamic Type, maintain 44-point touch targets, adapt to Dark Mode and increased contrast, and honor Reduce Motion. Critical status and action meaning must not depend on color alone.