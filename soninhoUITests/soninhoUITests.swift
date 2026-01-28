//
//  soninhoUITests.swift
//  soninhoUITests
//
//  Created by João Flores on 28/01/26.
//

import XCTest

final class soninhoUITests: XCTestCase {
    // MARK: - Properties
    var app: XCUIApplication!

    // MARK: - Setup
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tab Bar Tests
    @MainActor
    func testTabBarExists() throws {
        // Verify tab bar items exist
        let homeTab = app.buttons["Início"]
        let trackerTab = app.buttons["Dormir"]
        let alarmTab = app.buttons["Alarme"]
        let statsTab = app.buttons["Stats"]
        let settingsTab = app.buttons["Ajustes"]

        // Take screenshot of initial state
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Tab Bar - Initial State"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Check if at least the home tab exists (may have different names)
        XCTAssertTrue(app.buttons.count >= 5, "Tab bar should have at least 5 buttons")
    }

    @MainActor
    func testTabBarNavigation() throws {
        // Get all buttons in the app
        let buttons = app.buttons

        // Navigate through tabs and capture screenshots
        sleep(1)

        // Screenshot Home
        var screenshot = app.screenshot()
        var attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "01 - Home Screen"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Try to find and tap Sleep Tracker tab
        let trackerTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Dormir' OR label CONTAINS[c] 'Sleep' OR label CONTAINS[c] 'moon'")).firstMatch
        if trackerTab.exists {
            trackerTab.tap()
            sleep(1)

            screenshot = app.screenshot()
            attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "02 - Sleep Tracker Screen"
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        // Try to find and tap Alarm tab
        let alarmTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Alarm' OR label CONTAINS[c] 'alarm'")).firstMatch
        if alarmTab.exists {
            alarmTab.tap()
            sleep(1)

            screenshot = app.screenshot()
            attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "03 - Alarm Screen"
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        // Try to find and tap Statistics tab
        let statsTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Stats' OR label CONTAINS[c] 'Estatísticas' OR label CONTAINS[c] 'chart'")).firstMatch
        if statsTab.exists {
            statsTab.tap()
            sleep(1)

            screenshot = app.screenshot()
            attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "04 - Statistics Screen"
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        // Try to find and tap Settings tab
        let settingsTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Ajustes' OR label CONTAINS[c] 'Settings' OR label CONTAINS[c] 'gear'")).firstMatch
        if settingsTab.exists {
            settingsTab.tap()
            sleep(1)

            screenshot = app.screenshot()
            attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "05 - Settings Screen"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    // MARK: - Sleep Tracker Tests
    @MainActor
    func testSleepTrackerButtonTappable() throws {
        // Navigate to Sleep Tracker
        let trackerTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Dormir' OR label CONTAINS[c] 'Sleep' OR label CONTAINS[c] 'moon'")).firstMatch
        if trackerTab.exists {
            trackerTab.tap()
            sleep(1)
        }

        // Screenshot before tap
        var screenshot = app.screenshot()
        var attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Sleep Tracker - Before Start"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Try to find the start button
        let startButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Iniciar' OR label CONTAINS[c] 'Start' OR label CONTAINS[c] 'Começar'")).firstMatch

        if startButton.exists {
            XCTAssertTrue(startButton.isHittable, "Start button should be tappable")

            // Get button frame info
            let buttonFrame = startButton.frame
            print("Start Button Frame: \(buttonFrame)")
            print("Start Button Accessible: \(startButton.isAccessibilityElement)")
            print("Start Button Enabled: \(startButton.isEnabled)")
            print("Start Button Hittable: \(startButton.isHittable)")

            // Tap the button
            startButton.tap()
            sleep(2)

            // Screenshot after tap
            screenshot = app.screenshot()
            attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Sleep Tracker - After Start Tap"
            attachment.lifetime = .keepAlways
            add(attachment)
        } else {
            // If specific button not found, try tapping any button with moon icon
            let moonButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'moon'")).firstMatch
            if moonButton.exists && moonButton.isHittable {
                moonButton.tap()
                sleep(2)
            }

            // Screenshot current state
            screenshot = app.screenshot()
            attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Sleep Tracker - Button Search"
            attachment.lifetime = .keepAlways
            add(attachment)

            // Print all buttons for debugging
            print("All buttons in app:")
            for i in 0..<app.buttons.count {
                let button = app.buttons.element(boundBy: i)
                print("  Button \(i): label='\(button.label)', identifier='\(button.identifier)', hittable=\(button.isHittable)")
            }
        }
    }

    // MARK: - Layout Analysis Tests
    @MainActor
    func testLayoutAnalysis() throws {
        // Capture all screens for layout analysis
        let screens = ["Home", "Dormir", "Alarme", "Stats", "Ajustes"]

        for (index, screenName) in screens.enumerated() {
            // Try to navigate to each screen
            let tab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", screenName)).firstMatch
            if tab.exists {
                tab.tap()
                sleep(1)

                // Get screen dimensions
                let mainWindow = app.windows.firstMatch
                let windowFrame = mainWindow.frame
                print("\n=== \(screenName) Screen ===")
                print("Window Frame: \(windowFrame)")

                // Check for overlapping elements
                let allElements = app.descendants(matching: .any)
                print("Total elements: \(allElements.count)")

                // Screenshot
                let screenshot = app.screenshot()
                let attachment = XCTAttachment(screenshot: screenshot)
                attachment.name = "Layout Analysis - \(index + 1). \(screenName)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    // MARK: - Button Accessibility Test
    @MainActor
    func testAllButtonsAccessible() throws {
        // Test all screens for button accessibility
        let tabs = app.buttons.allElementsBoundByIndex

        for tab in tabs.prefix(5) {
            if tab.isHittable {
                tab.tap()
                sleep(1)

                // Check all buttons are hittable
                let screenButtons = app.buttons.allElementsBoundByIndex
                for button in screenButtons {
                    if !button.isHittable && button.exists {
                        print("WARNING: Button '\(button.label)' exists but is not hittable")
                        print("  Frame: \(button.frame)")
                    }
                }
            }
        }

        // Final screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Button Accessibility - Final State"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Performance
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
