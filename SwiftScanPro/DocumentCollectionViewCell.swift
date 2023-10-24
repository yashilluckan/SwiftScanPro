//
//  DocumentCollectionViewCell.swift
//  SwiftScanPro
//
//  Created by Yashil Luckan on 2023/09/13.
//

import UIKit
import PDFKit

class DocumentCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var docName: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            checkmarkImageView.isHidden = !isSelected
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.contentMode = .scaleAspectFit
    }
    //MARK: - Configure the document cell:
    func configure(with documentPathString: String) {
        // Set the document name based on the file URL
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let documentFullPath = documentDirectory.appendingPathComponent(documentPathString).path
        
        print("Cell Method Path of doc: \(documentFullPath)")
        let fileExists = FileManager.default.fileExists(atPath: documentFullPath)
        print("File exists: \(fileExists)")
        if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: documentFullPath)) {
            print("PDF Page Count: \(pdfDocument.pageCount)")
        } else {
            print("Failed to initialize PDFDocument")
        }
        if let docNameLabel = docName{
            docNameLabel.text = (documentFullPath as NSString).lastPathComponent
        }
        // Generate a thumbnail for the first page of the PDF
        if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: documentFullPath)),
           let firstPage = pdfDocument.page(at: 0) {
            let thumbnailSize = CGSize(width: 100, height: 150)  // Adjust as needed
            imageView?.image = firstPage.thumbnail(of: thumbnailSize, for: .mediaBox)
        }
    }
}
