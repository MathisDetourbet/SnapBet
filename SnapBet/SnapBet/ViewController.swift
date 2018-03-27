//
//  ViewController.swift
//  SnapBet
//
//  Created by Mathis Detourbet on 27/03/2018.
//  Copyright © 2018 Mathis Detourbet. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var permissionNotGrantedView: UIView!
    
    @IBAction func takePhotoAction(_ sender: UIButton) {
        
    }
    // MARK: -  Timer Properties
    
    let TIMER_STEP: TimeInterval = 0.01
    var timer = Timer()
    var secondsCounter: TimeInterval = 0
    
    var session = AVCaptureSession()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        var layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return layer
    }()
    
    let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                              for: AVMediaType.video,
                                              position: .front)
    
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: nil,
                                  options: [CIDetectorAccuracy : CIDetectorAccuracyLow])
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkCameraPermission { granted in
            DispatchQueue.main.async {
                self.updatePermissionUI(granted: granted)
            }
            
            if granted {
                self.sessionPrepare()
                self.session.startRunning()
                let notificationCenter = NotificationCenter.default
                notificationCenter.addObserver(self, selector: #selector(self.appMovedToBackground), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
                notificationCenter.addObserver(self, selector: #selector(self.appMovedToForeground), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewLayer?.frame = permissionNotGrantedView.frame
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let previewLayer = previewLayer else { return }
        view.layer.addSublayer(previewLayer)
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // correct rotation of video layer
        guard let previewLayer = previewLayer else { return }
        let deviceOrientation = UIDevice.current.orientation
        previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.init(deviceOrientantion: deviceOrientation)
    }
    
    @objc func appMovedToBackground() {
        timer.invalidate()
        secondsCounter = 0
    }
    
    @objc func appMovedToForeground() {
    }
    
    //MARK: - IBActions
    
    @IBAction func settingsButtonPushed(_ sender: UIButton) {
        UIApplication.shared.open(URL(string:"App-Prefs:root")!, options: [:], completionHandler: nil)
    }
}

// MARK: - AVCaptureSession setup
extension ViewController {
    
    func sessionPrepare() {
        
        guard let camera = frontCamera else { return }
        
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: camera)
            session.beginConfiguration()
            
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            
            output.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            session.commitConfiguration()
            
            let queue = DispatchQueue(label: "output.queue")
            output.setSampleBufferDelegate(self, queue: queue)
            
        } catch {
            print("Error creating AVCaptureDeviceInput")
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [String : Any]?)
        let options: [String : Any] = [
            CIDetectorImageOrientation: exifOrientation(orientation: UIDevice.current.orientation),
            CIDetectorSmile: true
        ]
        
        guard let features = faceDetector?.features(in: ciImage, options: options) else { return }
        
        if let faceFeature = (features.flatMap { $0 as? CIFaceFeature }.first) {
            
        } else {
            // face is not visible
        }
        
    }
    
    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
        switch orientation {
        case .portraitUpsideDown:
            return 8
        case .landscapeLeft:
            return 3
        case .landscapeRight:
            return 1
        default:
            return 6
        }
    }
}

// MARK: - Permissions
extension ViewController {
    
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            completion(true)
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                completion(granted)
            })
        }
    }
    
    func updatePermissionUI(granted: Bool) {
        permissionNotGrantedView.isHidden = granted
    }
}
