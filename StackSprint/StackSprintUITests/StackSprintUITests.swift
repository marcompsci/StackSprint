import XCTest

final class StackSprintUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Launch

    @MainActor
    func testAppLaunchesAndShowsTabBar() throws {
        let app = XCUIApplication()
        app.launch()
        // Root tab bar should be visible
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Learn Tab

    @MainActor
    func testLearnTabIsReachable() throws {
        let app = XCUIApplication()
        app.launch()
        // Tap the Learn tab (first tab)
        let learnTab = app.tabBars.buttons.element(boundBy: 0)
        XCTAssertTrue(learnTab.waitForExistence(timeout: 5))
        learnTab.tap()
    }

    @MainActor
    func testLearnTabShowsCategories() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons.element(boundBy: 0).tap()
        // Category tabs should exist (e.g. "Web" or "Python")
        let webButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Web'")).firstMatch
        let pythonButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Python'")).firstMatch
        let hasCategory = webButton.waitForExistence(timeout: 5) || pythonButton.waitForExistence(timeout: 5)
        XCTAssertTrue(hasCategory)
    }

    // MARK: - Stats Tab

    @MainActor
    func testStatsTabIsReachable() throws {
        let app = XCUIApplication()
        app.launch()
        // Stats is typically the 4th tab
        let statsTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS 'Stats'")).firstMatch
        if statsTab.waitForExistence(timeout: 5) {
            statsTab.tap()
        }
    }

    // MARK: - Account Tab

    @MainActor
    func testAccountTabShowsXPSection() throws {
        let app = XCUIApplication()
        app.launch()
        let accountTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS 'Account'")).firstMatch
        guard accountTab.waitForExistence(timeout: 5) else { return }
        accountTab.tap()
        let xpText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'XP'")).firstMatch
        XCTAssertTrue(xpText.waitForExistence(timeout: 5))
    }
}
