# FMCamera

<!---[![CI Status](https://img.shields.io/travis/gokhanmandaci/FMCamera.svg?style=flat)](https://travis-ci.org/gokhanmandaci/FMCamera)--->
[![Version](https://img.shields.io/cocoapods/v/FMCamera.svg?style=flat)](https://cocoapods.org/pods/FMCamera)
<!---[![License](https://img.shields.io/cocoapods/l/FMCamera.svg?style=flat)](https://cocoapods.org/pods/FMCamera)--->
[![Platform](https://img.shields.io/cocoapods/p/FMCamera.svg?style=flat)](https://cocoapods.org/pods/FMCamera)

Simple camera view which can take pictures and capture photos. Camera view crops pictures and videos with a given size.
You can capture square videos. There are two Protocols which provide communication between your view controllers and fmcamera view.
You can set maximum picture size and configure audio, video and picture settings if you want.

Built using XCode 11.3.1 (Swift 5)

## Screenshots

<p>
<img src = 'https://github.com/gokhanmandaci/FMCamera/tree/master/Example/FMCamera/Images.xcassets/Screenshots/img1.imageset' width="200" />
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
    vwSquareCamera.configure()
}
```

### Capture

```
// Take Photo
vwSquareCamera.takePhoto()

// Capture Video
if !fmCamera.isCameraRecording {
    vwSquareCamera.startRecording()
} else {
    vwSquareCamera.stopRecording()
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
    func captured(_ image: UIImage) {
        /// Use captured and optimized image
    }
}
```

## Configuration Parameters

Usage examples are added to code documentation. Option+click on parameter to see usage examples.
We have two types of configuration parameters. Before calling `fmcamera.configure()` and before taking a photo.

### Before `configure()`:
```
///Flash mode for capturing.<br/>
var flashMode: AVCaptureDevice.FlashMode = .auto

/// Capture photo format.<br/>
var photoSettingsFormat: [String: Any]?

/// Video settings for recording video.<br/>
var videoSettings: [String: Any] = [:]

/// Audio settings for audio capturing<br/>
var audioSettings: [String: Any] = [:]
```

### Before Taking a Photo:
```
/// Update this for save the photo to your Photos.<br/>
var willSavePhotoToPhotos: Bool = false

/// Update this for save the video to your Photos.<br/>
var willSaveVideoToPhotos: Bool = false

/// Save original or save reduced image to photo roll. Works if `willSaveVideoToPhotos` is true.<br/>
var saveReducedImageToPhotos: Bool = false

/// Set max picture file size in bytes.<br/>
var maxPictureFileSize: Int = 400000

/// Decide if the captured photo rotates upwards. After capturing, photo always oriented upwards if you set this flag to true.<br/>
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
