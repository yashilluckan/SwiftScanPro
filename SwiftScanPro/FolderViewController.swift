//
//  ViewController.swift
//  SwiftScanPro
//
//  Created by Yashil Luckan on 2023/09/12.
//

import UIKit
import Vision
import VisionKit
import PDFKit

class FolderViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var setNamingConventionTextField: UITextField!
    @IBOutlet weak var twoPageModeSwitch: UISwitch!
    @IBOutlet weak var documentCollectionView: UICollectionView!
    //MARK: - Local Variables:
    var scannedImages: [UIImage] = []
    var totalPagesToScan = 0
    var folderIndex : Int = 0
    var foldersArrayReference : [Folder] = []
    var isInSelectionMode: Bool = false
    // Pre-define merge button
    let mergeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Merge", for: .normal)
        button.backgroundColor = UIColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.00)
        button.tintColor = UIColor.white
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(mergeTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Nav Bar:
        self.title = foldersArrayReference[folderIndex].name
        let scanButton = UIBarButtonItem(title: "New Scan", style: .plain, target: self, action: #selector(scanTapped))
        let doneButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(doneTapped))
        self.navigationItem.leftBarButtonItem = doneButton
        let selectButton = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(toggleSelection))
        navigationItem.rightBarButtonItems = [selectButton, scanButton]
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = UIColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.00)
        navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor(red: 0.61, green: 0.53, blue: 1.00, alpha: 1.00)]
        view.addSubview(mergeButton)
        NSLayoutConstraint.activate([
            mergeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mergeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            mergeButton.widthAnchor.constraint(equalToConstant: 50),
            mergeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        mergeButton.isHidden = true
        mergeButton.accessibilityIdentifier = "Merge"
        twoPageModeSwitch.isOn = false
        // Load in the collectionView cell:
        documentCollectionView.register(UINib(nibName: "DocumentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "DocumentCollectionViewCell")
        
        // Delegates:
        documentCollectionView.dataSource = self
        documentCollectionView.delegate = self
        setNamingConventionTextField.delegate = self
        documentCollectionView.accessibilityIdentifier = "docCV"
        // Update:
        foldersArrayReference = FolderManager.shared.loadFolders()
        cleanupCorruptedFiles()
        documentCollectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("REF: \(foldersArrayReference[folderIndex])")
        print("ALL DOCS: \(foldersArrayReference[folderIndex].documentPaths)")
        foldersArrayReference = FolderManager.shared.loadFolders()
        // Load naming convention
        let folderName = foldersArrayReference[folderIndex].name
        if let namingConvention = getNamingConvention(forFolder: folderName) {
            setNamingConventionTextField.text = namingConvention
        } else {
            setNamingConventionTextField.placeholder = "Not set"
        }
        documentCollectionView.reloadData()
    }
    
    //MARK: - NavigationBar Items:
    @objc func scanTapped() {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.view.accessibilityIdentifier = "vnDocCam"
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }
    
    @objc func doneTapped() {
        // Dismiss the FolderViewController
        FolderManager.shared.saveFolders(self.foldersArrayReference)
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Two-Page Mode:
    
    @IBAction func twoPageModeToggled(_ sender: UISwitch) {
        if sender.isOn {
            let alertController = UIAlertController(title: "Page Count", message: "How many pages will you be scanning?", preferredStyle: .alert)
            alertController.addTextField { (textField) in
                textField.placeholder = "Number of pages"
                textField.keyboardType = .numberPad
            }
            
            let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
                if let pageCount = alertController.textFields?.first?.text, let count = Int(pageCount) {
                    self?.totalPagesToScan = count
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                sender.isOn = false
            }
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        } else {
            totalPagesToScan = 0
        }
    }
    
    func processScannedImages(_ images: [UIImage]) -> [UIImage] {
        var processedImages: [UIImage] = []
        
        for (index, image) in images.enumerated() {
            if totalPagesToScan % 2 == 1 && index == images.count - 1 {
                // If total pages are odd and this is the last image, don't split
                processedImages.append(image)
            } else {
                if let leftPage = image.leftHalf, let rightPage = image.rightHalf {
                    processedImages.append(leftPage)
                    processedImages.append(rightPage)
                }
            }
        }
        
        return processedImages
    }
    //MARK: - PDF Handling:
    func saveImagesAsPDF(images: [UIImage], withName name: String) -> String? {
        let pdfDocument = PDFDocument()
        
        for image in images {
            guard let pdfPage = PDFPage(image: image) else { continue }
            pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfURL = documentsDirectory.appendingPathComponent("\(name)")
        
        do {
            try pdfDocument.write(to: pdfURL)
            print("PDF saved at: \(pdfURL)")
            return pdfURL.lastPathComponent
        } catch {
            print("Error writing PDF: \(error)")
            return nil
        }
    }
    
    func cleanupCorruptedFiles() {
        var indicesToRemove: [Int] = []
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        for (index, documentPathString) in foldersArrayReference[folderIndex].documentPaths.enumerated() {
            let fullPath = documentDirectory.appendingPathComponent(documentPathString)
            if !FileManager.default.fileExists(atPath: fullPath.path) {
                indicesToRemove.append(index)
            }
        }
        
        for index in indicesToRemove.reversed() {
            foldersArrayReference[folderIndex].documentPaths.remove(at: index)
        }
        
        FolderManager.shared.saveFolders(foldersArrayReference)
    }
    
    func deleteDocument(at indexPath: IndexPath) {
        let documentName = foldersArrayReference[folderIndex].documentPaths[indexPath.item]
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let documentFullPath = documentDirectory.appendingPathComponent(documentName)
        
        do {
            try FileManager.default.removeItem(at: documentFullPath)
            foldersArrayReference[folderIndex].documentPaths.remove(at: indexPath.item)
            documentCollectionView.deleteItems(at: [indexPath])
        } catch {
            print("Error deleting document: \(error)")
            foldersArrayReference[folderIndex].documentPaths.remove(at: indexPath.item)
            documentCollectionView.deleteItems(at: [indexPath])
        }
    }
    
    //MARK: - Merge Functionality:
    @objc func toggleSelection() {
        if isInSelectionMode {
            if let selectedItems = documentCollectionView.indexPathsForSelectedItems {
                for indexPath in selectedItems {
                    documentCollectionView.deselectItem(at: indexPath, animated: true)
                }
            }
        }
        isInSelectionMode = !isInSelectionMode
        documentCollectionView.allowsMultipleSelection = isInSelectionMode
        navigationItem.rightBarButtonItem?.title = isInSelectionMode ? "Cancel" : "Select"
        mergeButton.isHidden = true
    }
    
    @objc func mergeTapped() {
        print("Merge Tapped")
        guard let selectedIndexPaths = documentCollectionView.indexPathsForSelectedItems else { return }
        
        let selectedDocuments = selectedIndexPaths.compactMap { foldersArrayReference[folderIndex].documentPaths[$0.item] }
        let documentCount = foldersArrayReference[folderIndex].documentPaths.count
        let newDocumentName = "Merged_\(documentCount)"
        if mergePDFs(from: selectedDocuments, to: newDocumentName) {
            print("Merged")
            documentCollectionView.reloadData()
            toggleSelection()
        }
    }
    
    func updateMergeButtonVisibility() {
        if let selectedItems = documentCollectionView.indexPathsForSelectedItems, selectedItems.count > 1 {
            print("Greater than one so visible.")
            mergeButton.isHidden = false
        } else {
            print("Less than one so not visible.")
            mergeButton.isHidden = true
        }
    }
    
    
    func mergePDFs(from paths: [String], to newDocumentName: String) -> Bool {
        let pdfDocument = PDFDocument()
        
        for path in paths {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fullPath = documentDirectory.appendingPathComponent(path)
            
            if let sourceDocument = PDFDocument(url: fullPath) {
                for index in 0..<sourceDocument.pageCount {
                    if let page = sourceDocument.page(at: index) {
                        pdfDocument.insert(page, at: pdfDocument.pageCount)
                    }
                }
            }
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfURL = documentsDirectory.appendingPathComponent("\(newDocumentName).pdf")
        
        do {
            try pdfDocument.write(to: pdfURL)
            foldersArrayReference[folderIndex].documentPaths.append("\(newDocumentName).pdf")
            return true
        } catch {
            print("Error writing merged PDF: \(error)")
            return false
        }
    }
    
    //MARK: - Rename Feature:
    func renameDocument(at indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Rename Document", message: "Provide a new name for the document:", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "New name"
            textField.text = self.foldersArrayReference[self.folderIndex].documentPaths[indexPath.item] // Current name
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let strongSelf = self else { return }
            if let newName = alertController.textFields?.first?.text {
                let oldName = strongSelf.foldersArrayReference[strongSelf.folderIndex].documentPaths[indexPath.item]
                
                // Rename the file on disk
                if strongSelf.renameFileOnDisk(oldName: oldName, newName: newName) {
                    // Update the name in the array
                    strongSelf.foldersArrayReference[strongSelf.folderIndex].documentPaths[indexPath.item] = newName
                    strongSelf.documentCollectionView.reloadData()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    func renameFileOnDisk(oldName: String, newName: String) -> Bool {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let oldPath = documentDirectory.appendingPathComponent(oldName)
        let newPath = documentDirectory.appendingPathComponent(newName)
        
        do {
            try FileManager.default.moveItem(at: oldPath, to: newPath)
            return true
        } catch {
            print("Error renaming file: \(error)")
            return false
        }
    }
    //MARK: - CollectionViewDelegate Methods:
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return foldersArrayReference[folderIndex].documentPaths.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DocumentCollectionViewCell", for: indexPath) as! DocumentCollectionViewCell
        let documentPathString = foldersArrayReference[folderIndex].documentPaths[indexPath.item]
        let documentPath = URL(fileURLWithPath: documentPathString)
        cell.configure(with: documentPathString)
        cell.accessibilityIdentifier = documentPath.lastPathComponent
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 10  // Adjust this value as needed
        let collectionViewSize = collectionView.frame.size.width - (padding*3)
        return CGSize(width: collectionViewSize/2, height: collectionViewSize/2)  // Adjust height as needed
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deleteDocument(at: indexPath)
            }
            let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.renameDocument(at: indexPath)
            }
            return UIMenu(title: "", children: [renameAction, deleteAction])
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Did Select")
        if isInSelectionMode {
            updateMergeButtonVisibility()
            print("Update called.")
        } else {
            let documentName = foldersArrayReference[folderIndex].documentPaths[indexPath.item]
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fullDocumentPath = documentsDirectory.appendingPathComponent(documentName)
            print("Before sending to PDFViewVC: \(fullDocumentPath)")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let pdfVC = storyboard.instantiateViewController(withIdentifier: "PDFViewController") as! PDFViewController
            pdfVC.path = fullDocumentPath
            pdfVC.navTitle = documentName
            let navController = UINavigationController(rootViewController: pdfVC)
            navController.modalTransitionStyle = .coverVertical
            navController.modalPresentationStyle = .overFullScreen
            
            self.present(navController, animated: true, completion: nil)
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if isInSelectionMode {
            if let selectedItems = collectionView.indexPathsForSelectedItems, selectedItems.count < 2 {
                mergeButton.isHidden = true
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if !isInSelectionMode {
            let documentName = foldersArrayReference[folderIndex].documentPaths[indexPath.item]
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fullDocumentPath = documentsDirectory.appendingPathComponent(documentName)
            print("Before sending to PDFViewVC: \(fullDocumentPath)")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let pdfVC = storyboard.instantiateViewController(withIdentifier: "PDFViewController") as! PDFViewController
            pdfVC.path = fullDocumentPath
            pdfVC.navTitle = documentName
            let navController = UINavigationController(rootViewController: pdfVC)
            self.present(navController, animated: true, completion: nil)
            return false  // This will prevent the cell from being "selected"
        }
        return true
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10  // Change this value as needed
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10  // Change this value as needed
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)  // Adjust these as needed
    }
    //MARK: - Set Naming Convention:
    // To save the naming convention
    func saveNamingConvention(forFolder folderName: String, namingConvention: String) {
        UserDefaults.standard.setValue(namingConvention, forKey: folderName)
    }
    
    // To retrieve the naming convention
    func getNamingConvention(forFolder folderName: String) -> String? {
        return UserDefaults.standard.string(forKey: folderName)
    }
    
    func generateFileName(forFolder folderName: String) -> String {
        if let namingConvention = getNamingConvention(forFolder: folderName) {
            // Retrieve the count of existing files in the folder to use as the unique identifier
            let fileCount = countFilesInFolder(folderName: folderName) + 1
            return "\(namingConvention)_\(fileCount).pdf"
        } else {
            // Return a default file name.
            return "DefaultFileName.pdf" // Added .pdf
        }
    }
    
    func countFilesInFolder(folderName: String) -> Int {
        if let index = foldersArrayReference.firstIndex(where: { $0.name == folderName }) {
            return foldersArrayReference[index].documentPaths.count
        }
        return 0
    }
    //MARK: - Override to present next screen in fullscreen:
    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil) {
        viewControllerToPresent.modalPresentationStyle = .fullScreen
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}
//MARK: - VNDocumentCameraViewControllerDelegate Methods:
extension FolderViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        for i in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: i)
            scannedImages.append(image) //Append scanned images to array.
        }
        if twoPageModeSwitch.isOn {
            scannedImages = processScannedImages(scannedImages)
        }
        let alertController = UIAlertController(title: "File Name", message: "Please provide a name for the document:", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            let folderName = self.foldersArrayReference[self.folderIndex].name
            if let namingConvention = self.getNamingConvention(forFolder: folderName), !namingConvention.isEmpty {
                textField.text = self.generateFileName(forFolder: folderName) // Use the naming convention with a unique identifier
            } else {
                textField.placeholder = "File name" // Default placeholder if no naming convention is set
            }
        }
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let fileName = alertController.textFields?.first?.text, let strongSelf = self {
                if let savedPDFFileName = strongSelf.saveImagesAsPDF(images: strongSelf.scannedImages, withName: fileName) {
                    // Handle saved PDF
                    strongSelf.foldersArrayReference[self!.folderIndex].documentPaths.append(savedPDFFileName)
                    FolderManager.shared.saveFolders(strongSelf.foldersArrayReference)
                    strongSelf.documentCollectionView.collectionViewLayout.invalidateLayout()
                    strongSelf.documentCollectionView.reloadData()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        // Dismiss the scanner view controller first
        controller.dismiss(animated: true) { [weak self] in
            // Present the alert after the scanner has been dismissed
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true)
    }
}
//MARK: - UITextField Delegate Methods for Naming Convention:
extension FolderViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == setNamingConventionTextField {
            // Save naming convention when return is pressed
            let folderName = foldersArrayReference[folderIndex].name
            if let namingConvention = textField.text {
                saveNamingConvention(forFolder: folderName, namingConvention: namingConvention)
            }
            textField.resignFirstResponder() // Close the keyboard
        }
        return true
    }
}

//MARK: - Split Image for Two-Page Mode:
extension UIImage {
    var leftHalf: UIImage? {
        guard let cgImage = cgImage?.cropping(to: CGRect(x: 0, y: 0, width: size.width / 2, height: size.height)) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
    
    var rightHalf: UIImage? {
        guard let cgImage = cgImage?.cropping(to: CGRect(x: size.width / 2, y: 0, width: size.width / 2, height: size.height)) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
}
