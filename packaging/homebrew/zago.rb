class Zago < Formula
  desc "Terminal text editor and plain-text diagramming tool"
  homepage "https://github.com/zonble/zago"
  url "https://github.com/zonble/zago/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "cd87ef76603d988c2e494b4775bafbdb8d4cc4a6931ab84380cc5faa62eb0557"
  license "MIT"
  head "https://github.com/zonble/zago.git", branch: "main"

  on_macos do
    depends_on xcode: ["16.0", :build]
  end

  on_linux do
    depends_on "swift" => :build
  end 

  def install
    system "swift", "build",
      "--configuration", "release",
      "--disable-sandbox",
      "--product", "zago"

    bin.install ".build/release/zago"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/zago --version")
  end
end
