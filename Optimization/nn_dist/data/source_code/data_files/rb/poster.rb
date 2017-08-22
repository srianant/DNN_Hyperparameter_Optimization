class Poster < Formula
  desc "Create large posters out of PostScript pages"
  homepage "https://schrfr.github.io/poster/"
  url "https://github.com/schrfr/poster/archive/1.0.0.tar.gz"
  sha256 "1df49dfd4e50ffd66e0b6e279b454a76329a36280e0dc73b08e5b5dcd5cff451"

  bottle do
    cellar :any_skip_relocation
    sha256 "caa5474e5d7baf13ae6495c01a7530146d55531e41c88a469b0e44ee892c4be4" => :sierra
    sha256 "07702fc6f1d43a3875637f8ff9d3509d6eb913abda301c24c23d824a76a858b6" => :el_capitan
    sha256 "718131fa123a69d0db610d95722d968fbda597da2477abe520146393ff0321c2" => :yosemite
    sha256 "5c109f3122d33b73aecbb3a7e5aaeece5c9e9d3be8aae9c6e39001b6a5feea4e" => :mavericks
  end

  def install
    system "make"
    bin.install "poster"
    man1.install "poster.1"
  end

  test do
    system "#{bin}/poster", test_fixtures("test.ps")
  end
end
