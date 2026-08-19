# Contributing to My Journey

Thanks for helping improve My Journey. This project is open source because progress photos are personal, and users should be able to understand and trust what the app does with their images.

## Contributor Premium Codes

If you fix a confirmed issue or submit a pull request that improves the app and it is accepted or merged, you will receive a code for the Premium in-app purchase.

Premium currently unlocks the Remove Watermark entitlement for exports.

To claim a code, comment on the merged pull request or accepted issue after the work lands, or contact the maintainer through GitHub. Codes are provided after the contribution is accepted and are subject to App Store promotional or offer code availability.

Qualifying contributions include meaningful bug fixes, feature improvements, accessibility work, privacy or security hardening, test coverage, release polish, screenshots, and documentation improvements. Spam, generated noise, unaccepted changes, or trivial changes made only to claim a code do not qualify.

## How to Contribute

1. Pick an open issue, or open an issue first if you want to propose a larger change.
2. Fork the repository and create a focused branch.
3. Keep each pull request scoped to one fix or improvement.
4. Add or update tests when the change affects behavior.
5. Include screenshots or a screen recording for UI changes when possible.
6. Open a pull request with a clear summary and testing notes.

## Good Areas to Help

- Real-device camera testing and permission edge cases.
- Accessibility improvements for VoiceOver, Dynamic Type, labels, and contrast.
- Export reliability and performance, especially for larger journeys.
- UI polish across iPhone and iPad layouts.
- Privacy review and documentation.
- Unit and UI test coverage.
- App Store release checklist and screenshot polish.

## Development Notes

Open `MyJourney.xcodeproj` in Xcode and run the `MyJourney` scheme on an iPhone or iPad simulator. Use a physical iOS device for final camera testing.

Use `MyJourney/Products.storekit` when testing the Premium purchase flow locally.

## Pull Request Checklist

- The app builds locally in Xcode, or the PR explains why it was not tested.
- UI changes include screenshots or a short recording when practical.
- Behavior changes include tests where reasonable.
- User photos remain local unless a privacy-impacting change was explicitly discussed first.
- Free and Premium behavior remains clear and intentional.
