//
//  Folder.swift
//  SwiftScanPro
//
//  Created by Yashil Luckan on 2023/09/12.
//
import Foundation
struct Folder: Codable {
    var name: String
    var documentPaths: [String] = []
    
    init(name: String) {
        self.name = name
    }
}
