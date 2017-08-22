class Ekhtml < Formula
  desc "Forgiving SAX-style HTML parser"
  homepage "http://ekhtml.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/ekhtml/ekhtml/0.3.2/ekhtml-0.3.2.tar.gz"
  sha256 "1ed1f0166cd56552253cd67abcfa51728ff6b88f39bab742dbf894b2974dc8d6"

  bottle do
    cellar :any
    sha256 "a4e245b9e7b3643dea35dc0b6dece64f92b76d27ec59ba28c30ea7a666254396" => :sierra
    sha256 "d606a2fe3d466a5e76f22a0736f0b485be613bad4a09575d496d9396d3a71903" => :el_capitan
    sha256 "450e3decaf7077d771f4a5eb43047c820867b17bffb312b039be8b1a33a81611" => :yosemite
    sha256 "4ae02f9ef463d52c8c0c7bccfd3f63441258a89a976f2869bf416b408fc534f3" => :mavericks
  end

  def install
    ENV.j1
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end
end
