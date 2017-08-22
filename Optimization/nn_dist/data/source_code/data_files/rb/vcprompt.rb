class Vcprompt < Formula
  desc "Provide version control info in shell prompts"
  homepage "https://bitbucket.org/gward/vcprompt"
  url "https://bitbucket.org/gward/vcprompt/downloads/vcprompt-1.2.1.tar.gz"
  sha256 "98c2dca278a34c5cdbdf4a5ff01747084141fbf4c50ba88710c5a13c3cf9af09"

  bottle do
    cellar :any
    rebuild 1
    sha256 "9416ab35f637cc751b667f1a8481d17936faa58f39749d87e4e32b07b647f229" => :sierra
    sha256 "11e4de5f008aec3510274ef2265d6d30d214249e127cc1d3045b01b47232c96b" => :el_capitan
    sha256 "a6b02f96a018c993568e4ee43bfa23343c88aa4c6aa58b4727b69c01340f59ff" => :yosemite
    sha256 "ee133ff8277ce6d7792acd261ba3f27259e677badfe73b80ffd6fd08c6cd3665" => :mavericks
  end

  head do
    url "https://bitbucket.org/gward/vcprompt", :using => :hg
    depends_on "autoconf" => :build
  end

  depends_on "sqlite"

  def install
    system "autoconf" if build.head?

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"

    system "make", "PREFIX=#{prefix}",
                   "MANDIR=#{man1}",
                   "install"
  end

  test do
    system "#{bin}/vcprompt"
  end
end
