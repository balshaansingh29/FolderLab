cask "folderlab" do
  version "0.6"
  sha256 "bc7b6b2712f90e9d852176574b8c30f28a0534f1465184a770060e699b1286a4"

  url "https://github.com/balshaansingh29/FolderLab/releases/download/v#{version}/FolderLab-v#{version}.dmg"
  name "FolderLab"
  desc "Native macOS studio to customize, stamp, and skin Finder folders in real time"
  homepage "https://github.com/balshaansingh29/FolderLab"

  depends_on macos: ">= :ventura"

  app "FolderLab.app"

  zap trash: [
    "~/Library/Preferences/com.balshaansingh.folderlab.plist",
    "~/Library/Saved Application State/com.balshaansingh.folderlab.savedState",
  ]
end
