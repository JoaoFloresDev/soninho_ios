//
//  ScreenshotTests.swift
//  soninhoUITests
//
//  Created by João Flores on 28/01/26.
//

import XCTest

final class ScreenshotTests: XCTestCase {
    // MARK: - Properties
    var app: XCUIApplication!
    let screenshotPath = "/Users/joaoflores/Documents/GambitStudio/soninho_ios/soninho/Screenshots"

    // MARK: - Setup
    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Screenshot Test
    @MainActor
    func testCaptureAllScreenshots() throws {
        // Wait for app to load
        sleep(2)

        // Skip onboarding if present
        skipOnboardingIfNeeded()

        // Wait after onboarding
        sleep(2)

        // Print all buttons to debug
        print("=== All buttons in app ===")
        for i in 0..<min(app.buttons.count, 20) {
            let btn = app.buttons.element(boundBy: i)
            print("Button \(i): '\(btn.label)' - hittable: \(btn.isHittable), frame: \(btn.frame)")
        }

        // Get screen size
        let window = app.windows.firstMatch
        let screenWidth = window.frame.width
        let screenHeight = window.frame.height
        print("Screen size: \(screenWidth) x \(screenHeight)")

        // Calculate tab positions (5 tabs evenly distributed)
        // Tab bar is at the bottom, approximately y = screenHeight - 60
        let tabY = screenHeight - 50
        let tabWidth = screenWidth / 5

        // Tab positions (center of each tab)
        let homeX = tabWidth * 0.5
        let sleepX = tabWidth * 1.5
        let alarmX = tabWidth * 2.5
        let statsX = tabWidth * 3.5
        let settingsX = tabWidth * 4.5

        // 1. Home Screen (should be default)
        captureScreenshot(name: "01_Home")

        // 2. Sleep Tracker - tap at position
        print("Tapping Sleep tab at (\(sleepX), \(tabY))...")
        let sleepCoord = window.coordinate(withNormalizedOffset: CGVector(dx: sleepX/screenWidth, dy: tabY/screenHeight))
        sleepCoord.tap()
        sleep(2)
        captureScreenshot(name: "02_SleepTracker")

        // 3. Smart Alarm
        print("Tapping Alarm tab at (\(alarmX), \(tabY))...")
        let alarmCoord = window.coordinate(withNormalizedOffset: CGVector(dx: alarmX/screenWidth, dy: tabY/screenHeight))
        alarmCoord.tap()
        sleep(2)
        captureScreenshot(name: "03_SmartAlarm")

        // 4. Statistics
        print("Tapping Stats tab at (\(statsX), \(tabY))...")
        let statsCoord = window.coordinate(withNormalizedOffset: CGVector(dx: statsX/screenWidth, dy: tabY/screenHeight))
        statsCoord.tap()
        sleep(2)
        captureScreenshot(name: "04_Statistics")

        // 5. Settings
        print("Tapping Settings tab at (\(settingsX), \(tabY))...")
        let settingsCoord = window.coordinate(withNormalizedOffset: CGVector(dx: settingsX/screenWidth, dy: tabY/screenHeight))
        settingsCoord.tap()
        sleep(2)
        captureScreenshot(name: "05_Settings")

        print("Screenshots completed! Check: \(screenshotPath)")
    }

    // MARK: - Onboarding Screenshot Test
    @MainActor
    func testCaptureOnboarding() throws {
        // Wait for app to load
        sleep(2)

        // Check if we're on onboarding
        let skipButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Skip' OR label CONTAINS[c] 'Pular'")).firstMatch
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Next' OR label CONTAINS[c] 'Próximo' OR label CONTAINS[c] 'Continuar' OR label CONTAINS[c] 'Continue'")).firstMatch
        let getStartedButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Get Started' OR label CONTAINS[c] 'Começar'")).firstMatch

        // If any onboarding element exists, capture screenshots
        if skipButton.exists || nextButton.exists || getStartedButton.exists {
            // Capture first onboarding screen
            captureScreenshot(name: "00a_Onboarding_1")

            // Navigate through onboarding
            for i in 2...4 {
                if nextButton.exists && nextButton.isHittable {
                    nextButton.tap()
                    sleep(1)
                    captureScreenshot(name: "00\(["a","b","c","d"][i-1])_Onboarding_\(i)")
                } else {
                    break
                }
            }

            // Capture final screen with Get Started
            if getStartedButton.exists {
                captureScreenshot(name: "00e_Onboarding_Final")
            }
        }
    }

    // MARK: - Onboarding Helper
    private func skipOnboardingIfNeeded() {
        // Look for onboarding buttons
        let skipButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Skip' OR label CONTAINS[c] 'Pular'")).firstMatch
        let getStartedButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Get Started' OR label CONTAINS[c] 'Começar' OR label CONTAINS[c] 'Start' OR label CONTAINS[c] 'Iniciar'")).firstMatch
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Next' OR label CONTAINS[c] 'Próximo' OR label CONTAINS[c] 'Continuar' OR label CONTAINS[c] 'Continue'")).firstMatch

        // If skip button exists, tap it
        if skipButton.waitForExistence(timeout: 2) && skipButton.isHittable {
            print("Found Skip button, tapping...")
            skipButton.tap()
            sleep(1)
            return
        }

        // Otherwise, try to navigate through onboarding
        for _ in 0..<5 {
            if getStartedButton.exists && getStartedButton.isHittable {
                print("Found Get Started button, tapping...")
                getStartedButton.tap()
                sleep(1)
                return
            }

            if nextButton.exists && nextButton.isHittable {
                print("Found Next button, tapping...")
                nextButton.tap()
                sleep(1)
            } else {
                break
            }
        }

        // Final check for get started
        if getStartedButton.waitForExistence(timeout: 1) && getStartedButton.isHittable {
            getStartedButton.tap()
            sleep(1)
        }
    }

    // MARK: - Tab Helper
    private func findTab(containing keywords: [String]) -> XCUIElement? {
        for keyword in keywords {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", keyword)
            let element = app.buttons.matching(predicate).firstMatch
            if element.exists && element.isHittable {
                print("Found tab with keyword: \(keyword)")
                return element
            }
        }
        return nil
    }

    // MARK: - Screenshot Helpers
    private func captureScreenshot(name: String) {
        let screenshot = app.screenshot()

        // Add as test attachment
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Save to file
        saveScreenshotToFile(screenshot: screenshot, name: name)

        print("Captured: \(name)")
    }

    private func saveScreenshotToFile(screenshot: XCUIScreenshot, name: String) {
        let fileManager = FileManager.default

        // Create directory
        try? fileManager.createDirectory(atPath: screenshotPath, withIntermediateDirectories: true)

        // Save PNG
        let path = "\(screenshotPath)/\(name).png"
        let pngData = screenshot.pngRepresentation
        fileManager.createFile(atPath: path, contents: pngData)
    }
}
