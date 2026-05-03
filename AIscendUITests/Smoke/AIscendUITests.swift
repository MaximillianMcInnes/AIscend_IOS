//
//  AIscendUITests.swift
//  AIscendUITests
//
//  Created by user294334 on 4/7/26.
//

import XCTest

final class AIscendUITests: XCTestCase {
    private func launchApp(
        startTab: String = "scan",
        additionalArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitest-complete-onboarding",
            "--uitest-force-signed-in",
            "--uitest-start-tab=\(startTab)",
            "--uitest-disable-daily-photo-prompts"
        ] + additionalArguments
        app.launch()
        return app
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let app = launchApp()
        XCTAssertTrue(app.otherElements["scan-studio-new-scan-root"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testScanStudioLoadsPreviousScansWhenToggleIsTapped() throws {
        let app = launchApp()
        let sortLabel = app.staticTexts["Sort"]
        XCTAssertTrue(app.otherElements["scan-studio-new-scan-root"].waitForExistence(timeout: 5))

        let previousScansButton = app.buttons["scan-studio-tab-previousScans"]

        XCTAssertTrue(previousScansButton.waitForExistence(timeout: 5))
        XCTAssertTrue(previousScansButton.isHittable)
        XCTAssertFalse(sortLabel.exists)

        previousScansButton.tap()

        expectation(for: NSPredicate(format: "value == %@", "Selected"), evaluatedWith: previousScansButton)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(sortLabel.waitForExistence(timeout: 5))
    }

    @MainActor
    func testMoreLookalikePreviewOpens() throws {
        let app = launchApp(startTab: "more")

        let lookalikeButton = app.buttons["Lookalike"]
        XCTAssertTrue(lookalikeButton.waitForExistence(timeout: 5))
        lookalikeButton.tap()

        XCTAssertTrue(app.staticTexts["Celebrity Lookalike"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Instant match"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testMoreSkinLabPreviewOpens() throws {
        let app = launchApp(startTab: "more")

        let skinLabButton = app.buttons["Skin Lab"]
        XCTAssertTrue(skinLabButton.waitForExistence(timeout: 5))
        skinLabButton.tap()

        XCTAssertTrue(app.staticTexts["Skin Lab"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Texture map"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAccountDeletionFlowCanBeInitiatedAndConfirmed() throws {
        let app = launchApp(startTab: "more")

        let profileButton = app.buttons["Profile"]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 5))
        profileButton.tap()

        let deleteAccountButton = app.buttons["profile-delete-account-button"]
        XCTAssertTrue(deleteAccountButton.waitForExistence(timeout: 5))
        for _ in 0..<4 where !deleteAccountButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(deleteAccountButton.isHittable)
        deleteAccountButton.tap()

        let confirmationButton = app.buttons["Delete account"]
        XCTAssertTrue(confirmationButton.waitForExistence(timeout: 5))
        confirmationButton.tap()

        XCTAssertTrue(app.buttons["Continue with Google"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
