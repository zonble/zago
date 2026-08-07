class Zago < Formula
  desc "Terminal text editor and plain-text diagramming tool"
  homepage "https://github.com/zonble/zago"
  url "https://github.com/zonble/zago/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "0d6ff240024b6ca1355c1f0e2891f65cf38b49d94e4d539181872b5e62d05b70"
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
