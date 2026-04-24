#!/usr/bin/env bash
set -euo pipefail

# boring.notch DMG Packaging Script
# This script builds the application and packages it into a DMG.

PROJECT_NAME="boringNotch"
BUILD_DIR="./build"
DERIVED_DATA_DIR="$BUILD_DIR/DerivedData"
APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release/$PROJECT_NAME.app"
DMG_OUTPUT="$BUILD_DIR/$PROJECT_NAME.dmg"
VENV_DIR="$BUILD_DIR/dmg_venv"

echo "Step 1: Building $PROJECT_NAME (Release)..."
xcodebuild -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$PROJECT_NAME" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    build \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO

echo "Step 2: Setting up DMG creation environment..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
pip install -q dmgbuild ds-store mac-alias pyobjc-core pyobjc-framework-cocoa pyobjc-framework-quartz

echo "Step 3: Creating DMG..."
./Configuration/dmg/create_dmg.sh "$APP_PATH" "$DMG_OUTPUT" "$PROJECT_NAME"

echo "------------------------------------------------"
echo "✅ DMG Package created successfully!"
echo "Location: $DMG_OUTPUT"
echo "------------------------------------------------"
