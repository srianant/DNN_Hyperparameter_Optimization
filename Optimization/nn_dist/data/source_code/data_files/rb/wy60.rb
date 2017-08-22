class Wy60 < Formula
  desc "Wyse 60 compatible terminal emulator"
  homepage "https://code.google.com/archive/p/wy60/"
  url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/wy60/wy60-2.0.9.tar.gz"
  sha256 "f7379404f0baf38faba48af7b05f9e0df65266ab75071b2ca56195b63fc05ed0"

  bottle do
    sha256 "f03706d166cfcc0679e696493bd13df30ad0617a92b602b79e3494ba3b1f46fb" => :sierra
    sha256 "84d3bfa45582f2816808006f192c7580cedad24de3941a0786b5b36ce29e469c" => :el_capitan
    sha256 "80508e33f12142eec20ff0e8866ed191b03facea5b6653a6f5331cb017ff78af" => :yosemite
    sha256 "7257f9a9c49d867114209be3d4b4b8537da65f34302fa15266f7ead044947331" => :mavericks
  end

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end
end
