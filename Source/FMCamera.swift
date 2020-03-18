//
//  FMCamera.swift
//  fmcamera
//
//  Created by gokhan on 28.01.2020.
//  Copyright © 2020 gokhan. All rights reserved.
//

import AVFoundation
import Photos
import UIKit

/**
 With this protocol you can start and stop recording.
 */
public protocol FMCaptureVideoProtocol {
    func recordingStarted(_ error: Error?)
    func recordingFinished(_ videoUrl: URL?, _ error: Error?)
}

/// Delegate for start and stop recording events.
public var fmCaptureVideoDelegate: FMCaptureVideoProtocol?

/**
 With this protocol you can start and stop recording.
 */
public protocol FMCapturePhotoProtocol {
    func captured(_ image: UIImage, data: Data)
}

/// Delegate for capture photo event.
public var fmCapturePhotoDelegate: FMCapturePhotoProtocol?

/// Use when getting video when you use library or camera.
public enum VideoSource {
    case camera
    case library
}

public class FMCamera: UIView {
    // MARK: Parameters
    private var session: AVCaptureSession = AVCaptureSession()
    private var deviceInput: AVCaptureDeviceInput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Outputs
    private var videoOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    private var audioOutput: AVCaptureAudioDataOutput = AVCaptureAudioDataOutput()
    
    // Photo Output
    private var stillImageOutput: AVCapturePhotoOutput!
    
    // Connections
    
    private var videoDevice: AVCaptureDevice = AVCaptureDevice.default(for: .video)!
    private var audioConnection: AVCaptureConnection?
    private var videoConnection: AVCaptureConnection?
    
    // Assets
    private var assetWriter: AVAssetWriter?
    private var audioInput: AVAssetWriterInput?
    private var videoInput: AVAssetWriterInput?
    
    // File Management
    private var fileManager: FileManager = FileManager()
    private var recordingURL: URL?
    
    // Flags
    /**
     Check if recording started.
     ### Default: ###
     ````
     false
     ````
     */
    public var isCameraRecording: Bool = false
    private var isConfigured: Bool = false
    private var isRecordingSessionStarted: Bool = false
    private var currentPosition: AVCaptureDevice.Position = .back
    
    // Config Parameters
    /**
     Flash mode for capturing. You can update it before calling configure()
     ### Default: ###
     ````
     .auto
     ````
     */
    public var flashMode: AVCaptureDevice.FlashMode = .auto
    
    public var sPreset: AVCaptureSession.Preset = .low
    
    /**
      Update this for save the photo to your Photos.
     
      ### Default: ###
      ````
     false
      ````
     */
    public var willSavePhotoToPhotos: Bool = false
    /**
      Update this for save the video to your Photos.
     
      ### Default: ###
      ````
     false
      ````
     */
    public var willSaveVideoToPhotos: Bool = false
    // Settings
    /**
      Audio settings for audio capturing. You can update it before calling configure()
     
     ### Default: ###
     ````
     [
         AVFormatIDKey: kAudioFormatMPEG4AAC,
         AVNumberOfChannelsKey: 1,
         AVSampleRateKey: 48000.0
     ]
     ````
     */
    public var audioSettings: [String: Any] = [:]
    /**
      Video settings for recording video. You can update it before calling configure()
      Needs a ratio firts: `let ratio = frame.width / frame.height` You can specify a custom ratio
      and change the values if you want.
     
     ### Default: ###
     ````
     [
         AVVideoCodecKey: AVVideoCodecType.h264,
         AVVideoWidthKey: 1080,
         AVVideoHeightKey: 1080 * ratio,
         AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill
     ]
     ````
     */
    public var videoSettings: [String: Any] = [:]
    /**
      Capture photo format. You can update it before calling configure()
     
     ### Default: ###
     ````
     [
         AVVideoCodecKey: AVVideoCodecType.jpeg
     ]
     ````
     */
    public var photoSettingsFormat: [String: Any]?
    
    /**
      Set max picture file size in bytes. You can update it before taking a picture.
     
     ### Default: ###
     ````
     400000, ~400 KB
     ````
     */
    public var maxPictureFileSize: Int = 400000
    
    /**
      Save original or save reduced image to photo roll. You can update it before taking a picture.
     Works if willSaveVideoToPhotos is true.
     
     ### Default: ###
     ````
     false
     ````
     */
    public var saveReducedImageToPhotos: Bool = false
    
    /**
     Decide if the captured photo rotates upwards. After capturing, photo always oriented upwards if you set this flag to true.
     
      ### Default: ###
      ````
      false
      ````
     */
    public var rotateCapturedPhotoUpwards: Bool = false
    
