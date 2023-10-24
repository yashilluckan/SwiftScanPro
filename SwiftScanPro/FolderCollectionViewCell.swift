//
//  FolderCollectionViewCell.swift
//  SwiftScanPro
//
//  Created by Yashil Luckan on 2023/09/12.
//

import UIKit

class FolderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var folderNameLabel: UILabel!
    @IBOutlet weak var folderIconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Set background color to grey
        contentView.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.15) // light grey with 15% opacity
        // Set corner radius
        contentView.layer.cornerRadius = 40 // set corner radius.
    }
    //MARK: - Configure the Folder Cell:
    func configure(with folder: Folder) {
        folderNameLabel.text = folder.name
        folderIconImageView.image = UIImage(named: "purplefolder")
    }
    
    
}
