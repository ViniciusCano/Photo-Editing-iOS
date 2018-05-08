//
//  PhotoEditingViewController.swift
//  MyPhotoExt
//
//  Created by Vinícius Cano Santos on 01/02/18.
//  Copyright © 2018 Vinícius Cano Santos. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class PhotoEditingViewController: UIViewController, PHContentEditingController {

    //Declaração de variáveis
    @IBOutlet weak var imageView: UIImageView!
    
    var input: PHContentEditingInput?
    var displayedImage: UIImage?
    var imageOrientation: Int32?
    var currentFilter = "CIColorInvert"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - PHContentEditingController
    
    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        // Inspect the adjustmentData to determine whether your extension can work with past edits.
        // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
        return false
    }
    
    func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: UIImage) {
        // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
        // If you returned true from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
        // If you returned false, the contentEditingInput has past edits "baked in".
        input = contentEditingInput
        
        if input != nil {
            displayedImage = input!.displaySizeImage
            imageOrientation = input!.fullSizeImageOrientation
            imageView.image = displayedImage
        }
    }
    
    func finishContentEditing(completionHandler: @escaping ((PHContentEditingOutput?) -> Void)) {
        // Update UI to reflect that editing has finished and output is being rendered.
        
        // Render and provide output on a background queue.
        DispatchQueue.global().async {
            // Create editing output from the editing input.
            let output = PHContentEditingOutput(contentEditingInput:
                self.input!)
            let url = self.input?.fullSizeImageURL
            
            if let imageUrl = url {
                let fullImage = UIImage(contentsOfFile:
                    imageUrl.path)
                
                let resultImage = self.performFilter(fullImage!,
                                                     orientation: self.imageOrientation)
                
                if let renderedJPEGData =
                    UIImageJPEGRepresentation(resultImage!, 0.9) {
                    try! renderedJPEGData.write(to:
                        output.renderedContentURL)
                }
                let archivedData =
                    NSKeyedArchiver.archivedData(
                        withRootObject: self.currentFilter)
                
                let adjustmentData =
                    PHAdjustmentData(formatIdentifier:
                        "com.ebookfrenzy.photoext",
                                     formatVersion: "1.0",
                                     data: archivedData)
                
                output.adjustmentData = adjustmentData
            }
            completionHandler(output)
        }
    }
    
    var shouldShowCancelConfirmation: Bool {
        // Determines whether a confirmation to discard changes should be shown to the user on cancel.
        // (Typically, this should be "true" if there are any unsaved changes.)
        return false
    }
    
    func cancelContentEditing() {
        // Clean up temporary files, etc.
        // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
    }
    
    
    @IBAction func sepiaSelected(_ sender: Any) {
        currentFilter = "CISepiaTone"
        
        if displayedImage != nil {
            imageView.image = performFilter(displayedImage!, orientation: nil)
        }
    }
    
    @IBAction func monoSelected(_ sender: Any) {
        currentFilter = "CIPhotoEffectMono"
        
        if displayedImage != nil {
            imageView.image = performFilter(displayedImage!, orientation: nil)
        }
    }
    
    @IBAction func invertSelected(_ sender: Any) {
        currentFilter = "CIColorInvert"
        
        if displayedImage != nil {
            imageView.image = performFilter(displayedImage!, orientation: nil)
        }
    }
    
    func performFilter(_ inputImage: UIImage, orientation: Int32?) -> UIImage? {
        var resultImage: UIImage?
        var cimage = CIImage(image: inputImage)!
        
        if orientation != nil {
            cimage = cimage.oriented(forExifOrientation: orientation!)
        }
        
        if let filter = CIFilter(name: currentFilter) {
            filter.setDefaults()
            filter.setValue(cimage, forKey: "inputImage")
            
            let ciFilteredImage = filter.outputImage
            let context = CIContext(options: nil)
            let cgImage = context.createCGImage(ciFilteredImage!, from: ciFilteredImage!.extent)
            resultImage = UIImage(cgImage: cgImage!)
        }
        return resultImage
    }

}
