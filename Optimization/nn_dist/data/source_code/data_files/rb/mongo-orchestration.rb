class MongoOrchestration < Formula
  desc "REST API to manage MongoDB configurations on a single host."
  homepage "https://github.com/10gen/mongo-orchestration"
  url "https://pypi.python.org/packages/source/m/mongo-orchestration/mongo-orchestration-0.5.tar.gz"
  sha256 "3d99f1700ba11169d9b25b8196454f4ba91476c5aea23b4cf368bea6bd73a07d"

  head "https://github.com/10gen/mongo-orchestration"

  bottle do
    cellar :any_skip_relocation
    sha256 "2f5bb55fb3807bcba1c4d14d7d15a5e28f5fc282961c95c0d923f9a7a380f97f" => :sierra
    sha256 "ec730d61a6708de1d3e0d2a3b1e41e51cc9ccff3f47b501f0c066e36dd2f0bc6" => :el_capitan
    sha256 "6da2ea7a7537b1e2a100c937d96ba5490253ebb9c061c4d5dcb6129d9c5d5b62" => :yosemite
    sha256 "df9d112113a99ca42b35ad89dc7e7d38944087a7512d79421c0897965df99875" => :mavericks
  end

  depends_on :python if MacOS.version <= :snow_leopard

  resource "bottle" do
    url "https://pypi.python.org/packages/source/b/bottle/bottle-0.12.9.tar.gz"
    sha256 "fe0a24b59385596d02df7ae7845fe7d7135eea73799d03348aeb9f3771500051"
  end

  resource "pymongo" do
    url "https://pypi.python.org/packages/source/p/pymongo/pymongo-3.2.1.tar.gz"
    sha256 "57a86ca602b0a4d2da1f9f3afa8c59fd8ca62d829f6d8f467eae0b7cb22ba88a"
  end

  resource "cherrypy" do
    url "https://pypi.python.org/packages/source/C/CherryPy/CherryPy-4.0.0.tar.gz"
    sha256 "73ad4f8870b5a3e9988a7778b5d3003a390d440527ec3458a0c7e58865d2611a"
  end

  def install
    ENV.prepend_create_path "PYTHONPATH", libexec/"vendor/lib/python2.7/site-packages"

    resources.each do |r|
      r.stage do
        system "python", *Language::Python.setup_install_args(libexec/"vendor")
      end
    end

    ENV.prepend_create_path "PYTHONPATH", libexec/"lib/python2.7/site-packages"
    system "python", *Language::Python.setup_install_args(libexec)

    bin.install Dir["#{libexec}/bin/*"]
    bin.env_script_all_files(libexec/"bin", :PYTHONPATH => ENV["PYTHONPATH"])
  end

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>mongo-orchestration</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/mongo-orchestration</string>
          <string>-b</string>
          <string>127.0.0.1</string>
          <string>-p</string>
          <string>8889</string>
          <string>--no-fork</string>
          <string>start</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
      </dict>
    </plist>
  EOS
  end

  test do
    system "#{bin}/mongo-orchestration", "-h"
  end
end
