class X11vnc < Formula
  desc "VNC server for real X displays"
  homepage "http://www.karlrunge.com/x11vnc/"
  url "https://downloads.sourceforge.net/project/libvncserver/x11vnc/0.9.13/x11vnc-0.9.13.tar.gz"
  sha256 "f6829f2e629667a5284de62b080b13126a0736499fe47cdb447aedb07a59f13b"

  bottle do
    cellar :any
    sha256 "077e8a99c5097641b24d5d8e4c8b75076e81bc8b07876fff4a53d4b9d67d8831" => :sierra
    sha256 "5b215e4baff20b8120706c2698766fc7a84033e0502949691ed66e12f984bdf0" => :el_capitan
    sha256 "a32bb68e7b1ebb96de7acd8ce4d602038fed7ae0d7e6c6adca294fc688f2a8ad" => :yosemite
    sha256 "6e92c88b0c90fbda1ffc73f62c7ef2482b42b544595232b02caa54a6ab7c7021" => :mavericks
    sha256 "104e7c7dfd642f901e9f8be417b77540242c1ef2bf8e8aba6bee64e5d9f2a215" => :mountain_lion
  end

  depends_on :x11 => :optional
  depends_on "openssl"
  depends_on "jpeg"

  # Patch solid.c so a non-void function returns a NULL instead of a void.
  # An email has been sent to the maintainers about this issue.
  patch :DATA

  def install
    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --prefix=#{prefix}
      --mandir=#{man}
    ]

    if build.with? "x11"
      args << "--with-x"
    else
      args << "--without-x"
    end

    system "./configure", *args
    system "make"
    system "make", "MKDIRPROG=mkdir -p", "install"
  end

  test do
    system bin/"x11vnc", "--version"
  end
end

__END__
diff --git a/x11vnc/solid.c b/x11vnc/solid.c
index d6b0bda..0b2cfa9 100644
--- a/x11vnc/solid.c
+++ b/x11vnc/solid.c
@@ -177,7 +177,7 @@ unsigned long get_pixel(char *color) {
 
 XImage *solid_root(char *color) {
 #if NO_X11
-	RAWFB_RET_VOID
+	RAWFB_RET(NULL)
 	if (!color) {}
 	return NULL;
 #else
