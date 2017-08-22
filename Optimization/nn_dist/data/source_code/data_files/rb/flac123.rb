class Flac123 < Formula
  desc "Command-line program for playing FLAC audio files"
  homepage "http://flac-tools.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/flac-tools/flac123/flac123-0.0.12-release.tar.gz"
  sha256 "1976efd54a918eadd3cb10b34c77cee009e21ae56274148afa01edf32654e47d"

  bottle do
    cellar :any
    sha256 "f62d8e1f08e8cd5d952f02a35ebcdc921a1295035a2b66e843d80aacb8d9843e" => :sierra
    sha256 "669b5ff8922496fe8abe8b020ef92118847539095a0d281f73b85e965be1f708" => :el_capitan
    sha256 "3bc22230d8e4ed12c794a0784173e576d17cfae249bb87d4540680d3f0483957" => :yosemite
    sha256 "afeeeebde3988d1028452606aaf22ba18379cf59743c4ac9abefac2f86234dd1" => :mavericks
    sha256 "4f76ae1d865f10de27f44c57242178c06ffb33017ac3646a4dd2115fc2882c61" => :mountain_lion
  end

  depends_on "automake" => :build
  depends_on "autoconf" => :build

  depends_on "flac"
  depends_on "libao"
  depends_on "libogg"
  depends_on "popt"

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install", "CC=#{ENV.cc}",
                   # specify aclocal and automake without version suffixes
                   "ACLOCAL=${SHELL} #{buildpath}/missing --run aclocal",
                   "AUTOMAKE=${SHELL} #{buildpath}/missing --run automake"
  end

  test do
    system "#{bin}/flac123"
  end
end
