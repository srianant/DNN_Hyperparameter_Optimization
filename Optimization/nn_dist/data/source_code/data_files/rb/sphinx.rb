class Sphinx < Formula
  desc "Full-text search engine"
  homepage "http://www.sphinxsearch.com"
  url "http://sphinxsearch.com/files/sphinx-2.2.11-release.tar.gz"
  sha256 "6662039f093314f896950519fa781bc87610f926f64b3d349229002f06ac41a9"
  head "https://github.com/sphinxsearch/sphinx.git"

  bottle do
    sha256 "55ce34bdedf13946fa614bde50839d93135eae720f1021e2c87807d04515ab18" => :sierra
    sha256 "c75e018d69afb7d3cb662ebd129af67607d47f7b7f71ce8ea95be75d66dc502d" => :el_capitan
    sha256 "f89b43df8735d295a55c74f18d6af4a1a10b9f3ae81df69713c27f9240f78d14" => :yosemite
    sha256 "4ec1f1ea71e17b9e924e9f36747d7184114463640f100022cdbb46202e46261f" => :mavericks
  end

  option "with-mysql", "Force compiling against MySQL"
  option "with-postgresql", "Force compiling against PostgreSQL"
  option "with-id64", "Force compiling with 64-bit ID support"

  deprecated_option "mysql" => "with-mysql"
  deprecated_option "pgsql" => "with-postgresql"
  deprecated_option "id64" => "with-id64"

  depends_on "re2" => :optional
  depends_on :mysql => :optional
  depends_on :postgresql => :optional
  depends_on "openssl" if build.with? "mysql"

  resource "stemmer" do
    url "https://github.com/snowballstem/snowball.git",
        :revision => "9b58e92c965cd7e3208247ace3cc00d173397f3c"
  end

  fails_with :llvm do
    build 2334
    cause <<-EOS.undent
      ld: rel32 out of range in _GetPrivateProfileString from
          /usr/lib/libodbc.a(SQLGetPrivateProfileString.o)
    EOS
  end

  fails_with :clang do
    build 421
    cause "sphinxexpr.cpp:1802:11: error: use of undeclared identifier 'ExprEval'"
  end

  def install
    resource("stemmer").stage do
      system "make", "dist_libstemmer_c"
      system "tar", "xzf", "dist/libstemmer_c.tgz", "-C", buildpath
    end

    args = %W[
      --prefix=#{prefix}
      --disable-dependency-tracking
      --localstatedir=#{var}
      --with-libstemmer
    ]

    args << "--enable-id64" if build.with? "id64"
    args << "--with-re2" if build.with? "re2"

    if build.with? "mysql"
      args << "--with-mysql"
    else
      args << "--without-mysql"
    end

    if build.with? "postgresql"
      args << "--with-pgsql"
    else
      args << "--without-pgsql"
    end

    system "./configure", *args
    system "make", "install"
  end

  def caveats; <<-EOS.undent
    This is not sphinx - the Python Documentation Generator.
    To install sphinx-python use pip.

    Sphinx has been compiled with libstemmer support.

    Sphinx depends on either MySQL or PostreSQL as a datasource.

    You can install these with Homebrew with:
      brew install mysql
        For MySQL server.

      brew install mysql-connector-c
        For MySQL client libraries only.

      brew install postgresql
        For PostgreSQL server.

    We don't install these for you when you install this formula, as
    we don't know which datasource you intend to use.
    EOS
  end

  test do
    system bin/"searchd", "--help"
  end
end
