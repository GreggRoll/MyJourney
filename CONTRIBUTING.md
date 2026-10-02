# Contributing to My Journey

Thanks for helping improve My Journey. This project is open source because progress photos are personal, and users should be able to understand and trust what the app does with their images.

## Free lifetime subscription for a successful PR

When your pull request is accepted and merged by a maintainer, you receive a **free lifetime subscription to My Journey** as a thank-you for your contribution.

A merge request (MR) is called a pull request (PR) on GitHub. A successful PR means the maintainer has reviewed, accepted, and merged it into this repository. Opening an issue or submitting a PR alone does not qualify; the PR must be merged.

After your PR is merged, leave a comment on it asking the maintainer to arrange your lifetime subscription. Keep private account and payment details out of public issues and PRs; coordinate any necessary private details directly with the maintainer.

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