    // Queue
    private var recordingQueue = DispatchQueue(label: "recording.queue")
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    // MARK: - Setup
    fileprivate func setupView() {
        let view = viewFromNibForClass()
        view.frame = bounds
        view.autoresizingMask = [
            UIView.AutoresizingMask.flexibleWidth,
            UIView.AutoresizingMask.flexibleHeight
        ]
        
        let ratio = frame.width / frame.height
        
        audioSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 48000.0
        ] as [String: Any]
        
        videoSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1080,
            AVVideoHeightKey: 1080 * ratio,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill
        ] as [String: Any]
        
        addSubview(view)
    }
    
    /// Loads a XIB file into a view and returns this view.
    fileprivate func viewFromNibForClass() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
}

// MARK: - Class Functions
extension FMCamera {
    public func configure() {
        /// Request authorization if necessary
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                DispatchQueue.main.async {
                    self.readyForConfiguration()
                }
            case .denied:
                print("Should open settings")
            case .notDetermined,
                 .restricted:
                break
            default:
                break
            }
        }
    }
    
    /**
     Starts recording video
     */
    public func startRecording() {
        if isConfigured {
            if assetWriter != nil {
                if assetWriter!.status == .unknown {
                    assetWriter!.startWriting()
                }
                videoOutput.setSampleBufferDelegate(self, queue: recordingQueue)
                audioOutput.setSampleBufferDelegate(self, queue: recordingQueue)
                isCameraRecording = true
            } else {
                configureSession()
                addSettings()
                isRecordingSessionStarted = false
                if session.isRunning {
                    session.startRunning()
                }
                startRecording()
            }
        } else {
            print("SC CAMERA ERROR: Please configure your camera view before recording video. ( Call configure() )")
        }
    }
    
    /**
     Stops recording video
     */
    public func stopRecording() {
        videoOutput.setSampleBufferDelegate(nil, queue: nil)
        audioOutput.setSampleBufferDelegate(nil, queue: nil)
        
        if assetWriter != nil, recordingURL != nil {
            assetWriter?.finishWriting {
                self.isCameraRecording = false
                DispatchQueue.main.async {
                    fmCaptureVideoDelegate?.recordingFinished(self.recordingURL, nil)
                }
            }
            assetWriter = nil
        }
        if willSaveVideoToPhotos {
            saveVideo()
        }
    }
    
    /**
     Take photo
     */
    public func takePhoto() {
        if isConfigured {
            var settings: AVCapturePhotoSettings!
            if let format = photoSettingsFormat {
                settings = AVCapturePhotoSettings(format: format)
            } else {
                settings = AVCapturePhotoSettings(format: [
                    AVVideoCodecKey: AVVideoCodecType.jpeg
                ])
            }
            
            if let dInput = deviceInput {
                if dInput.device.hasFlash {
                    settings.flashMode = flashMode
                } else {
                    settings.flashMode = .off
                }
            }
            stillImageOutput.capturePhoto(with: settings, delegate: self)
        } else {
            print("SC CAMERA ERROR: Please configure your camera view before taking photo. ( Call configure() )")
        }
    }
    
    /**
     Get video thumbnail. Returns first captured frame.
     You can set copy time.
     
     - Parameter sourceURL: Source url for recorded video. Default to FMCamera's recorded video.
     - Parameter copyTime: Time for video thumb image. Default to the first frame
     
     ### Usage Example: ###
     ````
     getVideoThumbnail(url)
     getVideoThumbnail(url, copyTime: CMTime(seconds: 2, preferredTimescale: 60))
     ````
     
     - Returns: UIImage.
     */
    public func getVideoThumbnail(_ sourceURL: URL? = nil, copyTime: CMTime = CMTime(seconds: 0, preferredTimescale: 60), source: VideoSource = .camera) -> UIImage? {
        if let url = sourceURL {
            return makeThumbnail(url, copyTime, source: source)
        } else if let url = recordingURL {
            return makeThumbnail(url, copyTime)
        }
        return nil
    }
    
    /**
    Makes a thumbnail with a given parameters.
    */
    private func makeThumbnail(_ url: URL, _ copyTime: CMTime, source: VideoSource = .camera) -> UIImage? {
        let urlAsset: AVAsset = AVAsset(url: url)
        let assetImages = AVAssetImageGenerator(asset: urlAsset)
        
        do {
            let thumbnailImage = try assetImages.copyCGImage(at: copyTime, actualTime: nil)
            if source == .camera {
                return UIImage(cgImage: thumbnailImage, scale: 1.0, orientation: .right)
            } else {
                return UIImage(cgImage: thumbnailImage, scale: 1.0, orientation: .up)
            }
        } catch {
            print(error)
        }
        return  nil
    }
    
    /**
     Saves recorded video to photo roll
     */
    private func saveVideo() {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.recordingURL!)
            self.isCameraRecording = false
        }) { success, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    if success {
                        fmCaptureVideoDelegate?.recordingFinished(self.recordingURL, nil)
                    } else {
                        fmCaptureVideoDelegate?.recordingFinished(nil, error)
                    }
                }
            }
        }
    }
    
    /**
     Saves capture photo to photo roll
     */
    private func savePhoto(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
    }
    
    /// Transfrom video by orientation
    private func getVideoTransform() -> CGAffineTransform {
        switch UIDevice.current.orientation {
        case .portrait:
            return CGAffineTransform(rotationAngle: .pi / 2)
        case .portraitUpsideDown:
            return CGAffineTransform(rotationAngle: -.pi / 2)
        case .landscapeLeft:
            return .identity
        case .landscapeRight:
            return CGAffineTransform(rotationAngle: -.pi)
        default:
            return CGAffineTransform(rotationAngle: .pi / 2)
        }
    }
    
    public func flipCamera(_ position: AVCaptureDevice.Position) {
        if isConfigured {
            currentPosition = position
            addCaptureDeviceInput(position)
        } else {
            print("SC CAMERA ERROR: Please configure your camera view before flipping camera. ( Call configure() )")
        }
    }
}

