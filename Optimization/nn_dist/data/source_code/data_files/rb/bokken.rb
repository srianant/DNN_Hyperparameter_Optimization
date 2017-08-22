class Bokken < Formula
  desc "GUI for the Pyew and Radare projects"
  homepage "http://bokken.re/"
  url "https://inguma.eu/attachments/download/212/bokken-1.8.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.netbsd.org/pub/pkgsrc/distfiles/bokken-1.8.tar.gz"
  sha256 "1c73885147dfcf0a74ba4d3dd897a6aabc11a4a42f95bd1269782d0b2e1a11b9"
  revision 1

  bottle do
    cellar :any
    rebuild 1
    sha256 "ab4748b33f0cf6662484a6bb9164e83375574d7a9f7a65df396b02d69a4536bb" => :sierra
    sha256 "b1af4c645b8f74359fa1d3f72e8d01148be47cb94fe3cb5fe2743e0f0f11fb25" => :el_capitan
    sha256 "12499141d1e78fee72d12550ea95b07f5d8e96c5dc9f7426b4329f8d7f309821" => :yosemite
    sha256 "cfbbed6a3f39b9d714ac7abaecf802050a14f0811684ce554d2eb1fc21e6a608" => :mavericks
  end

  depends_on "graphviz"
  depends_on "librsvg"
  depends_on "pygtk"
  depends_on "pygtksourceview"
  depends_on "radare2"

  resource "distorm64" do
    url "https://mirrorservice.org/sites/ftp.debian.org/debian/pool/main/d/distorm64/distorm64_1.7.30.orig.tar.gz"
    sha256 "98b218e5a436226c5fb30d3b27fcc435128b4e28557c44257ed2ba66bb1a9cf1"
  end

  resource "pyew" do
    # Upstream only provides binary packages so pull from Debian.
    url "https://mirrorservice.org/sites/ftp.debian.org/debian/pool/main/p/pyew/pyew_2.0.orig.tar.gz"
    sha256 "64a4dfb1850efbe2c9b06108697651f9ff25223fd132eec66c6fe84d5ecc17ae"
  end

  def install
    resource("distorm64").stage do
      inreplace "src/pydistorm.h", "python2\.5", "python2.7"
      cd "build/mac" do
        inreplace "Makefile", "-lpython", "-undefined dynamic_lookup"
        system "make"
        mkdir_p libexec/"distorm64"
        (libexec/"distorm64").install "libdistorm64.dylib"
        ln_s "libdistorm64.dylib", libexec/"distorm64/libdistorm64.so"
      end
    end

    resource("pyew").stage do
      (libexec/"pyew").install Dir["*"]
      # Make sure that the launcher looks for pyew.py in the correct path (fixed
      # in pyew ab9ea236335e).
      inreplace libexec/"pyew/pyew", "\./pyew.py", "`dirname $0`/pyew.py"
    end

    python_path = "#{libexec}/lib/python2.7/site-packages:#{libexec}/pyew"
    ld_library_path = "#{libexec}/distorm64"
    (libexec/"bokken").install Dir["*"]
    (bin/"bokken").write <<-EOS.undent
      #!/usr/bin/env bash
      env \
        PYTHONPATH=#{python_path}:${PYTHONPATH} \
        LD_LIBRARY_PATH=#{ld_library_path}:${LD_LIBRARY_PATH} \
        python #{libexec}/bokken/bokken.py "${@}"
    EOS
  end
end
