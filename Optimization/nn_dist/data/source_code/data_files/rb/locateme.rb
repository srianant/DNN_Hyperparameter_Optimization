class Locateme < Formula
  desc "Find your location using Apple's geolocation services"
  homepage "http://iharder.sourceforge.net/current/macosx/locateme"
  url "https://downloads.sourceforge.net/project/iharder/locateme/LocateMe-v0.2.1.zip"
  sha256 "137016e6c1a847bbe756d8ed294b40f1d26c1cb08869940e30282e933e5aeecd"

  bottle do
    cellar :any_skip_relocation
    sha256 "cb5fe0b740f04c036726e546481f0eed603873ce57b063e0621ae8f73f66645d" => :sierra
    sha256 "5f8e1febc1886565bfa9691cb3ffc0486999f8b682a52276c1d9ea6e0f1f4470" => :el_capitan
    sha256 "a7876905a4c06452431e506523c5fdf142e2de364427600122fbb9b4928bc6d1" => :yosemite
  end

  def install
    system ENV.cc, "-framework", "Foundation", "-framework", "CoreLocation", "LocateMe.m", "-o", "LocateMe"
    bin.install "LocateMe"
    man1.install "LocateMe.1"
  end

  test do
    system "#{bin}/LocateMe", "-h"
  end
end
