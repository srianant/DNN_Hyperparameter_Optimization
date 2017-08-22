class Unittest < Formula
  desc "C++ Unit Test Framework"
  homepage "http://unittest.red-bean.com/"
  url "http://unittest.red-bean.com/tar/unittest-0.50-62.tar.gz"
  sha256 "9586ef0149b6376da9b5f95a992c7ad1546254381808cddad1f03768974b165f"

  bottle do
    cellar :any_skip_relocation
    sha256 "c997c9ce2d6984607af24a6dc7dc21ddefc0570a15d2fb61192b3a361120a83d" => :sierra
    sha256 "501b61d05de70cfb53116c66daf380cb35a1665eeecf34dfc6b27ab945458f43" => :el_capitan
    sha256 "8e26d281818bdf26ae2876004f5388fee9bd954589f57a6a25c979949e5f5bf1" => :yosemite
    sha256 "2acbb80540c9ff3c17cf4ab95db16657947761813915a94fa4afc0204e4b09b3" => :mavericks
  end

  fails_with :llvm do
    build 2334
  end

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end
end
