////
////  ViewController.swift
////  SnapBet
////
////  Created by Mathis Detourbet on 27/03/2018.
////  Copyright © 2018 Mathis Detourbet. All rights reserved.
////
//
//import UIKit
//import AVFoundation
//
//public enum CameraSelection {
//    /// Camera on the back of the device
//    case rear
//    /// Camera on the front of the device
//    case front
//}
//
//class ViewController: UIViewController {
//
//    // MARK: - IBOutlets
//    @IBOutlet weak var permissionNotGrantedView: UIView!
//    @IBOutlet weak var screenShotImageView: UIImageView!
//
//    @IBAction func takePhotoAction(_ sender: UIButton) {
//        if let videoConnection = photoFileOutput?.connection(with: AVMediaType.video) {
//            photoFileOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: {(sampleBuffer, error) in
//                if (sampleBuffer != nil) {
//                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)
//                    let image = self.processPhoto(imageData!)
//                    // Call delegate and return new image
//                    DispatchQueue.main.async {
//                        self.screenShotImageView.image = image
//                    }
//                }
//            })
//        }
//    }
//
//    fileprivate var photoFileOutput : AVCaptureStillImageOutput?
//
//    var outputVideoData: AVCaptureVideoDataOutput!
//    var session = AVCaptureSession()
//
//    lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
//        var layer = AVCaptureVideoPreviewLayer(session: self.session)
//        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        return layer
//    }()
//
//    let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
//                                              for: AVMediaType.video,
//                                              position: .front)
//
//    let faceDetector = CIDetector(ofType: CIDetectorTypeFace,
//                                  context: nil,
//                                  options: [CIDetectorAccuracy : CIDetectorAccuracyLow])
//
//    // MARK: - Methods
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        checkCameraPermission { granted in
//            DispatchQueue.main.async {
//                self.updatePermissionUI(granted: granted)
//            }
//
//            if granted {
//                self.sessionPrepare()
//                self.previewLayer?.connection?.videoOrientation = .portrait
//                self.configurePhotoOutput()
//                self.session.startRunning()
//            }
//        }
//    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//
//        previewLayer?.frame = view.frame
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        guard let previewLayer = previewLayer else { return }
//        view.layer.insertSublayer(previewLayer, at: 0)
//    }
//
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//
//        // correct rotation of video layer
//        guard let previewLayer = previewLayer else { return }
//        let deviceOrientation = UIDevice.current.orientation
//        previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.init(deviceOrientantion: deviceOrientation)
//    }
//
//    fileprivate func configurePhotoOutput() {
//        let photoFileOutput = AVCaptureStillImageOutput()
//        if self.session.canAddOutput(photoFileOutput) {
//            photoFileOutput.outputSettings  = [AVVideoCodecKey: AVVideoCodecJPEG]
//            self.session.addOutput(photoFileOutput)
//            self.photoFileOutput = photoFileOutput
//        }
//    }
//
//    fileprivate func processPhoto(_ imageData: Data) -> UIImage {
//        let dataProvider = CGDataProvider(data: imageData as CFData)
//        let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
//        // Set proper orientation for photo
//        // If camera is currently set to front camera, flip image
//        let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: .downMirrored)
//        return image
//    }
//    
//    fileprivate func getImageOrientation(forCamera: CameraSelection) -> UIImageOrientation {
//        let deviceOrientation = UIDevice.current.orientation
//        switch deviceOrientation {
//        case .landscapeLeft:
//            return forCamera == .rear ? .up : .downMirrored
//        case .landscapeRight:
//            return forCamera == .rear ? .down : .upMirrored
//        case .portraitUpsideDown:
//            return forCamera == .rear ? .left : .rightMirrored
//        default:
//            return forCamera == .rear ? .right : .leftMirrored
//        }
//    }
//
//    //MARK: - IBActions
//
//    @IBAction func settingsButtonPushed(_ sender: UIButton) {
//        UIApplication.shared.open(URL(string:"App-Prefs:root")!, options: [:], completionHandler: nil)
//    }
//}
//
//// MARK: - AVCaptureSession setup
//extension ViewController {
//
//    func sessionPrepare() {
//
//        guard let camera = frontCamera else { return }
//
//        session.sessionPreset = AVCaptureSession.Preset.photo
//
//        do {
//            let deviceInput = try AVCaptureDeviceInput(device: camera)
//            session.beginConfiguration()
//
//            if session.canAddInput(deviceInput) {
//                session.addInput(deviceInput)
//            }
//
//            outputVideoData = AVCaptureVideoDataOutput()
//            outputVideoData.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
//
//            outputVideoData.alwaysDiscardsLateVideoFrames = true
//
//            if session.canAddOutput(outputVideoData) {
//                session.addOutput(outputVideoData)
//            }
//
//            session.commitConfiguration()
//
//            let queue = DispatchQueue(label: "output.queue")
//            outputVideoData.setSampleBufferDelegate(self, queue: queue)
//
//        } catch {
//            print("Error creating AVCaptureDeviceInput")
//        }
//    }
//}
//
//// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
//extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
//
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
//        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [String : Any]?)
////        guard !shouldTakePhoto else {
////            DispatchQueue.main.async {
////                let image = UIImage(ciImage: ciImage)
////                self.screenShotImageView.image = image
////                self.screenShotImageView.isHidden = false
////                self.session.stopRunning()
////            }
////            return
////        }
//
//        let options: [String : Any] = [
//            CIDetectorImageOrientation: exifOrientation(orientation: UIDevice.current.orientation),
//            CIDetectorSmile: true
//        ]
//
//        guard let features = faceDetector?.features(in: ciImage, options: options) else { return }
//
//        if let faceFeature = (features.flatMap { $0 as? CIFaceFeature }.first) {
//
//        } else {
//            // face is not visible
//        }
//
//    }
//
//    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
//        switch orientation {
//        case .portraitUpsideDown:
//            return 8
//        case .landscapeLeft:
//            return 3
//        case .landscapeRight:
//            return 1
//        default:
//            return 6
//        }
//    }
//}
//
//// MARK: - Permissions
//extension ViewController {
//
//    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
//        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
//            completion(true)
//        } else {
//            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
//                completion(granted)
//            })
//        }
//    }
//
//    func updatePermissionUI(granted: Bool) {
//        permissionNotGrantedView.isHidden = granted
//    }
//}

