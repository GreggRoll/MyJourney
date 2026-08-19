# App Store Screenshots

The upload-ready marketing images are in:

- `final/iphone` — 1290 × 2796 PNG (iPhone 15 Pro Max)
- `final/ipad` — 2064 × 2752 PNG (13-inch iPad Pro)

Recommended upload order:

1. `01_see_every_change.png`
2. `02_make_progress_a_habit.png`
3. `03_your_journey_stays_yours.png`

The untouched simulator captures are in `raw`. To regenerate the marketing compositions after replacing any raw capture, run:

```sh
swift scripts/make_app_store_screenshots.swift
```

The sample progress-photo assets are marked as Xcode development assets. They are used by Debug UI-test launches and excluded from Release archives.
