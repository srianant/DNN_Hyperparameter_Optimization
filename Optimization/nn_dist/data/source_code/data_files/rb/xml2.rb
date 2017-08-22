class Xml2 < Formula
  desc "Makes XML and HTML more amenable to classic UNIX text tools"
  homepage "https://web.archive.org/web/20160730094113/http://www.ofb.net/~egnor/xml2/"
  url "https://web.archive.org/web/20160427221603/http://download.ofb.net/gale/xml2-0.5.tar.gz"
  sha256 "e3203a5d3e5d4c634374e229acdbbe03fea41e8ccdef6a594a3ea50a50d29705"

  bottle do
    cellar :any_skip_relocation
    rebuild 1
    sha256 "d8d4bb9ceb9d97b648d3fd3cffb1e2fad2e4d82aa6aa3397c22f53fe5468ac56" => :sierra
    sha256 "85e939873edbb3dd1b072437992a0c404534a5084cccd6f9f76d99b09ddda695" => :el_capitan
    sha256 "3883d5997021b3a5bd57d8830906cb9b370da0f6e1927b6c7e9dcd6740e05c5c" => :yosemite
  end

  depends_on "pkg-config" => :build

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_equal "/test", pipe_output("#{bin}/xml2", "<test/>", 0).chomp
  end
end
