#!/usr/bin/env python3
"""
FolderLab Custom DMG Packager with Rich Personality
Creates a beautifully branded, high-contrast macOS installer DMG with:
- Custom 2x Retina background artwork with branded glow, typography, and drag-and-drop guide
- Perfectly positioned icon placements (FolderLab.app -> /Applications)
- Custom Finder window dimensions (660x440)
- Custom volume icon
"""

import os
import sys
import shutil
import subprocess
import tempfile
from pathlib import Path

def run_cmd(cmd, check=True):
    print(f"==> {cmd}")
    res = subprocess.run(cmd, shell=True, text=True, capture_output=True)
    if check and res.returncode != 0:
        print(f"Error: Command failed with exit code {res.returncode}")
        print("STDOUT:", res.stdout)
        print("STDERR:", res.stderr)
        sys.exit(res.returncode)
    return res

def build_custom_dmg(app_bundle, output_dmg, volume_name="FolderLab"):
    print(f"\n==========================================")
    print(f"📦 Packaging Custom Personality DMG: {output_dmg}")
    print(f"==========================================")

    if os.path.exists(output_dmg):
        os.remove(output_dmg)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    generate_bg_script = os.path.join(script_dir, "generate_bg.swift")

    with tempfile.TemporaryDirectory() as staging_dir:
        rw_dmg = os.path.join(staging_dir, "temp.dmg")
        bg_png = os.path.join(staging_dir, "background.png")
        
        # 1. Generate Custom Retina Background Artwork
        run_cmd(f"swift '{generate_bg_script}' '{bg_png}'")

        # 2. Create temporary read/write disk image (approx 120MB)
        run_cmd(f"hdiutil create -size 120m -fs HFS+ -volname '{volume_name}' -ov '{rw_dmg}'")

        # 3. Attach disk image
        attach_output = run_cmd(f"hdiutil attach -nobrowse -noverify -noautoopen '{rw_dmg}'").stdout
        mount_point = None
        for line in attach_output.splitlines():
            if f"/Volumes/{volume_name}" in line:
                mount_point = line.split()[-1]
                break

        if not mount_point:
            mount_point = f"/Volumes/{volume_name}"

        print(f"Mounted disk image at: {mount_point}")

        try:
            # 4. Copy Application bundle
            dest_app = os.path.join(mount_point, os.path.basename(app_bundle))
            print(f"Copying {app_bundle} to {dest_app}...")
            run_cmd(f"cp -R '{app_bundle}' '{dest_app}'")

            # 5. Create Applications symlink
            apps_link = os.path.join(mount_point, "Applications")
            run_cmd(f"ln -s /Applications '{apps_link}'")

            # 6. Copy Background Image to hidden directory
            hidden_bg_dir = os.path.join(mount_point, ".background")
            os.makedirs(hidden_bg_dir, exist_ok=True)
            shutil.copyfile(bg_png, os.path.join(hidden_bg_dir, "background.png"))

            # 7. Set custom volume icon if available
            app_icon_icns = os.path.join(app_bundle, "Contents", "Resources", "AppIcon.icns")
            if os.path.exists(app_icon_icns):
                vol_icon = os.path.join(mount_point, ".VolumeIcon.icns")
                shutil.copyfile(app_icon_icns, vol_icon)
                run_cmd(f"SetFile -a C '{mount_point}' 2>/dev/null || true")

            # 8. Configure Finder Window & Icon Positions via AppleScript
            applescript = f'''
tell application "Finder"
    tell disk "{volume_name}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {{160, 120, 820, 560}}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 110
        try
            set background picture of theViewOptions to file ".background:background.png"
        end try
        set position of item "{os.path.basename(app_bundle)}" of container window to {{180, 220}}
        set position of item "Applications" of container window to {{480, 220}}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
'''
            print("Applying AppleScript styling to Finder window...")
            res = subprocess.run(["osascript", "-e", applescript], text=True, capture_output=True)
            if res.returncode != 0:
                print(f"Notice: osascript window layout returned code {res.returncode}: {res.stderr.strip()}")

            run_cmd("sync")
            run_cmd("sleep 1")

        finally:
            print(f"Detaching {mount_point}...")
            run_cmd(f"hdiutil detach '{mount_point}' -force -quiet || true")

        # 9. Convert to compressed, read-only final DMG
        print(f"Compressing into final DMG: {output_dmg}...")
        run_cmd(f"hdiutil convert '{rw_dmg}' -format UDZO -imagekey zlib-level=9 -o '{output_dmg}' -ov")
        print(f"✅ Successfully created bespoke installer: {output_dmg}")

if __name__ == "__main__":
    app_path = "FolderLab.app"
    out_dmg = "FolderLab-v0.6.dmg"
    if len(sys.argv) > 1:
        app_path = sys.argv[1]
    if len(sys.argv) > 2:
        out_dmg = sys.argv[2]

    build_custom_dmg(app_path, out_dmg)
