cask "folderlab" do
  version "0.4"
  sha256 "181bf542b614d7a523555dec444d86adede68a364fa316fcb76f08d6d60a9446"

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
