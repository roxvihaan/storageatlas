# Storage Atlas

A native macOS SwiftUI app that turns a folder into an interactive 3D storage map.

## Features

- True 3D SceneKit treemap embedded in SwiftUI
- Block footprint represents relative storage usage
- Click to focus and inspect
- Double-click to reveal the file or folder in Finder
- Click-drag to rotate the map and scroll to zoom
- Glassmorphism and neumorphic themes
- Animated, hands-on onboarding inspired by Thump’s pacing and interaction style
- Local-only scanning with cancellable background work

## Run

Open `Package.swift` in Xcode 16 or later and run the `StorageAtlas` scheme, or use:

```sh
swift run StorageAtlas
```

The first launch opens onboarding. Choose a folder when prompted; the app skips
hidden files, package contents, and symbolic links while calculating sizes.
