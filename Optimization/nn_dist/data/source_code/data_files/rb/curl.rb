class Curl < Formula
  desc "Get a file from an HTTP, HTTPS or FTP server"
  homepage "https://curl.haxx.se/"
  url "https://curl.haxx.se/download/curl-7.51.0.tar.bz2"
  sha256 "7f8240048907e5030f67be0a6129bc4b333783b9cca1391026d700835a788dde"

  bottle do
    cellar :any
    rebuild 1
    sha256 "f22103edd6d20beb57ac9f2f006f07034fd11b1daa37a213587ed42625e270a4" => :sierra
    sha256 "a8eab505288894c1921740a656492c5548306de0f204061dfe3e3f7cf434e01c" => :el_capitan
    sha256 "542d195a25d227a24dcf3bbbc40b99d892d101bbb1b422729ab495a1289f0dfc" => :yosemite
  end

  keg_only :provided_by_osx

  option "with-libidn", "Build with support for Internationalized Domain Names"
  option "with-rtmpdump", "Build with RTMP support"
  option "with-libssh2", "Build with scp and sftp support"
  option "with-c-ares", "Build with C-Ares async DNS support"
  option "with-gssapi", "Build with GSSAPI/Kerberos authentication support."
  option "with-libmetalink", "Build with libmetalink support."
  option "with-libressl", "Build with LibreSSL instead of Secure Transport or OpenSSL"
  option "with-nghttp2", "Build with HTTP/2 support (requires OpenSSL or LibreSSL)"

  deprecated_option "with-idn" => "with-libidn"
  deprecated_option "with-rtmp" => "with-rtmpdump"
  deprecated_option "with-ssh" => "with-libssh2"
  deprecated_option "with-ares" => "with-c-ares"

  # HTTP/2 support requires OpenSSL 1.0.2+ or LibreSSL 2.1.3+ for ALPN Support
  # which is currently not supported by Secure Transport (DarwinSSL).
  if MacOS.version < :mountain_lion || (build.with?("nghttp2") && build.without?("libressl"))
    depends_on "openssl"
  else
    option "with-openssl", "Build with OpenSSL instead of Secure Transport"
    depends_on "openssl" => :optional
  end

  depends_on "pkg-config" => :build
  depends_on "libidn" => :optional
  depends_on "rtmpdump" => :optional
  depends_on "libssh2" => :optional
  depends_on "c-ares" => :optional
  depends_on "libmetalink" => :optional
  depends_on "libressl" => :optional
  depends_on "nghttp2" => :optional

  def install
    # Fail if someone tries to use both SSL choices.
    # Long-term, handle conflicting options case in core code.
    if build.with?("libressl") && build.with?("openssl")
      odie <<-EOS.undent
      --with-openssl and --with-libressl are both specified and
      curl can only use one at a time.
      EOS
    end

    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
    ]

    # cURL has a new firm desire to find ssl with PKG_CONFIG_PATH instead of using
    # "--with-ssl" any more. "when possible, set the PKG_CONFIG_PATH environment
    # variable instead of using this option". Multi-SSL choice breaks w/o using it.
    if build.with? "libressl"
      ENV.prepend_path "PKG_CONFIG_PATH", "#{Formula["libressl"].opt_lib}/pkgconfig"
      args << "--with-ssl=#{Formula["libressl"].opt_prefix}"
      args << "--with-ca-bundle=#{etc}/libressl/cert.pem"
      args << "--with-ca-path=#{etc}/libressl/certs"
    elsif MacOS.version < :mountain_lion || build.with?("openssl") || build.with?("nghttp2")
      ENV.prepend_path "PKG_CONFIG_PATH", "#{Formula["openssl"].opt_lib}/pkgconfig"
      args << "--with-ssl=#{Formula["openssl"].opt_prefix}"
      args << "--with-ca-bundle=#{etc}/openssl/cert.pem"
      args << "--with-ca-path=#{etc}/openssl/certs"
    else
      args << "--with-darwinssl"
      args << "--without-ca-bundle"
      args << "--without-ca-path"
    end

    args << (build.with?("libssh2") ? "--with-libssh2" : "--without-libssh2")
    args << (build.with?("libidn") ? "--with-libidn" : "--without-libidn")
    args << (build.with?("libmetalink") ? "--with-libmetalink" : "--without-libmetalink")
    args << (build.with?("gssapi") ? "--with-gssapi" : "--without-gssapi")
    args << (build.with?("rtmpdump") ? "--with-librtmp" : "--without-librtmp")

    if build.with? "c-ares"
      args << "--enable-ares=#{Formula["c-ares"].opt_prefix}"
    else
      args << "--disable-ares"
    end

    system "./configure", *args
    system "make", "install"
    libexec.install "lib/mk-ca-bundle.pl"
  end

  test do
    # Fetch the curl tarball and see that the checksum matches.
    # This requires a network connection, but so does Homebrew in general.
    filename = (testpath/"test.tar.gz")
    system "#{bin}/curl", "-L", stable.url, "-o", filename
    filename.verify_checksum stable.checksum

    system libexec/"mk-ca-bundle.pl", "test.pem"
    assert File.exist?("test.pem")
    assert File.exist?("certdata.txt")
  end
end
