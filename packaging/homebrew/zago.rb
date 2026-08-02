class Zago < Formula
  desc "Terminal text editor and plain-text diagramming tool"
  homepage "https://github.com/zonble/zago"
  url "https://github.com/zonble/zago/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_RELEASE_TARBALL_SHA256"
  license "MIT"
  head "https://github.com/zonble/zago.git", branch: "main"

  depends_on xcode: ["16.0", :build]

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
