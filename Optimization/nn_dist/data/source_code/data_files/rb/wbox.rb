class Wbox < Formula
  desc "HTTP testing tool and configuration-less HTTP server"
  homepage "http://hping.org/wbox/"
  url "http://www.hping.org/wbox/wbox-5.tar.gz"
  sha256 "1589d85e83c8ee78383a491d89e768ab9aab9f433c5f5e035cfb5eed17efaa19"

  bottle do
    cellar :any_skip_relocation
    sha256 "241edb51af197d72022a48cb8444506188269b335b057ceaa7bf952db86777d8" => :sierra
    sha256 "0e813a0982d6b9228217f14352812d9e6880cce44757f8af9a0447bf5e4a1e63" => :el_capitan
    sha256 "ee2bd7599a73c3a9f3fe9f8c2d441d753914981b2420e591050780d436bbf011" => :yosemite
    sha256 "35b640ce39cd36f75ec595215099f121feb517672fb11abf30b36a1e567fc117" => :mavericks
  end

  def install
    system "make"
    bin.install "wbox"
  end

  test do
    system "#{bin}/wbox", "www.google.com", "1"
  end
end
