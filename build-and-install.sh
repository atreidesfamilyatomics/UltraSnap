#!/bin/bash
set -e  # Exit on error

# UltraSnap Build and Install Script
# Builds, installs, and launches UltraSnap

echo "🔨 Building UltraSnap..."
echo ""

# Clean previous build
rm -rf ./build

# Build the app
xcodebuild \
    -scheme UltraSnap \
    -configuration Release \
    -derivedDataPath ./build \
    clean build \
    | grep -E '(Build Succeeded|BUILD SUCCEEDED|error:|warning:.*:)' || true

# Check if build succeeded
if [ ! -d "./build/Build/Products/Release/UltraSnap.app" ]; then
    echo "❌ Build failed. UltraSnap.app not found."
    exit 1
fi

echo ""
echo "✅ Build succeeded!"
echo ""
echo "📦 Installing to ~/Applications/..."

# Kill any running instance
killall UltraSnap 2>/dev/null && echo "   Stopped running instance" || true

# Remove old version
rm -rf ~/Applications/UltraSnap.app

# Copy new version
cp -r ./build/Build/Products/Release/UltraSnap.app ~/Applications/

echo "   Installed to ~/Applications/UltraSnap.app"
echo ""
echo "🚀 Launching UltraSnap..."

# Launch the app
open ~/Applications/UltraSnap.app

echo ""
echo "✨ Done! UltraSnap is now running with the latest changes."
echo ""
