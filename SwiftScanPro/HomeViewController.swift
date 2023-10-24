//
//  HomeViewController.swift
//  SwiftScanPro
//
//  Created by Yashil Luckan on 2023/09/12.
//

import UIKit

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    @IBOutlet weak var navBar: UINavigationBar!
    var appearance = UINavigationBarAppearance()
    var foldersArray: [Folder] = []
    var foldersFilePath: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent("folders.plist")
    }
    
    
    @IBOutlet weak var foldersCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        foldersCollectionView.register(UINib(nibName: "FolderCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "FolderCell")
        self.navBar.prefersLargeTitles = true
        foldersArray = FolderManager.shared.loadFolders()
        foldersCollectionView.dataSource = self
        foldersCollectionView.delegate = self
        foldersCollectionView.accessibilityIdentifier = "folderCV"
    }
    //new:
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        foldersArray = FolderManager.shared.loadFolders()
        // Load the foldersArray from persistent storage
        foldersCollectionView.reloadData()
        navBar.largeTitleTextAttributes = [.foregroundColor: UIColor(red: 0.61, green: 0.53, blue: 1.00, alpha: 1.00)]
        navBar.tintColor = UIColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.00)
    }
    
    @IBAction func addFolderTapped(_ sender: UIBarButtonItem) {
        // Create an alert
        let alertController = UIAlertController(title: "New Folder", message: "Enter a name for this folder.", preferredStyle: .alert)
        
        // Add a text field to the alert for the folder name
        alertController.addTextField { textField in
            textField.placeholder = "Folder Name"
        }
        
        // Add a "Cancel" action to the alert
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Add an "Add" action to the alert
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            if let folderName = alertController.textFields?.first?.text, !folderName.isEmpty {
                // Check if folder with same name already exists
                if self?.foldersArray.contains(where: { $0.name == folderName }) == false {
                    // Add the new folder to the data source
                    self?.foldersArray.append(Folder(name: folderName))
                    FolderManager.shared.saveFolders(self?.foldersArray ?? [])
                    //self?.saveFolders()
                    // Reload the collection view
                    self?.foldersCollectionView.reloadData()
                } else {
                    // Present an error if the folder name already exists
                    self?.showError(message: "A folder with this name already exists!")
                }
            } else {
                // Present an error if the folder name is empty
                self?.showError(message: "Folder name cannot be empty!")
            }
        })
        // Present the alert
        present(alertController, animated: true, completion: nil)
    }
    
    func showError(message: String) {
        let errorAlert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(errorAlert, animated: true, completion: nil)
    }
    
    //MARK: - Folder Management Methods:
    func deleteFolder(at indexPath: IndexPath) {
        // Remove the folder from the data source
        foldersArray.remove(at: indexPath.item)
        // Save the updated foldersArray to disk
        FolderManager.shared.saveFolders(foldersArray)
        // Update the collection view
        foldersCollectionView.deleteItems(at: [indexPath])
    }
    
    func renameFolder(at indexPath: IndexPath) {
        let oldFolderName = foldersArray[indexPath.item].name
        let alertController = UIAlertController(title: "Rename Folder", message: "Enter a new name for this folder.", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.text = oldFolderName
        }
        
        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            if let newName = alertController.textFields?.first?.text, !newName.isEmpty {
                if self?.foldersArray.contains(where: { $0.name == newName }) == false {
                    // Rename the folder in the data source
                    self?.foldersArray[indexPath.item].name = newName
                    // Save the updated foldersArray to disk
                    FolderManager.shared.saveFolders(self?.foldersArray ?? [])
                    // Reload the collection view
                    self?.foldersCollectionView.reloadData()
                } else {
                    self?.showError(message: "A folder with this name already exists!")
                }
            } else {
                self?.showError(message: "Folder name cannot be empty!")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(renameAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    //MARK: - CollectionVIew Delegate Methods:
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FolderCell", for: indexPath) as! FolderCollectionViewCell
        let folder = foldersArray[indexPath.item]
        cell.configure(with: folder)
        cell.accessibilityIdentifier = folder.name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return foldersArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 10  // Adjust this value as needed
        let collectionViewSize = collectionView.frame.size.width - padding
        return CGSize(width: collectionViewSize/2, height: collectionViewSize/2)  // Adjust height as needed
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected folder")
        //let selectedFolder = foldersArray[indexPath.item]
        let selectedFolderIndex = indexPath.item
        // instantiate the FolderDetailViewController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailVC = storyboard.instantiateViewController(withIdentifier: "FolderViewController") as! FolderViewController
        // detailVC.folder = selectedFolder
        // New:
        detailVC.folderIndex = selectedFolderIndex
        detailVC.foldersArrayReference = self.foldersArray
        let navController = UINavigationController(rootViewController: detailVC)
        self.present(navController, animated: true, completion: nil)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deleteFolder(at: indexPath)
            }
            let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.renameFolder(at: indexPath)
            }
            return UIMenu(title: "", children: [renameAction, deleteAction])
        }
    }
    
}
