# UltraSnap Build Instructions

## Quick Build & Install

Run the automated build script:

```bash
cd ~/Projects/learning-lab/UltraSnap
./build-and-install.sh
```

This script will:
1. Clean previous builds
2. Build UltraSnap in Release configuration
3. Kill any running instance
4. Install to ~/Applications/
5. Launch the updated app

## Manual Build

If you need to build manually:

```bash
cd ~/Projects/learning-lab/UltraSnap
xcodebuild -scheme UltraSnap -configuration Release -derivedDataPath ./build clean build
cp -r ./build/Build/Products/Release/UltraSnap.app ~/Applications/
killall UltraSnap 2>/dev/null || true
open ~/Applications/UltraSnap.app
```

## Testing

Run the test suite:

```bash
xcodebuild test -scheme UltraSnap -destination 'platform=macOS'
```

## Current Version

- **80 tests** passing
- **19 zone presets** (11 original + 8 asymmetric)
- **Border snap** support (all edges + corners)
