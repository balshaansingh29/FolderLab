#!/bin/bash
set -e

echo "📁 Installing FolderLab for macOS..."

LATEST_RELEASE=$(curl -s https://api.github.com/repos/balshaansingh29/FolderLab/releases/latest)
DMG_URL=$(echo "$LATEST_RELEASE" | grep "browser_download_url.*FolderLab-.*\.dmg" | head -n 1 | cut -d '"' -f 4)

if [ -z "$DMG_URL" ]; then
    DMG_URL="https://github.com/balshaansingh29/FolderLab/releases/download/v0.6/FolderLab-v0.6.dmg"
fi

TMP_DIR=$(mktemp -d)
DMG_PATH="$TMP_DIR/FolderLab.dmg"
MOUNT_DIR="$TMP_DIR/mount"

echo "⬇️ Downloading latest release..."
curl -L --progress-bar "$DMG_URL" -o "$DMG_PATH"

echo "💿 Mounting installer..."
mkdir -p "$MOUNT_DIR"
hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_DIR" -nobrowse -quiet

echo "📁 Installing FolderLab to /Applications..."
rm -rf /Applications/FolderLab.app
cp -R "$MOUNT_DIR/FolderLab.app" /Applications/

echo "🧹 Unmounting installer..."
hdiutil detach "$MOUNT_DIR" -quiet || true
rm -rf "$TMP_DIR"

echo "✨ Clearing macOS Gatekeeper quarantine..."
xattr -cr /Applications/FolderLab.app

echo ""
echo "🎉 FolderLab successfully installed to /Applications!"
echo "🚀 You can now launch FolderLab from Spotlight (⌘Space) or your Applications folder with zero security warnings."
