//
//  AIscendUITests.swift
//  AIscendUITests
//
//  Created by user294334 on 4/7/26.
//

import XCTest

final class AIscendUITests: XCTestCase {
    private func launchApp(
        additionalArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitest-complete-onboarding",
            "--uitest-force-signed-in",
            "--uitest-start-tab=scan",
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
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
