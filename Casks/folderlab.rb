cask "folderlab" do
  version "0.6"
  sha256 "8203560bf5ea63421e3574d25cb86eaca639b38b5da7d127e912372467b7f911"

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
