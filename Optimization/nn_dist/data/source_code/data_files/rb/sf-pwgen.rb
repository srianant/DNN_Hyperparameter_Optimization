class SfPwgen < Formula
  desc "Generate passwords using SecurityFoundation framework"
  homepage "https://bitbucket.org/anders/sf-pwgen/"
  url "https://github.com/anders/pwgen/archive/v1.4.tar.gz"
  sha256 "1f4c7f514426305be2e1b893a586310d579e500e033938800afd2c98fedb84d9"

  head "https://github.com/anders/pwgen.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "ff59281df8d8c0e341233cdffafe67d0dc78101afb90a8597b0a83605ef578a3" => :sierra
    sha256 "2c0e0523569aa25fe254012d3b86ae0bdc587c0f17c4a62d8d12917b7fa44fbf" => :el_capitan
    sha256 "2c6d133b3c9b079dc8c81407107a3c1fb4d5cb3d654afa7acef6f23b9f9df9a6" => :yosemite
  end

  depends_on :macos => :mountain_lion

  def install
    system "make"
    bin.install "sf-pwgen"
  end

  test do
    assert_equal 20, shell_output("#{bin}/sf-pwgen -a memorable -c 1 -l 20").chomp.length
  end
end
