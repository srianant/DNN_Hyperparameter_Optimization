class Hesiod < Formula
  desc "Library for the simple string lookup service built on top of DNS"
  homepage "https://github.com/achernya/hesiod"
  url "https://github.com/achernya/hesiod/archive/hesiod-3.2.1.tar.gz"
  sha256 "813ccb091ad15d516a323bb8c7693597eec2ef616f36b73a8db78ff0b856ad63"

  bottle do
    sha256 "6b12ee90c4f50d02503a44b68b6b4c95097b299aefc7fbfa68872925a5ca48d5" => :sierra
    sha256 "1fd5997be54205d6b7825e156eba9ffae51bdd9e651fd3bb269f9f696d95071b" => :el_capitan
    sha256 "d8db2bc394437272bfcf0225f435075f71269ee9e41b6e453514463e57501348" => :yosemite
  end

  depends_on "automake" => :build
  depends_on "autoconf" => :build
  depends_on "libtool" => :build
  depends_on "libidn"

  def install
    system "autoreconf", "-fvi"
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system "#{bin}/hesinfo", "sipbtest", "passwd"
    system "#{bin}/hesinfo", "sipbtest", "filsys"
  end
end
