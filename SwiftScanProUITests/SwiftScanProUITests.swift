//
//  SwiftScanProUITests.swift
//  SwiftScanProUITests
//
//  Created by Yashil Luckan on 2023/10/10.
//

import XCTest

final class SwiftScanProUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    
    func testAdvancedUserFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        let addFolder = app.buttons["Add Folder"]
        addFolder.tap()
        
        let newFolderAlert = app.alerts["New Folder"]
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: newFolderAlert, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        let newFolderTextField = newFolderAlert.textFields.element
        newFolderTextField.typeText("AdvancedTest1")
        
        let addFolderButton = newFolderAlert.buttons["Add"]
        addFolderButton.tap()
        
        let folderCV = app.collectionViews["folderCV"]
        var newFolderCell = folderCV.cells["AdvancedTest1"]
        newFolderCell.tap()
        // Set Naming Convention:
        let namingConventionTextField = app.textFields["NamingConventionTextField"]
        namingConventionTextField.tap()
        namingConventionTextField.typeText("LCKYAS002")
        app.keyboards.buttons["Return"].tap()
        // Turn on Two-Page Mode:
        let twoPageModeSwitch = app.switches["TwoPageModeToggle"]
        twoPageModeSwitch.tap()
        let pageCountAlert = app.alerts["Page Count"]
        expectation(for: exists, evaluatedWith: pageCountAlert, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        let pageCountTextField = pageCountAlert.textFields.element
        pageCountTextField.typeText("2")
        
        let savePageCountButton = pageCountAlert.buttons["Save"]
        savePageCountButton.tap()
        
        let newScanButton = app.buttons["New Scan"]
        newScanButton.tap()
        
        let vnDocVC = app.otherElements["vnDocCam"]
        let vnDocExists = vnDocVC.waitForExistence(timeout: 5)
        XCTAssert(vnDocExists, "Failed to open in 5 seceonds")
        
        let newDocAlert = app.alerts["File Name"]
        expectation(for: exists, evaluatedWith: newDocAlert, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        // No need to type file name as naming convention is set.
        let alertSaveButton = app.buttons["Save"]
        alertSaveButton.tap()
        // Open new
        let docCollectionView = app.collectionViews["docCV"]
        let newDocCell = docCollectionView.cells["LCKYAS002_1.pdf"]
        newDocCell.tap()
        
        let pdfView = app.otherElements["pdfView"]
        expectation(for: exists, evaluatedWith: pdfView, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        pdfView.swipeLeft()
        //sleep(3) // To manually check if document has 2 pages (split correctly).
        let thumbnailButton = app.buttons["toggleThumbnailView"]
        thumbnailButton.tap()
        let thumbnailView = app.otherElements["thumbnailView"]
        XCTAssert(thumbnailView.exists, "Thumbnail view is not displayed.")
        thumbnailButton.tap()
        XCTAssertFalse(thumbnailView.exists, "Thumbnail view should not be displayed.")
        let shareButton = app.buttons["Share"]
        shareButton.tap()
        sleep(2)
        // Tap near top of screen to dismiss share menu:
        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        coordinate.tap()
        
        let markupButton = app.buttons["markup"]
        markupButton.tap()
        let textBoxButton = app.buttons["textBoxButton"]
        textBoxButton.tap()
        let coordinate2 = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate2.tap()
        let textBoxAlert = app.alerts["Enter Text"]
        expectation(for: exists, evaluatedWith: textBoxAlert, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        let textBoxTextField = textBoxAlert.textFields.element
        textBoxTextField.typeText("h")
        
        let addTextButton = textBoxAlert.buttons["Add"]
        addTextButton.tap()
        
        let saveText = app.buttons["Save"]
        saveText.tap()
        let savedAlert = app.alerts["Saved"]
        expectation(for: exists, evaluatedWith: savedAlert, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        let OK = savedAlert.buttons["OK"]
        OK.tap()
        
        let pdfDone = app.buttons["Done"]
        pdfDone.tap()
        
        //Back in the folder...
        
        namingConventionTextField.tap()
        namingConventionTextField.clearText()
        app.keyboards.buttons["Return"].tap()
        
        twoPageModeSwitch.tap() // Switch two-page mode off.
        newScanButton.tap()
        XCTAssert(vnDocExists, "Failed to open in 5 seceonds")
        expectation(for: exists, evaluatedWith: newDocAlert, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        let fileNameTextField = newDocAlert.textFields.element
        fileNameTextField.typeText("fileToMerge")
        alertSaveButton.tap()
        let selectButton = app.buttons["Select"]
        selectButton.tap()
        let newDocCell2 = docCollectionView.cells["fileToMerge"]
        newDocCell.tap()
        newDocCell2.tap()
        let merge = app.buttons["Merge"]
        merge.tap()
        let mergedDocCell = docCollectionView.cells["Merged_2.pdf"]
        mergedDocCell.tap()
        expectation(for: exists, evaluatedWith: pdfView, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        pdfDone.tap()
        newDocCell2.press(forDuration: 1.0)
        
        // Wait for the "Rename" option to appear in the context menu
        let renameOptionScan = app.buttons["Rename"]
        renameOptionScan.tap()
        
        let renameAlertScan = app.alerts["Rename Document"]
        expectation(for: exists, evaluatedWith: renameAlertScan, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        let renameTextField1 = renameAlertScan.textFields.element
        renameTextField1.clearText()
        renameTextField1.typeText("renamed")
        let saveRename = renameAlertScan.buttons["Save"]
        saveRename.tap()
        newDocCell2.press(forDuration: 1.0)
        let deleteOptionScan = app.buttons["Delete"]
        deleteOptionScan.tap()
        
        let backToHome = app.buttons["Back"]
        backToHome.tap()
        
        newFolderCell.press(forDuration: 1)
        let renameOptionFolder = app.buttons["Rename"]
        renameOptionFolder.tap()
        let renameAlertFolder = app.alerts["Rename Folder"]
        expectation(for: exists, evaluatedWith: renameAlertFolder, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        let renameTextField2 = renameAlertFolder.textFields.element
        renameTextField2.clearText()
        renameTextField2.typeText("toDelete")
        let saveRename2 = renameAlertFolder.buttons["Rename"]
        saveRename2.tap()
        
        newFolderCell = folderCV.cells["toDelete"]
        newFolderCell.press(forDuration: 1.0)
        let deleteOption = app.buttons["Delete"]
        deleteOption.tap()
        sleep(5) // Time to pause and view graphs.
    }

    func testBasicUserFlow() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        let addFolder = app.buttons["Add Folder"]
        addFolder.tap()
        
        let newFolderAlert = app.alerts["New Folder"]
        
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: newFolderAlert, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        let textField = newFolderAlert.textFields.element
        textField.typeText("TestFolder1")
        
        let addButtonOnAlert = newFolderAlert.buttons["Add"]
        addButtonOnAlert.tap()
        
        let collectionView = app.collectionViews["folderCV"]
        let newFolderCell = collectionView.cells["TestFolder1"]
        newFolderCell.tap()
        
        let newScanButton = app.buttons["New Scan"]
        newScanButton.tap()
        
        let vnDocVC = app.otherElements["vnDocCam"]
        let vnDocExists = vnDocVC.waitForExistence(timeout: 5)
        XCTAssert(vnDocExists, "Failed to open in 5 seceonds")
        
        let newDocAlert = app.alerts["File Name"]
        expectation(for: exists, evaluatedWith: newDocAlert, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        let fileNameTextField = newDocAlert.textFields.element
        fileNameTextField.typeText("TestDoc1")
        let alertSaveButton = app.buttons["Save"]
        alertSaveButton.tap()
        let docCollectionView = app.collectionViews["docCV"]
        let newDocCell = docCollectionView.cells["TestDoc1"]
        newDocCell.tap()
        sleep(5)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = stringValue.map { _ in XCUIKeyboardKey.delete.rawValue }.joined(separator: "")
        typeText(deleteString)
    }
}

