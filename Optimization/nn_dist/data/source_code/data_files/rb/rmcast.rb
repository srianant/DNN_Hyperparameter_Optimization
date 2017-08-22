class Rmcast < Formula
  desc "IP Multicast library"
  homepage "http://www.land.ufrj.br/tools/rmcast/rmcast.html"
  url "http://www.land.ufrj.br/tools/rmcast/download/rmcast-2.0.0.tar.gz"
  sha256 "79ccbdbe4a299fd122521574eaf9b3e2d524dd5e074d9bc3eb521f1d934a59b1"

  bottle do
    cellar :any
    sha256 "9ef73c5d52886029cd89d829cdceccca0d03bce0dc72647d8cce6704d492f080" => :sierra
    sha256 "4fe0a1745659bb99748972c2fa0640e6b864e92739ba192a89ed12c0614b1372" => :el_capitan
    sha256 "502e09994a9b455d9040f8e346419a2a3ef0156a73b0249bc161446448729292" => :yosemite
    sha256 "1afd20258226dc16873b567b1b5ab920b9e414f4733bfa99fa917074685f2b8a" => :mavericks
  end

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end
end
