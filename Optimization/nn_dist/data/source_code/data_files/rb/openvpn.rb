class Openvpn < Formula
  desc "SSL VPN implementing OSI layer 2 or 3 secure network extension"
  homepage "https://openvpn.net/index.php/download/community-downloads.html"
  url "https://swupdate.openvpn.org/community/releases/openvpn-2.3.13.tar.xz"
  mirror "https://build.openvpn.net/downloads/releases/openvpn-2.3.13.tar.xz"
  sha256 "9cde0c8000fd32d5275adb55f8bb1d8ba429ff3de35f60a36e81f3859b7537e0"

  bottle do
    cellar :any
    sha256 "0fe4812ab0aac4851646ca5d56f99ce278849f0aa4bffd5ce998639c878b6075" => :sierra
    sha256 "346b5be100c4853471fe7cc675e442f41338ecb71a696bafc662580e8ddef9d4" => :el_capitan
    sha256 "78babe5014b3a3e027dad33bb49887b6912422c184d8a63be2bdf790d94d6ca5" => :yosemite
  end

  # Requires tuntap for < 10.10
  depends_on :macos => :yosemite

  depends_on "lzo"
  depends_on "openssl"
  depends_on "pkcs11-helper" => [:optional, "without-threading", "without-slotevent"]

  if build.with? "pkcs11-helper"
    depends_on "pkg-config" => :build
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --disable-silent-rules
      --with-crypto-library=openssl
      --prefix=#{prefix}
      --enable-password-save
    ]

    args << "--enable-pkcs11" if build.with? "pkcs11-helper"

    system "./configure", *args
    system "make", "install"

    inreplace "sample/sample-config-files/openvpn-startup.sh",
              "/etc/openvpn", "#{etc}/openvpn"

    (doc/"samples").install Dir["sample/sample-*"]
    (etc/"openvpn").install doc/"samples/sample-config-files/client.conf"
    (etc/"openvpn").install doc/"samples/sample-config-files/server.conf"

    # We don't use PolarSSL, so this file is unnecessary & somewhat confusing.
    rm doc/"README.polarssl"
  end

  def post_install
    (var/"run/openvpn").mkpath
  end

  plist_options :startup => true

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd";>
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_sbin}/openvpn</string>
        <string>--config</string>
        <string>#{etc}/openvpn/openvpn.conf</string>
      </array>
      <key>OnDemand</key>
      <false/>
      <key>RunAtLoad</key>
      <true/>
      <key>TimeOut</key>
      <integer>90</integer>
      <key>WatchPaths</key>
      <array>
        <string>#{etc}/openvpn</string>
      </array>
      <key>WorkingDirectory</key>
      <string>#{etc}/openvpn</string>
    </dict>
    </plist>
    EOS
  end

  test do
    system sbin/"openvpn", "--show-ciphers"
  end
end
