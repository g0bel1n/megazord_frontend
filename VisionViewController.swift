/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements the Vision view controller.
*/

import UIKit
import AVFoundation
import Vision

class VisionViewController: ViewController {
    
    private var detectionOverlay: CALayer! = nil
    
    // Vision parts
    private var analysisRequests = [VNRequest]()
    private let sequenceRequestHandler = VNSequenceRequestHandler()
    
    // Registration history
    private let maximumHistoryLength = 15
    private var transpositionHistoryPoints: [CGPoint] = [ ]
    private var previousPixelBuffer: CVPixelBuffer?
    
    // The current pixel buffer undergoing analysis. Run requests in a serial fashion, one after another.
    private var currentlyAnalyzedPixelBuffer: CVPixelBuffer?
    
    // Queue for dispatching vision classification and barcode requests
    private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.FlowerShop.serialVisionQueue")
    var productViewOpen = false
    var details: Dictionary<String, Any>!
    
    fileprivate func showProductInfo(_ details: Dictionary<String, Any>) {
        let list_confusion = ["moteur"]
        // Perform all UI updates on the main queue.
        DispatchQueue.main.async(execute: {
            if self.productViewOpen {
                // Bail out early if another observation already opened the product display.
                return
            }
            self.productViewOpen = true
            print("here I am fucker")
            
            if list_confusion.contains(details["identifier"] as! String){
                                
                self.performSegue(withIdentifier: "showUndecidedSegue", sender: details["identifier"])
            }
            else {
                
                self.performSegue(withIdentifier: "showProductSegue", sender: details)
            }
        })
    }
    

    /// - Tag: SetupVisionRequest
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts.
        let error: NSError! = nil
        
        // Setup barcode detection.
        let barcodeDetection = VNDetectBarcodesRequest(completionHandler: { (request, error) in
            if let results = request.results as? [VNBarcodeObservation] {
                if let mainBarcode = results.first {
                    if let payloadString = mainBarcode.payloadStringValue {
                        return
                    }
                }
            }
        })
        self.analysisRequests = ([barcodeDetection])
        
        // Setup a classification request.
        guard let modelURL = Bundle.main.url(forResource: "MegaZord_mobilenetv2", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "The model file is missing."])
        }
        guard let objectRecognition = createClassificationRequest(modelURL: modelURL) else {
            return NSError(domain: "VisionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "The classification request failed."])
        }
        self.analysisRequests.append(objectRecognition)
        return error
    }
    
    private func createClassificationRequest(modelURL: URL) -> VNCoreMLRequest? {
        
        do {
            let objectClassifier = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let classificationRequest = VNCoreMLRequest(model: objectClassifier, completionHandler: { (request, error) in
                if let results = request.results as? [VNClassificationObservation] {
                    
                    if results.first!.confidence > 0.8 {
                        for res in results {
                            print("\(res.identifier) : \(res.confidence)")
                            
                        }
                        self.showProductInfo(["identifier": results.first!.identifier, "cameFromRefSRC": false])
                        print("\n\n")
                    }
                        
                    
                }
            })
            return classificationRequest
            
        } catch let error as NSError {
            print("Model failed to load: \(error).")
            return nil
        }
    }
    
    /// - Tag: AnalyzeImage
    private func analyzeCurrentImage() {
        // Most computer vision tasks are not rotation-agnostic, so it is important to pass in the orientation of the image with respect to device.
        let orientation = exifOrientationFromDeviceOrientation()
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentlyAnalyzedPixelBuffer!, orientation: orientation)
        visionQueue.async {
            do {
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer { self.currentlyAnalyzedPixelBuffer = nil }
                try requestHandler.perform(self.analysisRequests)
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    fileprivate func resetTranspositionHistory() {
        transpositionHistoryPoints.removeAll()
    }
    
    fileprivate func recordTransposition(_ point: CGPoint) {
        transpositionHistoryPoints.append(point)
        
        if transpositionHistoryPoints.count > maximumHistoryLength {
            transpositionHistoryPoints.removeFirst()
        }
    }
    /// - Tag: CheckSceneStability
    fileprivate func sceneStabilityAchieved() -> Bool {
        // Determine if we have enough evidence of stability.
        if transpositionHistoryPoints.count == maximumHistoryLength {
            // Calculate the moving average.
            var movingAverage: CGPoint = CGPoint.zero
            for currentPoint in transpositionHistoryPoints {
                movingAverage.x += currentPoint.x
                movingAverage.y += currentPoint.y
            }
            let distance = abs(movingAverage.x) + abs(movingAverage.y)
            if distance < 20 {
                return true
            }
        }
        return false
    }
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        guard previousPixelBuffer != nil else {
            previousPixelBuffer = pixelBuffer
            self.resetTranspositionHistory()
            return
        }
        
        if productViewOpen {
            return
        }
        let registrationRequest = VNTranslationalImageRegistrationRequest(targetedCVPixelBuffer: pixelBuffer)
        do {
            try sequenceRequestHandler.perform([ registrationRequest ], on: previousPixelBuffer!)
        } catch let error as NSError {
            print("Failed to process request: \(error.localizedDescription).")
            return
        }
        
        previousPixelBuffer = pixelBuffer
        
        if let results = registrationRequest.results {
            if let alignmentObservation = results.first as? VNImageTranslationAlignmentObservation {
                let alignmentTransform = alignmentObservation.alignmentTransform
                self.recordTransposition(CGPoint(x: alignmentTransform.tx, y: alignmentTransform.ty))
            }
        }
        if self.sceneStabilityAchieved() {
            showDetectionOverlay(true)
            if currentlyAnalyzedPixelBuffer == nil {
                // Retain the image buffer for Vision processing.
                currentlyAnalyzedPixelBuffer = pixelBuffer
                analyzeCurrentImage()
            }
        } else {
            showDetectionOverlay(false)
        }
    }
    
    private func showDetectionOverlay(_ visible: Bool) {
        DispatchQueue.main.async(execute: {
            // perform all the UI updates on the main queue
            self.detectionOverlay.isHidden = !visible
        })
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // setup Vision parts
        setupLayers()
        setupVision()
        
        // start the capture
        startCaptureSession()
    }
    
    func setupLayers() {
        detectionOverlay = CALayer()
        detectionOverlay.bounds = self.view.bounds.insetBy(dx: 15, dy: 100)
        detectionOverlay.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY*8/10)
        detectionOverlay.borderColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.46, 0.73, 0.24, 0.7])
        detectionOverlay.borderWidth = 8
        detectionOverlay.cornerRadius = 20
        detectionOverlay.isHidden = true
        rootLayer.addSublayer(detectionOverlay)
    }
    
    @IBAction func unwindToScanning(unwindSegue: UIStoryboardSegue) {
        productViewOpen = false
        self.resetTranspositionHistory() // reset scene stability
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let productVC = segue.destination as? ProductViewController, segue.identifier == "showProductSegue" {
            if let details = sender as? Dictionary<String, Any> {
                productVC.details = details
            }
        }
        if let productVC_2 = segue.destination as? UndecidedViewController, segue.identifier == "showUndecidedSegue" {
            if let class_product = sender as? String {
                productVC_2.class_product = class_product
            }
        }

    }
}
