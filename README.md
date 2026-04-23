<h1 align="center">
  <br>
  <img src="./newappicon.png" alt="Boring Notch App Icon" width="150">
  <br>
  Boring Notch
  <br>
</h1>

<p align="center">
  Personal macOS notch experiment and long-term development branch.
</p>

<p align="center">
  <a href="./README.zh-CN.md">中文文档</a>
</p>

## Overview

This repository is now maintained as my personal Boring Notch development project.
It focuses on iterative feature work, UI refinement, and local experimentation on macOS.

> [!NOTE]
> This project continues from the original upstream repository:
> [TheBoredTeam/boring.notch](https://github.com/TheBoredTeam/boring.notch)
>
> The current codebase is maintained as my personal development version, but the original project link is kept here for reference and attribution.

Current direction:

- notch-based media and utility experience for macOS
- faster iteration on personal feature ideas
- independent documentation and changelog for this codebase

## Development

### Requirements

- macOS 14 or later
- Xcode 16 or later

### Run locally

```bash
git clone https://github.com/neversaywanan/boring.notch.git
cd boring.notch
open boringNotch.xcodeproj
```

Then run the app in Xcode with `Cmd + R`.

### Notes

- The app may request Accessibility and other system permissions during development.
- If macOS blocks a locally built app after exporting it, remove quarantine manually:

```bash
xattr -dr com.apple.quarantine /Applications/boringNotch.app
```

## Project Structure

- `boringNotch/`: main SwiftUI app source
- `boringNotch/components/`: notch modules, settings panels, onboarding, shelf, clipboard, webcam, HUD
- `boringNotch/managers/`: shared managers such as clipboard handling
- `boringNotch/models/`: app state, defaults, and shared models
- `boringNotch/helpers/`: helper utilities and icon access
- `boringNotch.xcodeproj/`: Xcode project configuration

## Personal Development Focus

- keep the notch interaction smooth and visually consistent
- make utility panels more practical for daily use
- improve system integration behavior and settings reliability
- continue polishing onboarding, localization, and customization flow

## Changelog

### 2026-04-24

- Added a clipboard tab in the notch UI.
- Added clipboard history with quick recopy and item removal.
- Added clipboard-related settings, including feature toggle, tab visibility, and max history count.
- Refreshed related tab and animation behavior in the notch experience.

### 2026-04-21

- Updated the app icon set and repository branding assets.
- Refined general app behavior across notch views and settings flow.
- Improved XPC helper behavior and accessibility authorization handling.
- Continued polishing onboarding, settings, and localized strings.

## License

This repository keeps the existing project license and attribution files in the codebase.
