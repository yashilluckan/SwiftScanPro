//
//  FolderManager.swift
//  SwiftScanPro
//
//  Created by Yashil Luckan on 2023/09/13.
//
import Foundation
class FolderManager {
    static let shared = FolderManager()
    
    private init() {} // This prevents others from using the default '()' initializer for this class
    
    var foldersFilePath: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent("folders.plist")
    }
    
    func saveFolders(_ folders: [Folder]) {
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(folders)
            try data.write(to: foldersFilePath)
        } catch {
            print("Error encoding folders array: \(error.localizedDescription)")
        }
    }
    
    func loadFolders() -> [Folder] {
        if let data = try? Data(contentsOf: foldersFilePath) {
            let decoder = PropertyListDecoder()
            do {
                return try decoder.decode([Folder].self, from: data)
            } catch {
                print("Error decoding folders array: \(error.localizedDescription)")
                return []
            }
        } else {
            return []
        }
    }
}
