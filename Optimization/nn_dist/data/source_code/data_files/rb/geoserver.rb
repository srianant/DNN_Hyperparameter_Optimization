class Geoserver < Formula
  desc "Java server to share and edit geospatial data"
  homepage "http://geoserver.org/"
  url "https://downloads.sourceforge.net/project/geoserver/GeoServer/2.10.0/geoserver-2.10.0-bin.zip"
  sha256 "6d29190863299635333151a2adc441171468961ec84621096c22d93233c47f53"

  bottle :unneeded

  def install
    libexec.install Dir["*"]
    (bin/"geoserver").write <<-EOS.undent
      #!/bin/sh
      if [ -z "$1" ]; then
        echo "Usage: $ geoserver path/to/data/dir"
      else
        cd "#{libexec}" && java -DGEOSERVER_DATA_DIR=$1 -jar start.jar
      fi
    EOS
  end

  def caveats; <<-EOS.undent
    To start geoserver:
      geoserver path/to/data/dir
    EOS
  end

  test do
    assert_match "geoserver path", shell_output("#{bin}/geoserver")
  end
end
