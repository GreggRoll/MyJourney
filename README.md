# My Journey

My Journey is a privacy-first progress photo app for iPhone and iPad. It helps you capture consistent photos over time, line up each new shot with your previous one, compare progress, and export shareable GIFs or MP4s without sending your images to an account, cloud service, or remote processor.

The planned App Store listing name is `My Journey - Progress through pics`.

<p align="center">
  <img src="AppStoreScreenshots/final/iphone/01_see_every_change.png" width="30%" alt="My Journey screenshot: see every change">
  <img src="AppStoreScreenshots/final/iphone/02_make_progress_a_habit.png" width="30%" alt="My Journey screenshot: make progress a habit">
  <img src="AppStoreScreenshots/final/iphone/03_your_journey_stays_yours.png" width="30%" alt="My Journey screenshot: your journey stays yours">
</p>

## Open source — help shape My Journey

My Journey is open source under the [MIT License](LICENSE), and everyone is welcome to help. Bug fixes, new features, accessibility improvements, design, tests, and documentation contributions are all welcome.

**Get a free lifetime subscription when your pull request is accepted and merged.** A successful merge request (MR), called a pull request (PR) on GitHub, is one that a maintainer reviews, accepts, and merges into this repository.

Start by [opening an issue](https://github.com/GreggRoll/MyJourney/issues) to report a bug or discuss an idea, or fork the repository and submit a focused pull request. For larger changes, discuss the approach in an issue first.

After your PR is merged, ask the maintainer in that PR to arrange your free lifetime subscription to My Journey. Do not post private account or payment details publicly.

See [Contributing](CONTRIBUTING.md) for how to get started and how the reward works.

## Features

- Progress-photo journeys for anything you want to document over time.
- Live camera capture with latest-photo overlay for consistent alignment.
- Adjustable overlay opacity, grid, and timer controls.
- Local journey metadata, images, and thumbnails.
- Journey detail timeline with first/latest summaries.
- Before/after comparison view.
- GIF and MP4 export with the iOS share sheet.
- Optional date and entry number overlays for exports.
- Free GIF watermark behavior with StoreKit-backed Premium entitlement.
- Local reminders for keeping a photo habit.
- Settings, privacy, and about screens.

## Privacy

My Journey is designed around local-first storage for personal progress photos.

- No account is required.
- Journey images and metadata are stored locally on device.
- Export rendering happens in app.
- Exported files are written locally and handed directly to the iOS share sheet.
- No cloud upload, account sync, or remote processing is involved in the export path.

## Running Locally

Requirements:

- Xcode with the iOS SDK installed.
- An iPhone or iPad simulator for general development.
- A physical device for final camera behavior testing.

Steps:

1. Clone the repository.
2. Open `MyJourney.xcodeproj` in Xcode.
3. Select the `MyJourney` scheme.
4. Run on an iPhone or iPad simulator, or on a physical device for camera testing.
5. Use `MyJourney/Products.storekit` when testing the Premium purchase flow locally.

## Project Structure

```text
MyJourney/
  App/             SwiftUI app entry point and dependency container
  Models/          Journeys, entries, export options, settings, entitlements
  Persistence/     Local JSON stores for journeys, settings, and metadata
  Services/        Camera, images, export, monetization, reminders
  ViewModels/      Screen state and user actions
  Views/           SwiftUI screens and reusable UI pieces
```

## Areas Where Help Is Welcome

- App Store release hardening and review-readiness checks.
- Real-device camera testing and permission edge cases.
- Accessibility passes for VoiceOver, Dynamic Type, labels, and contrast.
- Export reliability and performance for larger journeys.
- Custom export range selection.
- Background or resumable exports.
- Privacy review, documentation, and release notes.
- Focused unit/UI test coverage.

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to help and how the free lifetime subscription reward works.

## Current Limitations

- MP4 exports are silent video only.
- Exports currently use the full journey timeline rather than a custom subset picker.
- Real camera behavior still needs physical device testing; simulator builds verify compile and integration behavior only.
- Export rendering happens in app and is not yet background-resumable for very large journeys.

## Screenshots

Upload-ready marketing images are stored in `AppStoreScreenshots/final` for both iPhone and iPad. The raw simulator captures and screenshot generation script are also included for release iteration.

## License

My Journey is open source under the [MIT License](LICENSE).
