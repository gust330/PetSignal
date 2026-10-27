---
version: 1
slug: "petsignal-features-map-mapscreen-swift"
primary_target: "PetSignal/Features/Map/MapScreen.swift"
related_targets: ["PetSignal/Features/Reports/ReportsScreen.swift","PetSignal/Features/Reports/NewReportView.swift","PetSignal/Features/Reports/ReportDetailView.swift"]
---

## Scope

Native iOS app redesign centered on the map, in Operate mode. The map remains the initial screen and the fastest route to understanding what needs attention.

## Direction contract

THESIS: PetSignal is a calm civic signal map, not a social feed or a stack of generic cards. It borrows the legibility and disciplined hierarchy of a public wayfinding reference board: every active report reads as a traceable signal with an obvious safe next action.

OWN-WORLD: Deep evergreen ink, warm map paper, amber for missing reports, teal for sightings, thin route-like rules, squared information bands, and restrained rounded corners. Native SF typography and SF Symbols carry the interface; status is always named as well as colored.

STORY: A stressed user opens directly onto an approximate-area map, scans truthful report signals, selects one, understands what happened and when, then acts safely. Reports, creation, candidate matches, resolution, loading, empty, and error states all use the same signal language.

FIRST VIEWPORT: The map owns the screen. A compact opaque top information band names PetSignal and the visible active-report count, followed by a native filter control. Map annotations remain primary; selecting one raises a concise bottom report strip with image, type, time, and a full-width detail action. The signature interaction is the selected signal connecting map context to its action strip without decorative motion.

FORM: Map-first civic wayfinding reference board, raised by the density discipline of Japanese high-density web and the structural honesty of timetable racks. It refuses glass-heavy floating chrome and the generic card dashboard. SEED REFERENCE seed:6ef3aa2779f3c8f6.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

## Constraints

Preserve approximate-location privacy, safety guidance, explainable candidate matches, native iOS navigation, Dynamic Type, VoiceOver, Dark Mode, Increased Contrast, and Reduce Motion. Do not claim live, verified, or proximity-filtered data without implementing it.
