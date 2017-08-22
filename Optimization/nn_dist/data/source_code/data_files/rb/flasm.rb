class Flasm < Formula
  desc "Flash command-line assembler and disassembler"
  homepage "http://www.nowrap.de/flasm.html"
  url "http://www.nowrap.de/download/flasm16src.zip"
  version "1.62"
  sha256 "df1273a506e2479cf95775197f5b7fa94e29fe1e0aae5aa190ed5bbebc4be5c6"

  bottle do
    cellar :any_skip_relocation
    sha256 "423b77912442f613cec430a8eee149783047f6b1a32d82d4b2920969fb6ca77e" => :sierra
    sha256 "44aa3b83ee62932fea2f1b3139b2fe391c59bba92f890121eca35e2736214b52" => :el_capitan
    sha256 "b2ae27971e7fa4a731000eeda0cd7a8fb75cbe55d013af3c2d9d0cc3b2bc405f" => :yosemite
    sha256 "73568b00e6ecdde3baa228ef27e2c43a4879cb15bfd3d0ca036510a5d2dcbd3a" => :mavericks
    sha256 "020427b0cc5136824426970850eaa2563275f428d3a47e1d9d19fedea13aacd2" => :mountain_lion
  end

  def install
    system "make", "CC=#{ENV.cc}", "CFLAGS=#{ENV.cflags}"
    bin.install "flasm"
  end

  test do
    (testpath/"test").write <<-EOS.undent
      constants 'a', 'b'
      push 'a', 'b'
      getVariable
      push 'b'
      getVariable
      multiply
      setVariable
    EOS

    system "#{bin}/flasm", "-b", "test"
  end
end
