class Lib3ds < Formula
  desc "Library for managing 3D-Studio Release 3 and 4 '.3DS' files"
  homepage "https://code.google.com/archive/p/lib3ds/"
  url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/lib3ds/lib3ds-1.3.0.zip"
  sha256 "f5b00c302955a67fa5fb1f2d3f2583767cdc61fdbc6fd843c0c7c9d95c5629e3"

  bottle do
    cellar :any
    rebuild 1
    sha256 "4338a4f81ccc33ad78b30f051085594606b74fe5f7773e197a36f08e0b8967ba" => :sierra
    sha256 "e5810afd47dd88fb769e6ef62ef558b4ee4e643d4f5ae3fddb019257642b3375" => :el_capitan
    sha256 "33f5b51953a8d4a583c7d5d6a7796ffaaccf8bf6a303fac300bfdb76dcd0ad60" => :yosemite
    sha256 "3faa2167b32ab4fba667c2fc1d1131411fc3765c7e32a220b16aa62ee433d930" => :mavericks
    sha256 "d508b861035a3e6a91e90f3bcd89fd43c50ed6d07f365a75061f83d4af863379" => :mountain_lion
  end

  def install
    system "./configure", "--prefix=#{prefix}", "--disable-dependency-tracking"
    system "make", "install"
  end

  test do
    # create a raw emtpy 3ds file.
    (testpath/"test.3ds").write("\x4d\x4d\x06\x00\x00\x00")
    system bin/"3dsdump", "test.3ds"
  end
end
