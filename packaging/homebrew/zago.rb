class Zago < Formula
  desc "Terminal text editor and plain-text diagramming tool"
  homepage "https://github.com/zonble/zago"
  url "https://github.com/zonble/zago/archive/refs/tags/v1.4.6.tar.gz"
  sha256 "bfe82e8f5c1e8f0be62c3b7cf7d48b1d9d5b23e19062c6ff8d05f62cb34668af"
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
