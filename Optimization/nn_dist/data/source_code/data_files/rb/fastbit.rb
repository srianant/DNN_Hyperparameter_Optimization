class Fastbit < Formula
  desc "Open-source data processing library in NoSQL spirit"
  homepage "https://sdm.lbl.gov/fastbit/"
  url "https://codeforge.lbl.gov/frs/download.php/416/fastbit-2.0.2.tar.gz"
  sha256 "a9d6254fcc32da6b91bf00285c7820869950bed25d74c993da49e1336fd381b4"
  head "https://codeforge.lbl.gov/anonscm/fastbit/trunk",
       :using => :svn

  bottle do
    cellar :any
    sha256 "8ddbbfacf64944c202e98960f7d7a2bed3115d6184dd642842712bb2d12bba3a" => :sierra
    sha256 "2805a5e4739ab396077fad99782174b25def6d0c8ce3d3728ed39fed2160f286" => :el_capitan
    sha256 "33aa7e0a593b07b6d1615200b06ccd6eecd742beac345bd94b262f1b386d3591" => :yosemite
    sha256 "f2da8bed14e66f334f870cec65c678961f925d519bddefc74ef806b493346833" => :mavericks
    sha256 "d62226b902928b479e2835848a8eafdcd52557cb4249c59bd15cc1bd23d1e67e" => :mountain_lion
  end

  depends_on :java
  needs :cxx11

  conflicts_with "iniparser", :because => "Both install `include/dictionary.h`"

  def install
    ENV.cxx11
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
    libexec.install lib/"fastbitjni.jar"
    bin.write_jar_script libexec/"fastbitjni.jar", "fastbitjni"
  end

  test do
    assert_equal prefix.to_s,
                 shell_output("#{bin}/fastbit-config --prefix").chomp
    (testpath/"test.csv").write <<-EOS
      Potter,Harry
      Granger,Hermione
      Weasley,Ron
     EOS
    system bin/"ardea", "-d", testpath,
           "-m", "a:t,b:t", "-t", testpath/"test.csv"
  end
end
