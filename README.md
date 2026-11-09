# Car Video Lab v0.4.1 — CarPlay Video experiment

A full iOS Xcode project with YouTube iframe browsing/player, iOS Share Extension, local Wi-Fi receiver for car browsers, and an **experimental CarPlay Video / AirPlay test**.

**Important:** With the unsigned GitHub Actions IPA + Sideloadly, you can use the iPhone player, Share Extension, Wi-Fi car-browser receiver, and AirPlay receiver picker. You **cannot** get the restricted CarPlay Video entitlement by sideloading. CarPlay Video requires approval from Apple and a car with Video in Car capability, and the included CarPlay native HLS demo is **not YouTube**.

See [CARPLAY-SETUP.md](CARPLAY-SETUP.md) for the full integration and activation instructions and [WINDOWS-INSTALL.md](WINDOWS-INSTALL.md) for GitHub→Sideloadly.

GitHub Actions uses Xcode 27. To update your existing repository from Windows, see below.

```powershell
cd D:\Downloads
git clone https://github.com/gentle-bear/car-video-lab.git car-video-lab-update
# Copy the unzipped project contents to car-video-lab-update (including .github)
cd car-video-lab-update
git add -A
git commit -m "Car Video Lab v0.4 - CarPlay experiment"
git push
```

You can also update an existing local clone, copying files into its root. Don't run `git init` on the unpacked archive when you already have a repository.

## Complete ZIP for Windows

The archive contains the **entire project**, including `.github/workflows/build-ipa.yml`.
Archive entries are at project root (no extra wrapper folder). Extract directly into a folder of your choice.
To update the existing GitHub repository without losing commit history, clone it and unpack this archive INTO the cloned folder, not above it.

Use PowerShell commands in `WINDOWS-CLEAN-UPLOAD.md`.

**Limitations:** This is an experimental CarPlay scene; a sideloaded IPA still does not have Apple’s CarPlay Video entitlement. YouTube plays on iPhone; native CarPlay HLS demo requires Apple permission and a compatible car. The CarPlay code has not been compiled with Xcode in this environment; check GitHub Actions for build errors.


## v0.4.2 build fix
Removed AVRoutePickerView.player assignment (unavailable on iOS 27.1). AirPlayPicker uses system route selection; AVPlayer playback remains in NativeHLSPlayback. The full Xcode build still requires GitHub Actions verification.
