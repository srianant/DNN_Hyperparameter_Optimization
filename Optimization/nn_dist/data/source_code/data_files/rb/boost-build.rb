class BoostBuild < Formula
  desc "C++ build system"
  homepage "https://www.boost.org/build/"
  url "https://github.com/boostorg/build/archive/2016.03.tar.gz"
  sha256 "1e79253a6ce4cadb08ac1c05feaef241cbf789b65362ba8973e37c1d25a2fbe9"

  head "https://github.com/boostorg/build.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "87c0d16831b948b198795c2d17b96d8d7a586c0775411c4b3097266fef09e52f" => :sierra
    sha256 "da756b55ac249c474a875ee4d2c57a49ec7331b08ee006cba5b2477883dbffee" => :el_capitan
    sha256 "59dfa2358b532c384a8ff452be4c09d7d4e085f3a0be8c3f859c60ff55830905" => :yosemite
  end

  conflicts_with "b2-tools", :because => "both install `b2` binaries"

  def install
    system "./bootstrap.sh"
    system "./b2", "--prefix=#{prefix}", "install"
  end
end
