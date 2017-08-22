class Qstat < Formula
  desc "Query Quake servers from the command-line"
  homepage "http://qstat.sourceforge.net"
  url "https://downloads.sourceforge.net/project/qstat/qstat/qstat-2.11/qstat-2.11.tar.gz"
  sha256 "16f0c0f55567597d7f2db5136a0858c56effb4481a2c821a48cd0432ea572150"

  bottle do
    sha256 "816789bcb602cd112a64dadad943752fed3c7f32785e60a10e486026d5b26adc" => :sierra
    sha256 "2f674bb005dab3dcce93c131e5b238f0813638a974f82c85bffdbbeef49eb698" => :el_capitan
    sha256 "d63924f48565d8c17295544765e0dac015d7189c7608179dd9d0848c69f9e67b" => :yosemite
    sha256 "96b05212759a5a648f24ade7334738bda8d4ef4eeb8669e31afe45ed6293dc52" => :mavericks
  end

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end
end
