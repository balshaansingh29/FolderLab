cask "folderlab" do
  version "0.5"
  sha256 "09b66984e09e32b6566a60b53f7d98d693ddfdddeba3e2e0ae48a3654e2564d4"

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
