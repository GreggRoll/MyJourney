# My Journey

My Journey is an iPhone and iPad SwiftUI app for privacy-first progress photos. All image assets and metadata are intended to stay local to the device. The planned App Store listing name is `My Journey - Progress through pics`. Phase 1 focuses on app structure, onboarding, journey management, settings, privacy/about, and persistence scaffolding.

## Proposed Structure

```
MyJourney/
  App/
    MyJourneyApp.swift
    AppContainer.swift
  Models/
    Journey.swift
    JourneyEntryMetadata.swift
    AppSettings.swift
  Persistence/
    FileStore.swift
    JourneyRepository.swift
    SettingsRepository.swift
  Services/
    MonetizationService.swift
  ViewModels/
    RootViewModel.swift
    JourneyListViewModel.swift
    JourneyEditorViewModel.swift
    OnboardingViewModel.swift
    SettingsViewModel.swift
  Views/
    RootView.swift
    OnboardingView.swift
    JourneyListView.swift
    JourneyEditorView.swift
    SettingsView.swift
    PrivacyAboutView.swift
```

## Architecture Notes

- `Models` define app-facing domain objects and keep camera/export phases decoupled from UI.
- `Persistence` uses small JSON repositories in Application Support so journeys and entry metadata are local-only and easy to migrate later.
- `Services` contains abstractions for future capabilities, including monetization.
- `ViewModels` keep screens testable and isolate mutation logic from SwiftUI views.
- `Views` stay declarative and compose over view models plus store-backed state.

## Phase 1 Features

- Onboarding flow persisted locally
- Home/journeys screen with quick resume support
- Create, edit, and delete journeys
- Local persistence for journeys and entry metadata
- Settings, privacy, and about
- Monetization abstraction scaffolding only

## Phase 2 Additions

- Live camera capture for each journey using AVFoundation
- Overlay of the latest local image from the active journey
- Opacity controls with journey defaults
- Grid and 3-second timer options
- Camera permission handling
- Local image and thumbnail storage coordinated with journey metadata

## Phase 3 Additions

- Journey timeline/detail screen with first/latest summary
- Compare screen with before/after slider and manual entry selection
- GIF export with configurable playback duration
- Optional export overlays for capture date and entry number
- MP4 export
- iOS share sheet for exported assets

## Export Pipeline

- Timeline exports use the journey's local image files already saved in Application Support.
- Frames are loaded locally, normalized, optionally annotated with date and/or entry number, and then rendered into either GIF or MP4 output.
- Exported files are written to a temporary local export directory and passed directly into the iOS share sheet.
- No cloud upload, account sync, or remote processing is involved in the export path.

## Current Limitations

- MP4 exports are silent video only.
- Exports currently use the full journey timeline rather than a custom subset picker.
- Real camera behavior still needs device testing; simulator builds verify compile/integration only.
- Export rendering happens in-app and is not yet background-resumable for very large journeys.

## Notes

- The workspace started empty, so this phase includes a fresh SwiftUI iOS project scaffold.
- Full iPhone target compilation needs Xcode.app. This machine currently only has Command Line Tools active, so project verification beyond source-level review should be done in Xcode.
