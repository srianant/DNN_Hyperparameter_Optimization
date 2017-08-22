class Libiodbc < Formula
  desc "Database connectivity layer based on ODBC. (alternative to unixodbc)"
  homepage "http://www.iodbc.org/dataspace/iodbc/wiki/iODBC/"
  url "https://downloads.sourceforge.net/project/iodbc/iodbc/3.52.12/libiodbc-3.52.12.tar.gz"
  sha256 "51c5ff3a7d9a54202486cb77a3514e0e379a135beefcd5d12b96d1901f9dfb62"

  bottle do
    cellar :any
    sha256 "197ddbad1eec2fc783faf97622dd53cc29c600b0c725fb96b6252dc94dabd731" => :sierra
    sha256 "85570401135c9fa3f6325ae4ce098180128491c4472155f85ad5b7c4c6473d9e" => :el_capitan
    sha256 "cbcd0d50f16a1faa596466ba6678529550d631f770f84657da877f87e17b0424" => :yosemite
    sha256 "47fecc486608df1edc094742a3afbd33c7159c8957429528e11a6fb6f551ebc4" => :mavericks
  end

  keg_only :provided_pre_mavericks

  depends_on "automake" => :build
  depends_on "autoconf" => :build
  depends_on "libtool" => :build

  def install
    system "./autogen.sh"
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"iodbc-config", "--version"
  end
end
