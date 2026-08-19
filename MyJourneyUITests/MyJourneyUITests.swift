import XCTest

final class MyJourneyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testProductionLaunchDoesNotSeedSampleJourney() {
        let app = launchApp(sampleData: false, premium: false)
        completeOnboarding(in: app)

        XCTAssertFalse(app.staticTexts["Jennifer's Body"].exists)
        XCTAssertTrue(app.staticTexts["No Journeys Yet"].waitForExistence(timeout: 3))
    }

    func testFreeCompareShowsWatermark() throws {
        XCTAssertNotNil(Bundle(for: Self.self).url(forResource: "JenifersBody", withExtension: nil))
        let app = launchApp(sampleData: true, premium: false)
        openSampleCompare(in: app)

        XCTAssertTrue(app.staticTexts["freeWatermark"].waitForExistence(timeout: 3))
    }

    func testPremiumCompareHidesWatermark() {
        let app = launchApp(sampleData: true, premium: true)
        openSampleCompare(in: app)

        XCTAssertFalse(app.staticTexts["freeWatermark"].exists)
    }

    func testCaptureMarketingScreens() {
        let app = launchApp(sampleData: true, premium: true)
        XCTAssertTrue(app.buttons["onboardingContinueButton"].waitForExistence(timeout: 5))
        captureScreenshot(named: "01_onboarding")

        openSampleJourney(in: app)
        captureScreenshot(named: "02_journey_detail")

        let compareButton = app.buttons["compareButton"]
        XCTAssertTrue(compareButton.waitForExistence(timeout: 5))
        compareButton.tap()
        XCTAssertTrue(app.navigationBars["Compare"].waitForExistence(timeout: 5))
        captureScreenshot(named: "03_compare")
    }

    private func launchApp(sampleData: Bool, premium: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-reset"]
        if sampleData {
            app.launchArguments.append("-ui-testing-sample-data")
        }
        if premium {
            app.launchArguments.append("-ui-testing-premium")
        }
        app.launch()
        return app
    }

    private func completeOnboarding(in app: XCUIApplication) {
        let continueButton = app.buttons["onboardingContinueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertTrue(continueButton.isHittable)
        continueButton.tap()
    }

    private func openSampleCompare(in app: XCUIApplication) {
        openSampleJourney(in: app)

        let compareButton = app.buttons["compareButton"]
        XCTAssertTrue(compareButton.waitForExistence(timeout: 5))
        compareButton.tap()
        XCTAssertTrue(app.navigationBars["Compare"].waitForExistence(timeout: 5))
    }

    private func openSampleJourney(in app: XCUIApplication) {
        completeOnboarding(in: app)

        let journeyName = app.staticTexts["Jennifer's Body"].firstMatch
        XCTAssertTrue(journeyName.waitForExistence(timeout: 5))
        journeyName.tap()
        XCTAssertTrue(app.navigationBars["Journey"].waitForExistence(timeout: 5))
    }

    private func captureScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
