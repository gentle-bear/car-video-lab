# CarPlay Video integration experiment — v0.4.0

## What was implemented

- iOS CarPlay scene with `CPTemplateApplicationSceneDelegate` and `CPListTemplate` (iOS 27+).
- Checks `CPSessionConfiguration.supportsVideoPlayback`; shows a disabled row if the car lacks Video in Car.
- Creates `CPPlaybackConfiguration(preferredPresentation: .video, ...)` and starts a **native** `AVPlayer` of Apple's public Bip Bop HLS sample. This is a CarPlay video API experiment, **not YouTube playback**.
- On iPhone: a new CarPlay tab with `AVRoutePickerView` and the same native HLS sample, allowing the user to test AirPlay receiver availability independently of CarPlay scene entitlement.
- Original YouTube browser/Share Extension and local Wi-Fi receiver remain unchanged.

## Why the GitHub IPA is not yet a usable CarPlay app

Apple grants the **`com.apple.developer.carplay-video` entitlement** after an application/review. The file `CarPlayVideo.entitlements.EXAMPLE.plist` is deliberately not configured in `CODE_SIGN_ENTITLEMENTS`, so the unsigned GitHub IPA remains installable using Sideloadly. Adding the key to an unsigned IPA will not grant authorization and can make signing or launch fail. A free Apple ID cannot self-issue restricted CarPlay entitlements.

Even after Apple grants the entitlement and the app is signed with a matching provisioning profile, the in-car icon appears only if the car supports **Video in Car**. The vehicle may turn off video while moving; the system enforces this.

The app uses official YouTube WKWebView embedding; its video is not an AVPlayer HLS source, and copying a YouTube link into the native player will not work. The video demo uses Apple's official HLS **test** stream to establish the in-car playback path before investigating any properly licensed native media integration.

## Steps for authorized developer build

1. Apply for CarPlay Video App entitlement via https://developer.apple.com/carplay/ and wait for approval.
2. In Xcode with the Apple Developer team/profile that has the approved entitlement, copy `CarPlayVideo.entitlements.EXAMPLE.plist` to `CarPlayVideo.entitlements` and configure `CODE_SIGN_ENTITLEMENTS = CarPlayVideo.entitlements` **for the main application target only**. Do NOT enable it on the Share Extension.
3. Build and sign the app with an authorized provisioning profile. Use iOS 27/Xcode 27.
4. Connect to a car that explicitly supports Video in Car and park. If supported, the CarPlay scene shows a playable sample. If unsupported, the app may not appear at all.

## Testing now without Apple entitlement

Build/install the unsigned IPA via existing GitHub Actions → Sideloadly, open the new **CarPlay** tab on iPhone, tap the output picker, and see if your car shows as an AirPlay video destination. Play the Apple HLS sample. This can work only on AirPlay Video in Car receivers and is unrelated to the ordinary CarPlay app icon. Showing a car as audio output alone is not video capability.

### Notes

- The CarPlay scene compilation is verified only after GitHub Actions runs using `xcode-27` runner. Local Linux Swift parse and plist/pbxproj structural checks are not equivalent to iOS SDK typechecking.
- Never use tests while driving.

## References

https://developer.apple.com/carplay/
https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.carplay-video
https://developer.apple.com/videos/play/wwdc2026/212/
https://developer.apple.com/documentation/carplay/cpsessionconfiguration/supportsvideoplayback
https://developer.apple.com/documentation/avkit/avroutepickerview
https://developer.apple.com/streaming/examples/
