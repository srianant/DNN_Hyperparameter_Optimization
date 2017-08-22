class Openhmd < Formula
  desc "Free and open source API and drivers for immersive technology"
  homepage "http://openhmd.net"
  url "https://github.com/OpenHMD/OpenHMD/archive/0.2.0.tar.gz"
  sha256 "b5be787229d7c7c5cb763cec6207f9814b0bb993c68842ef0a390184ca25380d"
  head "https://github.com/OpenHMD/OpenHMD.git"

  bottle do
    cellar :any
    sha256 "999945d3e8003410777939f746f8f460c767ab2824dc2d1de3ab24af532daf0d" => :sierra
    sha256 "0e94a1356e5f6f0fb4079e16f431aae23003fa00c3ccaa8add9d5dd382b89b34" => :el_capitan
    sha256 "71e356cdd47df73193ec52341d4bc252237e48b8bad182d695fbeb74a3ed41ed" => :yosemite
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "hidapi"

  conflicts_with "cspice", :because => "both install `simple` binaries"
  conflicts_with "libftdi0", :because => "both install `simple` binaries"

  def install
    system "./autogen.sh"
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
    (pkgshare/"tests").install bin/"unittests"
  end

  test do
    system pkgshare/"tests/unittests"
  end
end
