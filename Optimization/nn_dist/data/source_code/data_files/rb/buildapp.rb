class Buildapp < Formula
  desc "Creates executables with SBCL"
  homepage "http://www.xach.com/lisp/buildapp/"
  url "https://github.com/xach/buildapp/archive/release-1.5.6.tar.gz"
  sha256 "d77fb6c151605da660b909af058206f7fe7d9faf972e2c30876d42cb03d6a3ed"
  head "https://github.com/xach/buildapp.git"

  bottle do
    sha256 "672cce34c7c3d0ce4ed2a434fc4c3933a3ba06e07ddff80f0aad24e92ce5ed51" => :el_capitan
    sha256 "353795727bd0ef56e9597de4a6e5d3352e4e07f8d8d61d0610a68810aac90bf1" => :yosemite
    sha256 "6e7ad94bb743298d8fe8fa64c73d70a156e5aae829c48aef9e0ac300fac97488" => :mavericks
  end

  depends_on "sbcl"

  def install
    bin.mkpath
    system "make", "install", "DESTDIR=#{prefix}"
  end

  test do
    code = "(defun f (a) (declare (ignore a)) (write-line \"Hello, homebrew\"))"
    system "#{bin}/buildapp", "--eval", code,
                              "--entry", "f",
                              "--output", "t"
    assert_equal `./t`, "Hello, homebrew\n"
  end
end
