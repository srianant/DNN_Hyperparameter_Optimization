class Pidgin < Formula
  desc "Multi-protocol chat client"
  homepage "https://pidgin.im/"
  url "https://downloads.sourceforge.net/project/pidgin/Pidgin/2.11.0/pidgin-2.11.0.tar.bz2"
  sha256 "f72613440586da3bdba6d58e718dce1b2c310adf8946de66d8077823e57b3333"

  bottle do
    sha256 "af3ead310f0c64642b0e231c2efc30d6f9a6f3fc8041ac1074f0bf0c0876cc7b" => :sierra
    sha256 "52962570a3c7ad641a990054e48e677749ff787792ae4baef4b8221b30cb23bd" => :el_capitan
    sha256 "8bcee9a4d3b7a5eb75956fae72e99da7278aab11f4da29b543d76459709e4057" => :yosemite
    sha256 "0cc25abde42aca098cd2009df81044aa15b5bf02996f9c23a9fe9ea159f315ac" => :mavericks
  end

  option "with-perl", "Build Pidgin with Perl support"
  option "without-gui", "Build only Finch, the command-line client"

  deprecated_option "perl" => "with-perl"
  deprecated_option "without-GUI" => "without-gui"

  depends_on "pkg-config" => :build
  depends_on "intltool" => :build
  depends_on "gettext"
  depends_on "gsasl" => :optional
  depends_on "gnutls"
  depends_on "libgcrypt"
  depends_on "libidn"
  depends_on "glib"

  if build.with? "gui"
    depends_on "gtk+"
    depends_on "cairo"
    depends_on "pango"
    depends_on "libotr"
  end

  # Finch has an equal port called purple-otr but it is a NIGHTMARE to compile
  # If you want to fix this and create a PR on Homebrew please do so.
  resource "pidgin-otr" do
    url "https://otr.cypherpunks.ca/pidgin-otr-4.0.2.tar.gz"
    sha256 "f4b59eef4a94b1d29dbe0c106dd00cdc630e47f18619fc754e5afbf5724ebac4"
  end

  def install
    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --prefix=#{prefix}
      --disable-avahi
      --disable-doxygen
      --enable-gnutls=yes
      --disable-dbus
      --disable-gevolution
      --disable-gstreamer
      --disable-gstreamer-interfaces
      --disable-gtkspell
      --disable-meanwhile
      --disable-vv
      --without-x
    ]

    args << "--disable-perl" if build.without? "perl"
    args << "--enable-cyrus-sasl" if build.with? "gsasl"

    args << "--with-tclconfig=#{MacOS.sdk_path}/usr/lib"
    args << "--with-tkconfig=#{MacOS.sdk_path}/usr/lib"
    if build.without? "gui"
      args << "--disable-gtkui"
    end

    system "./configure", *args
    system "make", "install"

    if build.with? "gui"
      resource("pidgin-otr").stage do
        ENV.prepend "CFLAGS", "-I#{Formula["libotr"].opt_include}"
        ENV.append_path "PKG_CONFIG_PATH", "#{lib}/pkgconfig"
        system "./configure", "--prefix=#{prefix}", "--mandir=#{man}"
        system "make", "install"
      end
    end
  end

  test do
    system "#{bin}/finch", "--version"
  end
end
