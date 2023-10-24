//
//  PDFViewController.swift
//  SwiftScanPro
//
//  Created by Yashil Luckan on 2023/09/13.
//

import UIKit
import PDFKit

class PDFViewController: UIViewController {
    var path : URL!
    var navTitle: String = ""
    let pdfView = PDFView()
    // Markup Buttons:
    var markupToolsContainer: UIView!
    var textboxButton: UIButton!
    var saveButton: UIBarButtonItem?
    var isTextboxMode = false
    // Markup Draw:
    var currentAnnotation: PDFAnnotation?
    var thumbnailView = PDFThumbnailView()
    var thumbnailToggleButton : UIBarButtonItem!
    
    override func viewDidLoad() {
        // Nav Bar Appearance:
        self.title = navTitle
        isModalInPresentation = true
        navigationController?.navigationBar.tintColor = UIColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.00)
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor(red: 0.61, green: 0.53, blue: 1.00, alpha: 1.00)]
        // Nav Bar Buttons
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneTapped))
        doneButton.accessibilityIdentifier = "Done"
        
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
        shareButton.accessibilityIdentifier = "Share"
        thumbnailToggleButton = UIBarButtonItem(image: UIImage(systemName: "list.bullet.circle"), style: .plain, target: self, action: #selector(toggleThumbnailView))
        thumbnailToggleButton.accessibilityIdentifier = "toggleThumbnailView"
        self.navigationItem.leftBarButtonItems = [doneButton, thumbnailToggleButton]
        // Set up PDFView and Thumbnail View
        // Initialize the thumbnail view
        thumbnailView = PDFThumbnailView(frame: .zero)
        // Associate it with the PDFView
        thumbnailView.pdfView = pdfView
        
        // Customize its appearance and behavior
        thumbnailView.thumbnailSize = CGSize(width: 80, height: 80)
        thumbnailView.layoutMode = .vertical
        thumbnailView.isHidden = true
        thumbnailView.accessibilityIdentifier = "thumbnailView"
        
        // Add it to the main view
        pdfView.accessibilityIdentifier = "pdfView"
        pdfView.displayMode = .singlePageContinuous
        pdfView.isUserInteractionEnabled = true
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.maxScaleFactor = 5.0
        pdfView.autoScales = true
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        view.addSubview(thumbnailView)
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            thumbnailView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            thumbnailView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            thumbnailView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 100) // Adjust width as needed
        ])
        
        pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pdfTapped))
        tapGesture.cancelsTouchesInView = false
        pdfView.addGestureRecognizer(tapGesture)
        
        
        if let document = PDFDocument(url: path!) {
            pdfView.document = document
        }
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(nextPage))
        swipeLeft.direction = .left
        swipeLeft.cancelsTouchesInView = false
        pdfView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(prevPage))
        swipeRight.direction = .right
        swipeRight.cancelsTouchesInView = false
        pdfView.addGestureRecognizer(swipeRight)
        
        //Markup:
        let markupButton = UIBarButtonItem(image: UIImage(systemName: "pencil.tip.crop.circle"), style: .plain, target: self, action: #selector(toggleMarkupTools))
        markupButton.accessibilityIdentifier = "markup"
        navigationItem.rightBarButtonItems = [markupButton, shareButton]
        NotificationCenter.default.addObserver(self, selector: #selector(documentChanged(_:)), name: Notification.Name.PDFViewDocumentChanged, object: nil)
        
        setupMarkupTools()
    }
    
    func setupMarkupTools() {
        // Container setup
        markupToolsContainer = UIView(frame: CGRect(x: 0, y: view.frame.height - 150, width: view.frame.width, height: 50))
        markupToolsContainer.backgroundColor = UIColor(red: 0.61, green: 0.53, blue: 1.00, alpha: 0.4)
        markupToolsContainer.layer.cornerRadius = 15
        markupToolsContainer.isHidden = true
        view.addSubview(markupToolsContainer)
        
        // Buttons setup
        textboxButton = UIButton(type: .system)
        textboxButton.accessibilityIdentifier = "textBoxButton"
        textboxButton.setImage(UIImage(systemName: "character.textbox"), for: .normal)
        textboxButton.tintColor = UIColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.00)
        textboxButton.addTarget(self, action: #selector(textboxModeActivated), for: .touchUpInside)
        
        
        // Stack view for horizontal layout
        let stackView = UIStackView(arrangedSubviews: [textboxButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.frame = markupToolsContainer.bounds
        markupToolsContainer.addSubview(stackView)
    }
    //MARK: - UIButton Functionality:
    @objc func documentChanged(_ notification: Notification) {
        addSaveButton()
    }
    
    @objc func toggleMarkupTools() {
        markupToolsContainer.isHidden.toggle()
    }
    
    @objc func textboxModeActivated() {
        isTextboxMode.toggle()
        addSaveButton()
    }
    
    @objc func saveChanges() {
        if let document = pdfView.document, let documentURL = document.documentURL {
            document.write(to: documentURL)
            let alert = UIAlertController(title: "Saved", message: "Your changes have been saved.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
        saveButton?.isHidden = true
        saveButton = nil
    }
    
    @objc func doneTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func nextPage() {
        pdfView.goToNextPage(nil)
    }
    
    @objc func prevPage() {
        pdfView.goToPreviousPage(nil)
    }
    //MARK: - Share Functionality:
    @objc func shareTapped() {
        guard let pdfPath = path else {
            print("No PDF here.")
            return
        }
        
        // Retrieve the PDF data
        guard let pdfData = try? Data(contentsOf: pdfPath) else {
            print("Failed to get PDF data.")
            return
        }
        
        // Determine the desired filename
        let desiredFilename = navTitle
        
        // Create a temporary URL with this filename
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent(desiredFilename + ".pdf")
        
        // Write the PDF data to this temporary URL
        do {
            try pdfData.write(to: tempFileURL)
        } catch {
            print("Error writing to temporary file: \(error)")
            return
        }
        
        // Share the temporary URL
        let activityVC = UIActivityViewController(activityItems: [tempFileURL], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityVC, animated: true)
    }
    
    @objc func toggleThumbnailView() {
        if thumbnailView.isHidden {
            thumbnailView.isHidden = false
            thumbnailToggleButton.image = UIImage(systemName: "list.bullet.circle.fill")
        } else {
            thumbnailView.isHidden = true
            thumbnailToggleButton.image = UIImage(systemName: "list.bullet.circle")
        }
    }
    //MARK: - Text Box Functionality:
    @objc func pdfTapped(recognizer: UITapGestureRecognizer) {
        guard isTextboxMode, let page = pdfView.page(for: recognizer.location(in: pdfView), nearest: true) else {
            return
        }
        let locationInView = recognizer.location(in: pdfView)
        let locationOnPage = pdfView.convert(locationInView, to: page)
        
        // Show dialog to get text
        let alertController = UIAlertController(title: "Enter Text", message: nil, preferredStyle: .alert)
        alertController.addTextField()
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            if let text = alertController.textFields?.first?.text {
                // Getting the width and height of annoted text:
                let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 70)]
                let attributedString = NSAttributedString(string: text, attributes: attributes)
                let stringSize = attributedString.size()
                let annotation = PDFAnnotation(bounds: CGRect(origin: locationOnPage, size: CGSize(width: stringSize.width, height: stringSize.height)), forType: .freeText, withProperties: nil)
                // Appearance of the annotation:
                annotation.font = UIFont.systemFont(ofSize: 70)
                annotation.color = UIColor.clear
                annotation.contents = text
                page.addAnnotation(annotation)
            }
        })
        present(alertController, animated: true)
    }
    //MARK: - Save Button Logic:
    func addSaveButton() {
        if saveButton == nil {
            saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveChanges))
            saveButton!.tintColor = UIColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.00)
            navigationItem.rightBarButtonItems?.append(saveButton!)
        }
    }
}
