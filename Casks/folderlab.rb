cask "folderlab" do
  version "0.7"
  sha256 "a71ab1a10f056a2f2a6ade1002675795f2b73f4b20fc9ae368c386e83c9c656d"

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