// MARK: - Configuration Functions
extension FMCamera {
    /**
     The permissions are granted and the view is ready for configuration.
     Start Configuring camera.
     */
    private func readyForConfiguration() {
        configureSession()
        addSettings()
        addCaptureDeviceInput()
        setPhotoOutput()
        configurePreviewLayer()
        addOutputsToSession()
        session.startRunning()
        isConfigured = true
    }
    
    /**
     Step 1: Configure session. Preset high, recording url default NSTemporaryDirectory and tail
      is file.mp4
     */
    private func configureSession() {
        session.sessionPreset = sPreset
        recordingURL = URL(fileURLWithPath: "\(NSTemporaryDirectory() as String)file.mp4")
        if fileManager.isDeletableFile(atPath: recordingURL!.path) {
            _ = try? fileManager.removeItem(atPath: recordingURL!.path)
        }
        assetWriter = try? AVAssetWriter(outputURL: recordingURL!,
                                         fileType: AVFileType.mp4)
    }
    
    /**
     Step 2: Add video and audio settings to AVAssetWriterInput objects.
     */
    private func addSettings() {
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        
        if videoInput != nil {
            videoInput!.expectsMediaDataInRealTime = true
            videoInput!.transform = getVideoTransform()
            if assetWriter != nil {
                if assetWriter!.canAdd(videoInput!) {
                    assetWriter!.add(videoInput!)
                }
            }
        }
        
        if audioInput != nil {
            audioInput!.expectsMediaDataInRealTime = true
            if assetWriter != nil {
                if assetWriter!.canAdd(audioInput!) {
                    assetWriter!.add(audioInput!)
                }
            }
        }
    }
    
