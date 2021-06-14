# FMCamera

<!---[![CI Status](https://img.shields.io/travis/gokhanmandaci/FMCamera.svg?style=flat)](https://travis-ci.org/gokhanmandaci/FMCamera)--->
[![Version](https://img.shields.io/cocoapods/v/FMCamera.svg?style=flat)](https://cocoapods.org/pods/FMCamera)
<!---[![License](https://img.shields.io/cocoapods/l/FMCamera.svg?style=flat)](https://cocoapods.org/pods/FMCamera)--->
[![Platform](https://img.shields.io/cocoapods/p/FMCamera.svg?style=flat)](https://cocoapods.org/pods/FMCamera)

Simple camera view which can take pictures and capture photos. Camera view crops pictures and videos with a given size.
You can capture square videos. There are two Protocols which provide communication between your view controllers and fmcamera view.
You can set maximum picture size and configure audio, video and picture settings if you want. Also you can get a thumbnail image for your video.

Built using XCode 11.3.1 (Swift 5)

## Screenshots

<p float="left"; padding="20px">
    <img src='https://raw.githubusercontent.com/gokhanmandaci/FMCamera/master/Example/FMCamera/Images.xcassets/Screenshots/img1.imageset/img1.png' width="33%" />
    <img src='https://raw.githubusercontent.com/gokhanmandaci/FMCamera/master/Example/FMCamera/Images.xcassets/Screenshots/img2.imageset/img2.png' width="33%" />
    <img src='https://raw.githubusercontent.com/gokhanmandaci/FMCamera/master/Example/FMCamera/Images.xcassets/Screenshots/img3.imageset/img3.png' width="33%" />
</p>

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

### Manual

1. Clone this repo
2. Navigate to project folder
3. Copy `Source` to your project


### Using Cocoapods

FMCamera is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'FMCamera'
```

## Permissions

Add the keys below to your `info.plist` file. Don't forget to change the description texts.

```
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library usage description</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone usage description</string>
<key>NSCameraUsageDescription</key>
<string>Camera usage description</string>
```

## Usage
1. `import FMCamera` in which class you want to use.
2. You can create a camera view on your storyboard or you can create it with code. Use Class named `FMCamera`
3. Update configuration parameters if necessary.
4. Configure fmcamera with `configure()` function
5. Use picture, video or both delegates
6. Write extensions for picture and/or video protocols.
7. Protocol functions will return images or video urls, use them.

## Code

In your view controller after creating a FMCamera object, for example called `fmCamera`

### Configuration

```
override func viewDidLoad() {
    super.viewDidLoad()
        
    fmCapturePhotoDelegate = self
    fmCaptureVideoDelegate = self
        
    // You can update configuration parameters here
    // or you can just use default ones.
    fmCamera.configure()
}
```

### Capture

```
// Take Photo
fmCamera.takePhoto()

// Capture Video
if !fmCamera.isCameraRecording {
    fmCamera.startRecording()
} else {
    fmCamera.stopRecording()
}
```

### Protocols

```
extension ViewController: FMCaptureVideoProtocol {
    func recordingStarted(_ error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    func recordingFinished(_ videoUrl: URL?, _ error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        } else {
            /// Use recorded video url
        }
    }
}


extension ViewController: FMCapturePhotoProtocol {
    func captured(_ image: UIImage, data: Data) {
        /// Use captured and optimized image
    }
}
```

## Configuration Parameters

Usage examples are added to code documentation. Option+click on parameter to see usage examples.
We have two types of configuration parameters. Before calling `fmcamera.configure()` and before taking a photo.

### Before `configure()`:
```
/// Set session preset with<br/>
var sPreset: AVCaptureSession.Preset = .medium

/// Set this parameter to TRUE if you want to use 
/// FMCamera just for photo capturing.<br/>
var setForPhotoCapturingOnly: Bool = false

///Flash mode for capturing.<br/>
var flashMode: AVCaptureDevice.FlashMode = .auto

/// Capture photo format.<br/>
var photoSettingsFormat: [String: Any]?

/// Set default camera, front or back.<br/>
var captureDevicePosition: AVCaptureDevice.Position = .back

/// Video settings for recording video.<br/>
var videoSettings: [String: Any] = [:]

/// Audio settings for audio capturing<br/>
var audioSettings: [String: Any] = [:]
```

### Before Taking a Photo:
```
/// Update this for save the photo to your Photos.
var willSavePhotoToPhotos: Bool = false

/// Update this for save the video to your Photos.
var willSaveVideoToPhotos: Bool = false

/// Save original or save reduced image to photo roll. 
///Works if `willSaveVideoToPhotos` is true.
var saveReducedImageToPhotos: Bool = false

/// Set max picture file size in bytes.
var maxPictureFileSize: Int = 400000

/// Set this to false if you want to optimize images yourself.
var optimizeImage: Bool = true

/// Decide if the captured photo rotates upwards. 
///After capturing, photo always oriented upwards if you set this flag to true.
var rotateCapturedPhotoUpwards: Bool = false
```

## Resources Used: <br/>
https://stackoverflow.com/a/44917862 <br/>
https://www.appcoda.com/avfoundation-swift-guide/ <br/>
https://stackoverflow.com/a/32041649

## Author

gokhanmandaci, gokhanmandaci@gmail.com


## License

FMCamera is available under the MIT license. See the LICENSE file for more info.
