<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="FolderLab App Icon" />
</p>

<h1 align="center">FolderLab</h1>

<p align="center">
  <b>The modern, native macOS studio to customize, stamp, and skin Finder folders in real time.</b><br>
  Built with SwiftUI & AppKit • Apple Liquid Glass • SF Symbols • Open Source
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Release-v0.5-brightgreen.svg" alt="Release v0.5">
  <img src="https://img.shields.io/badge/macOS-13%2B%20Ventura%20%7C%20Sonoma%20%7C%20Sequoia-blue.svg?logo=apple" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange.svg?logo=swift" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/UI-SwiftUI%20%26%20AppKit-purple.svg" alt="SwiftUI & AppKit">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
</p>

<p align="center">
  <img src="docs/screenshot.png?v=2" width="880" alt="FolderLab Studio Screenshot" />
</p>

---

## Overview

**FolderLab** gives macOS Finder folders a personal touch. Style folder colors, apply tactile surface textures, engrave icons or custom logos, attach vintage nameplates, and format folder text using stylish Unicode fonts—all with instant live previews and drag-and-drop simplicity.

---

## Key Features

### 🎨 Colors, Gradients & Textures
- **Custom Palettes & Multi-Stop Gradients**: Design 3-stop mesh gradients or sync directly with native macOS Finder tag colors.
- **Tactile Surface Textures**: Apply sharp finishes including Carbon Fiber, Brushed Metal, Tactile Leather, Dot Matrix, and Diagonal Ribs.
- **Liquid Glass Aesthetic**: Add realistic glass translucency, frosted diffusion sheen, and specular rim chamfers.
- **Surprise Me Generator**: 1-click procedural generator creating curated palettes, textures, and iconography across multiple aesthetic archetypes.

### 🏷️ Nameplates & Typography
- **Flap Nameplates & Banners**: Stamp realistic text banners across folder flaps. Choose from 7 distinct styles: *Dymo Embossed Tape, Modern Glass Capsule, Engraved Brass Plaque, Cyber Neon Ribbon, Paper Masking Tape, Minimal Clean Tag,* and *Debossed Text*.
- **Unicode Folder Renamer**: Format directory names directly on disk with 14 expressive Unicode styles (*Bold Sans, Script, Monospace, Double-Struck Blackboard, Fraktur Gothic, Small Caps*, and more).
- **3D Depth Stamping**: Customize typography depth with Embossed or Engraved 3D bevels using SF Pro Rounded, SF Mono, or New York Serif.

### ⚡ Symbols & Custom Stamps
- **140+ Apple SF Symbols**: Search and stamp curated vector symbols with custom scaling, gradients, and drop shadows.
- **Custom Image Importer**: Drag and drop any PNG, JPG, or SVG to stamp logos, team badges, or stickers.
- **Corner Status Badges**: Mark folders with discrete indicators for quick recognition (*Lock, Star, Checkmark, Warning, Cloud, Tag*).

### 🚀 Finder Workflow & Export
- **Drag-and-Drop Live Skinning**: Drop any folder from Finder onto the canvas to skin it instantly using official macOS APIs.
- **Batch Processing**: Style multiple folders simultaneously or theme entire subfolder trees in one click.
- **Lossless Export**: Save designs as production-ready Apple `.icns` icon sets or high-resolution 1024×1024 PNGs.
- **Portable Presets (`.folderlab`)**: Save, export, and share theme presets.
- **Full History**: 30-level Undo/Redo (`⌘Z` / `⇧⌘Z`) and recently applied style shelf.

---

## How It Works

```
 1. Customize            2. Drag & Drop           3. Done!
┌──────────────┐        ┌──────────────┐        ┌──────────────┐
│ Pick colors, │   ──>  │ Drop folder  │   ──>  │ Finder icon  │
│ icons & tape │        │ onto canvas  │        │ updates live │
└──────────────┘        └──────────────┘        └──────────────┘
```

1. **Customize**: Choose colors, textures, symbols, or nameplate banners in the inspector.
2. **Drop**: Drag any folder from Finder onto FolderLab (or click **Apply to Folder…**).
3. **Done**: Finder updates the folder icon immediately—no restart or terminal commands required.

---

## Curated Themes

| Theme | Palette | Aesthetic Vibe |
| :--- | :--- | :--- |
| **Classic Blue** | `#6CD0FF` → `#2F9DF4` | Authentic native macOS Finder feel |
| **Dark Graphite** | `#3A3D45` → `#181A1F` | Sleek Space Black & dark mode studio |
| **Titanium Slate** | `#5E6573` → `#3A3F49` | Industrial brushed metal & minimal slate |
| **Liquid Glass** | `Translucent Glass` | Frosted crystal with specular edge rim |
| **Neon Cyber** | `#FF007F` → `#7928CA` | Electric synthwave glow & vivid magenta |
| **Warm Sunset** | `#FF7E5F` → `#FEB47B` | Golden hour glow & warm tangerine |
| **Mint Emerald** | `#11998E` → `#38EF7D` | Vibrant organic foliage & emerald glass |
| **Crimson Ruby** | `#ED213A` → `#93291E` | Deep executive scarlet & velvet ruby |
| **Champagne Gold** | `#F6D365` → `#FDA085` | Luxury metallic shimmer & warm champagne |

---

## Installation

### Method 1: One-Line Quick Install (Recommended)

Downloads the latest release, installs to `/Applications`, removes quarantine flags, and launches FolderLab:

```bash
curl -fsSL https://raw.githubusercontent.com/balshaansingh29/FolderLab/main/install.sh | bash
```

### Method 2: Homebrew

```bash
brew install --cask https://raw.githubusercontent.com/balshaansingh29/FolderLab/main/Casks/folderlab.rb
```

### Method 3: Direct Download

Download pre-compiled binaries from the latest release:

- **[FolderLab-v0.5.dmg](https://github.com/balshaansingh29/FolderLab/releases/download/v0.5/FolderLab-v0.5.dmg)** — Drag-and-drop installer
- **[FolderLab-v0.5.zip](https://github.com/balshaansingh29/FolderLab/releases/download/v0.5/FolderLab-v0.5.zip)** — Standalone application archive

---

> [!NOTE]
> ### Opening for the First Time on macOS
> Because FolderLab is a free, open-source community app not signed through Apple's commercial Developer Program, macOS Gatekeeper may prompt: *"Apple could not verify FolderLab.app"*.
>
> **To launch the app:**
> - **Option A**: Right-click (or Control-click) `FolderLab.app` in `/Applications` → click **Open** → click **Open** (macOS remembers this choice permanently).
> - **Option B**: Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**.
> - **Option C**: Run in Terminal: `xattr -cr /Applications/FolderLab.app`

---

## Building from Source

### Requirements
- **macOS 13.0+** (Ventura, Sonoma, or Sequoia)
- **Xcode 15+** or **Swift 5.9+** toolchain

### Build & Run

```bash
# Clone the repository
git clone https://github.com/balshaansingh29/FolderLab.git
cd FolderLab

# Build and run
swift run
```

You can also open `Package.swift` directly in Xcode and press `⌘R`.

---

## Privacy & Security

- **100% Offline**: FolderLab requires no network permissions, contains no analytics, telemetry, or tracking.
- **Official macOS APIs**: Folder customizations are applied locally using Apple's standard `NSWorkspace.shared.setIcon(_:forFile:)` API.
- **No Background Daemons**: No helper tools, system extensions, or elevated privileges are required.

---

## License

Distributed under the [MIT License](LICENSE).