    /**
     Step 3: Add capture device input to session
     */
    private func addCaptureDeviceInput(_ position: AVCaptureDevice.Position = .back) {
        if deviceInput != nil {
            if session.inputs.contains(deviceInput!) {
                session.removeInput(deviceInput!)
            }
        }
        if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices.first {
            do {
                deviceInput = try AVCaptureDeviceInput(device: device)
                if deviceInput != nil {
                    if session.canAddInput(deviceInput!) {
                        session.addInput(deviceInput!)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    /**
     Step 3.1: Set output for photo
     */
    private func setPhotoOutput() {
        stillImageOutput = AVCapturePhotoOutput()
    }
    
    /**
     Step 4: Configure preview layer. This is your visual while recording video.
     */
    private func configurePreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        
        layer.masksToBounds = true
        previewLayer?.frame = bounds
        
        layer.insertSublayer(previewLayer!, at: 0)
    }
    
    /**
     Step 5: Add output objects to session and set connections
     */
    private func addOutputsToSession() {
        session.beginConfiguration()
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        if stillImageOutput != nil {
            if session.canAddOutput(stillImageOutput) {
                session.addOutput(stillImageOutput)
            }
        }
        
        videoConnection = videoOutput.connection(with: .video)
        if videoConnection?.isVideoStabilizationSupported == true {
            videoConnection?.preferredVideoStabilizationMode = .auto
        }
        session.commitConfiguration()
        
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            do {
                let audioIn = try AVCaptureDeviceInput(device: audioDevice)
                
                if session.canAddInput(audioIn) {
                    session.addInput(audioIn)
                }
                
                if session.canAddOutput(audioOutput) {
                    session.addOutput(audioOutput)
                }
                
                audioConnection = audioOutput.connection(with: .audio)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

// MARK: - Cropper
extension FMCamera {
    /**
     Crops image to given bounds
     
     - Parameter image: Image which will be cropped.
     - Parameter width: Width after crop.
     - Parameter height: Height after crop.
     
     - Returns: UIImage
     */
    private func cropToBounds(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
        let cgimage = image.cgImage!
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        let contextSize: CGSize = contextImage.size
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        if contextSize.width > contextSize.height {
            let ratio = height / width
            posX = ((contextSize.width - (contextSize.height * ratio)) / 2)
            posY = 0
            cgwidth = contextSize.height * ratio
            cgheight = contextSize.height
        } else {
            let ratio = width / height
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width * ratio
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        let imageRef: CGImage = cgimage.cropping(to: rect)!
        var orientation: UIImage.Orientation = getOrientation(image)
        if rotateCapturedPhotoUpwards {
            if currentPosition == .back {
                orientation = rotateBackUpwards()
            } else {
                orientation = rotateFrontUpwards()
            }
        }
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: orientation)
        
        return image
    }
    
    /**
     Gives the orientation for front and back camera seperately.
     
     - Parameter image: Image for getting image orientation
     
     - Returns: UIImage.Orientation
     */
    private func getOrientation(_ image: UIImage) -> UIImage.Orientation {
        if currentPosition == .front {
            return .leftMirrored
        }
        return image.imageOrientation
    }
    
    /**
     Works if `rotateCapturedPhotoUpwards` is true. Checks device orientation and returns image orientation photos captured with `back` camera.
     
     - Returns: UIImage.Orientation
     */
    private func rotateBackUpwards() -> UIImage.Orientation {
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .portrait:
            return .right
        case .portraitUpsideDown:
            return .left
        case .landscapeLeft:
            return .up
        case .landscapeRight:
            return .down
        default:
            return .right
        }
    }
    
    /**
     Works if 'rotateCapturedPhotoUpwards' is true. Checks device orientation and returns image orientation photos captured with `front` camera.
     
     - Returns: UIImage.Orientation
     */
    private func rotateFrontUpwards() -> UIImage.Orientation {
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .portrait:
            return .leftMirrored
        case .portraitUpsideDown:
            return .rightMirrored
        case .landscapeLeft:
            return .downMirrored
        case .landscapeRight:
            return .upMirrored
        default:
            return .leftMirrored
        }
    }
}

// MARK: - Image Processor
extension FMCamera {
    private func processImage(_ image: UIImage) {
        startOptimizing(image)
    }
    
    private func startOptimizing(_ image: UIImage) {
        var compressionQuality: CGFloat = 1.0
        while true {
            if let imageData = image.jpegData(compressionQuality: compressionQuality) {
                let imageFileSize: Int = imageData.count
                if compressionQuality > 0.1 {
                    compressionQuality -= 0.05
                    if imageFileSize <= maxPictureFileSize {
                        print("MEDIA FILE SIZE (bytes): \(imageFileSize)")
                        sendReduced(imageData)
                        break
                    }
                } else {
                    print("MEDIA FILE SIZE (bytes): \(imageFileSize)")
                    sendReduced(imageData)
                    break
                }
            } else {
                break
            }
        }
    }
    
    private func sendReduced(_ data: Data) {
        if let reducedImage = UIImage(data: data) {
            if willSavePhotoToPhotos, saveReducedImageToPhotos {
                savePhoto(reducedImage)
            }
            fmCapturePhotoDelegate?.captured(reducedImage, data: data)
        } else {
            print("SC CAMERA ERROR: Cannot reduce the image.")
        }
    }
}

// MARK: - AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate Functions
extension FMCamera: AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !isRecordingSessionStarted {
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if assetWriter != nil {
                assetWriter!.startSession(atSourceTime: presentationTime)
                isRecordingSessionStarted = true
            }
        }
        if let description = CMSampleBufferGetFormatDescription(sampleBuffer) {
            if CMFormatDescriptionGetMediaType(description) == kCMMediaType_Audio {
                if audioInput != nil {
                    if audioInput!.isReadyForMoreMediaData {
                        audioInput!.append(sampleBuffer)
                    }
                }
            } else {
                if videoInput != nil {
                    if videoInput!.isReadyForMoreMediaData {
                        if !videoInput!.append(sampleBuffer) {
                            print("SC CAMERA ERROR: Writing video buffer")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate Functions
extension FMCamera: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        if let capturedImage = UIImage(data: data) {
            let croppedImage = cropToBounds(image: capturedImage, width: frame.width, height: frame.height)
            processImage(croppedImage)
            if willSavePhotoToPhotos {
                if !saveReducedImageToPhotos {
                    savePhoto(croppedImage)
                }
            }
        } else {
            print("SC CAMERA ERROR: Cannot process the image.")
        }
    }
}
