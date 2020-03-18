//
//  ViewController.swift
//  FMCamera
//
//  Created by gokhanmandaci on 01/28/2020.
//  Copyright (c) 2020 gokhanmandaci. All rights reserved.
//

import AVFoundation
import UIKit
import FMCamera
import MobileCoreServices

class MainVC: UIViewController {
    // MARK: - Parameters
    private var avPlayer: AVPlayer?
    private var avPlayerLayer: AVPlayerLayer?
    private var position: AVCaptureDevice.Position = .back
    let imagePicker = UIImagePickerController()
    private var originalVideoUrl: URL?
    
    // MARK: - Outlets
    @IBOutlet weak var vwSquareCamera: FMCamera!
    @IBOutlet weak var vwVideoPlayer: UIView!
    @IBOutlet weak var imgCapture: UIImageView!
    @IBOutlet weak var btnFlash: UIButton!
    
    // MARK: - Actions
    @IBAction func btnCaptureAction(_ sender: Any) {
//        if !vwSquareCamera.isCameraRecording {
//            vwVideoPlayer.isHidden = true
//            if avPlayer != nil {
//                avPlayer?.pause()
//                avPlayer = nil
//            }
//            avPlayerLayer?.removeFromSuperlayer()
//            avPlayerLayer = nil
//            vwSquareCamera.startRecording()
//        } else {
//            vwSquareCamera.stopRecording()
//        }
        vwSquareCamera.maxPictureFileSize = 250000
        vwSquareCamera.takePhoto()
    }
    
    @IBAction func btnFlipCameraAction(_ sender: Any) {
        if position == .back {
            vwSquareCamera.flipCamera(.front)
            position = .front
        } else {
            vwSquareCamera.flipCamera(.back)
            position = .back
        }
    }
    
    @IBAction func btnFlashAction(_ sender: Any) {
        switch vwSquareCamera.flashMode {
        case .off, .auto:
            vwSquareCamera.flashMode = .on
            btnFlash.setImage(UIImage(named: "cameraFlashOpen"), for: .normal)
        case .on:
            vwSquareCamera.flashMode = .off
            btnFlash.setImage(UIImage(named: "cameraFlash"), for: .normal)
        @unknown default:
            break
        }
    }
    
    @IBAction func btnLibraryAction(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.mediaTypes = [kUTTypeImage, kUTTypeMovie, kUTTypeMPEG4] as [String]
            imagePicker.allowsEditing = true
            imagePicker.videoMaximumDuration = 30.0
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fmCaptureVideoDelegate = self
        fmCapturePhotoDelegate = self
        imagePicker.delegate = self
        
        vwSquareCamera.sPreset = .low
        vwSquareCamera.setForPhotoCapturingOnly = false
        
        vwSquareCamera.configure()
    }
}

// MARK: - Class Functions
extension MainVC {
    private func makeReady(_ url: URL) {
        vwVideoPlayer.isHidden = false
        avPlayer = AVPlayer(url: url)
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer?.videoGravity = .resizeAspect
        if avPlayerLayer != nil {
            vwVideoPlayer.layer.addSublayer(avPlayerLayer!)
            avPlayerLayer?.frame = vwVideoPlayer.bounds
            
            if avPlayer != nil {
                avPlayer!.play()
            }
        }
    }
}

extension MainVC: FMCaptureVideoProtocol {
    func recordingStarted(_ error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    func recordingFinished(_ videoUrl: URL?, _ error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        } else {
            if let url = videoUrl {
                do {
                    let resources = try url.resourceValues(forKeys: [.fileSizeKey])
                    if let fileSize = resources.fileSize {
                        print("MEDIA FILE SIZE (bytes): \(fileSize)")
                    }
                } catch {
                    print(error.localizedDescription)
                }
                
                imgCapture.image = vwSquareCamera.getVideoThumbnail()
                makeReady(url)
            }
        }
    }
}

extension MainVC: FMCapturePhotoProtocol {
    func captured(_ image: UIImage, data: Data) {
        imgCapture.image = image
    }
}

extension MainVC: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let url = info[.mediaURL] as? URL {
            imgCapture.image = vwSquareCamera.getVideoThumbnail(url, copyTime: .zero, source: .library)
            makeReady(url)
        }
    }
}
