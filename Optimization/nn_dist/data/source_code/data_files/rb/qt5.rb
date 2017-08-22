class OracleHomeVarRequirement < Requirement
  fatal true
  satisfy(:build_env => false) { ENV["ORACLE_HOME"] }

  def message; <<-EOS.undent
      To use --with-oci you have to set the ORACLE_HOME environment variable.
      Check Oracle Instant Client documentation for more information.
    EOS
  end
end

# Patches for Qt5 must be at the very least submitted to Qt's Gerrit codereview
# rather than their bug-report Jira. The latter is rarely reviewed by Qt.
class Qt5 < Formula
  desc "Version 5 of the Qt framework"
  homepage "https://www.qt.io/"
  head "https://code.qt.io/qt/qt5.git", :branch => "5.7", :shallow => false

  # Remove stable patches for > 5.7.0
  stable do
    url "https://download.qt.io/official_releases/qt/5.7/5.7.0/single/qt-everywhere-opensource-src-5.7.0.tar.xz"
    mirror "https://www.mirrorservice.org/sites/download.qt-project.org/official_releases/qt/5.7/5.7.0/single/qt-everywhere-opensource-src-5.7.0.tar.xz"
    sha256 "a6a2632de7e44bbb790bc3b563f143702c610464a7f537d02036749041fd1800"

    # Upstream commit from 7 Jul 2016 "configure and mkspecs: Don't try to find xcrun with xcrun"
    # http://code.qt.io/cgit/qt/qtbase.git/patch/configure?id=77a71c32c9d19b87f79b208929e71282e8d8b5d9
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/d3d0da3/qt5/xcrun-xcode-8.patch"
      sha256 "14f5a899108e9207bd5c2128f5f628d4e2d2a5e0c2ba0a401ec7b54f5ddcf677"
    end

    # Upstream commit from 3 Oct 2016 "Fixed build with MaxOSX10.12 SDK"
    # http://code.qt.io/cgit/qt/qtconnectivity.git/commit/?h=5.6&id=462323dba4f963844e8c9911da27a0d21e4abf43
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/04c2de3/qt5/qtconnectivity-bluetooth-fix.diff"
      sha256 "41fd73cba0018180015c2be191d63b3c33289f19132c136f482f5c7477620931"
    end

    # Upstream commit from 4 Aug 2016 "Fixes parallel builds where they were
    # sometimes failing on macOS with static builds."
    # http://code.qt.io/cgit/qt/qt3d.git/commit/src/src.pro?id=db3baec236841f9390e9450772838cb7ba878069
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/b13bde3/qt5/qt3d-parallel-build-fix.patch"
      sha256 "dacb69f4e2eac7656f6120f16c4c703b793b36b486efa43ccb182d57e83089b0"
    end

    # Upstream commit from 1 Aug 2016 "BASELINE: Update Chromium to 53.0.2785.41"
    # http://code.qt.io/cgit/qt/qtwebengine-chromium.git/commit/chromium/base/mac/sdk_forward_declarations.h?h=53-based&id=28b1110370900897ab652cb420c371fab8857ad4
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/59db922/qt5/qtwebengine-bluetooth-fix.diff"
      sha256 "af0bf77c10ea2be3010cee842c327018b997517784036991297eee4397354fa2"
    end

    # Equivalent to upstream commit from 4 Oct 2016 "Fix CUPS compilation error in macOS 10.12"
    # http://code.qt.io/cgit/qt/qtwebengine-chromium.git/commit/chromium/printing/backend/print_backend_cups.cc?h=53-based&id=3bd01037ab73b3ffbf4abbf97c54443a91b2fc4d
    # https://codereview.chromium.org/2248343002
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/34a4ad8/qt5/cups-sierra.patch"
      sha256 "63b5f37d694d0bd1db6d586d98f3c551239dc8818588f3b90dc75dfe6e9952be"
    end
  end

  bottle do
    sha256 "4be3f39a46f38bd596d2198b3535a4329072b6dc3e75717a0fcf23d392b84ed0" => :sierra
    sha256 "3085e765270fbae1df00a0a56df1e287234345cd5532cb54dafd991463813868" => :el_capitan
    sha256 "17bec6a0f29a0fb74c3dd8d7b8e45cb50a10b0b6860bca5f54590e04cbf7e48b" => :yosemite
  end

  keg_only "Qt 5 conflicts Qt 4"

  option "with-docs", "Build documentation"
  option "with-examples", "Build examples"
  option "with-oci", "Build with Oracle OCI plugin"
  option "with-qtwebkit", "Build with QtWebkit module"
  option "without-webengine", "Build without QtWebEngine module"

  deprecated_option "qtdbus" => "with-dbus"
  deprecated_option "with-d-bus" => "with-dbus"

  # OS X 10.7 Lion is still supported in Qt 5.5, but is no longer a reference
  # configuration and thus untested in practice. Builds on OS X 10.7 have been
  # reported to fail: <https://github.com/Homebrew/homebrew/issues/45284>.
  depends_on :macos => :mountain_lion

  depends_on "dbus" => :optional
  depends_on :mysql => :optional
  depends_on :postgresql => :optional
  depends_on :xcode => :build

  depends_on OracleHomeVarRequirement if build.with? "oci"

  # http://lists.qt-project.org/pipermail/development/2016-March/025358.html
  resource "qt-webkit" do
    url "https://download.qt.io/community_releases/5.7/5.7.0/qtwebkit-opensource-src-5.7.0.tar.xz"
    sha256 "c7a3253cbf8e6035c54c3b08d8a9457bd82efbce71d4b363c8f753fd07bd34df"
  end

  # Restore `.pc` files for framework-based build of Qt 5 on OS X. This
  # partially reverts <https://codereview.qt-project.org/#/c/140954/> merged
  # between the 5.5.1 and 5.6.0 releases. (Remove this as soon as feasible!)
  #
  # Core formulae known to fail without this patch (as of 2016-10-15):
  #   * gnuplot  (with `--with-qt5` option)
  #   * mkvtoolnix (with `--with-qt5` option, silent build failure)
  #   * poppler    (with `--with-qt5` option)
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/e8fe6567/qt5/restore-pc-files.patch"
    sha256 "48ff18be2f4050de7288bddbae7f47e949512ac4bcd126c2f504be2ac701158b"
  end

  def install
    args = %W[
      -verbose
      -prefix #{prefix}
      -release
      -opensource -confirm-license
      -system-zlib
      -qt-libpng
      -qt-libjpeg
      -qt-freetype
      -qt-pcre
      -nomake tests
      -no-rpath
    ]

    args << "-nomake" << "examples" if build.without? "examples"

    args << "-plugin-sql-mysql" if build.with? "mysql"
    args << "-plugin-sql-psql" if build.with? "postgresql"

    if build.with? "dbus"
      dbus_opt = Formula["dbus"].opt_prefix
      args << "-I#{dbus_opt}/lib/dbus-1.0/include"
      args << "-I#{dbus_opt}/include/dbus-1.0"
      args << "-L#{dbus_opt}/lib"
      args << "-ldbus-1"
      args << "-dbus-linked"
    else
      args << "-no-dbus"
    end

    if build.with? "oci"
      args << "-I#{ENV["ORACLE_HOME"]}/sdk/include"
      args << "-L#{ENV["ORACLE_HOME"]}"
      args << "-plugin-sql-oci"
    end

    args << "-skip" << "qtwebengine" if build.without? "webengine"

    if build.with? "qtwebkit"
      (buildpath/"qtwebkit").install resource("qt-webkit")
      inreplace ".gitmodules", /.*status = obsolete\n((\s*)project = WebKit\.pro)/, "\\1\n\\2initrepo = true"
    end

    system "./configure", *args
    system "make"
    ENV.j1
    system "make", "install"

    if build.with? "docs"
      system "make", "docs"
      system "make", "install_docs"
    end

    # Some config scripts will only find Qt in a "Frameworks" folder
    frameworks.install_symlink Dir["#{lib}/*.framework"]

    # The pkg-config files installed suggest that headers can be found in the
    # `include` directory. Make this so by creating symlinks from `include` to
    # the Frameworks' Headers folders.
    Pathname.glob("#{lib}/*.framework/Headers") do |path|
      include.install_symlink path => path.parent.basename(".framework")
    end

    # configure saved PKG_CONFIG_LIBDIR set up by superenv; remove it
    # see: https://github.com/Homebrew/homebrew/issues/27184
    inreplace prefix/"mkspecs/qconfig.pri",
              /\n# pkgconfig\n(PKG_CONFIG_(SYSROOT_DIR|LIBDIR) = .*\n){2}\n/,
              "\n"

    # Move `*.app` bundles into `libexec` to expose them to `brew linkapps` and
    # because we don't like having them in `bin`. Also add a `-qt5` suffix to
    # avoid conflict with the `*.app` bundles provided by the `qt` formula.
    # (Note: This move/rename breaks invocation of Assistant via the Help menu
    # of both Designer and Linguist as that relies on Assistant being in `bin`.)
    libexec.mkpath
    Pathname.glob("#{bin}/*.app") do |app|
      mv app, libexec/"#{app.basename(".app")}-qt5.app"
    end
  end

  def caveats; <<-EOS.undent
    We agreed to the Qt opensource license for you.
    If this is unacceptable you should uninstall.
    EOS
  end

  test do
    (testpath/"hello.pro").write <<-EOS.undent
      QT       += core
      QT       -= gui
      TARGET = hello
      CONFIG   += console
      CONFIG   -= app_bundle
      TEMPLATE = app
      SOURCES += main.cpp
    EOS

    (testpath/"main.cpp").write <<-EOS.undent
      #include <QCoreApplication>
      #include <QDebug>

      int main(int argc, char *argv[])
      {
        QCoreApplication a(argc, argv);
        qDebug() << "Hello World!";
        return 0;
      }
    EOS

    system bin/"qmake", testpath/"hello.pro"
    system "make"
    assert File.exist?("hello")
    assert File.exist?("main.o")
    system "./hello"
  end
end
