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

class MainVC: UIViewController {
    // MARK: - Parameters
    private var avPlayer: AVPlayer?
    private var avPlayerLayer: AVPlayerLayer?
    private var position: AVCaptureDevice.Position = .back
    
    // MARK: - Outlets
    @IBOutlet weak var vwSquareCamera: FMCamera!
    @IBOutlet weak var vwVideoPlayer: UIView!
    @IBOutlet weak var imgCapture: UIImageView!
    
    // MARK: - Actions
    @IBAction func btnCaptureAction(_ sender: Any) {
        if !vwSquareCamera.isCameraRecording {
            vwVideoPlayer.isHidden = true
            if avPlayer != nil {
                avPlayer?.pause()
                avPlayer = nil
            }
            avPlayerLayer?.removeFromSuperlayer()
            avPlayerLayer = nil
            vwSquareCamera.startRecording()
        } else {
            vwSquareCamera.stopRecording()
        }
//        vwSquareCamera.maxPictureFileSize = 250000
//        vwSquareCamera.takePhoto()
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
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fmCaptureVideoDelegate = self
        fmCapturePhotoDelegate = self
        
        vwSquareCamera.configure()
    }
}

// MARK: - Class Functions
extension MainVC {}

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
    }
}

extension MainVC: FMCapturePhotoProtocol {
    func captured(_ image: UIImage) {
        imgCapture.image = image
    }
}
