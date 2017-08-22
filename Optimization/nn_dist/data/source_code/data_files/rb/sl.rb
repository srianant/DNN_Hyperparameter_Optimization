class Sl < Formula
  desc "Prints a steam locomotive if you type sl instead of ls"
  homepage "https://github.com/mtoyoda/sl"
  url "https://github.com/mtoyoda/sl/archive/5.02.tar.gz"
  sha256 "1e5996757f879c81f202a18ad8e982195cf51c41727d3fea4af01fdcbbb5563a"

  head "https://github.com/mtoyoda/sl.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "afd30cb3a99d238a8ac52810834244d5f47fc2ff597db9ad61012bd2014395b9" => :sierra
    sha256 "f186cb86f4d48929aa671434dbd6be0a861069608098a30dc952697bcca85972" => :el_capitan
    sha256 "696104243a18e08279d461e66e6a696791e6c36b67df43e361ad6f6de1200440" => :yosemite
    sha256 "c7d4432bfc169f7338eeb0c8300a975495b229d6e85bfff4fdd6bbd11eb8da17" => :mavericks
  end

  fails_with :clang do
    build 318
  end

  def install
    system "make -e"
    bin.install "sl"
    man1.install "sl.1"
  end
end
