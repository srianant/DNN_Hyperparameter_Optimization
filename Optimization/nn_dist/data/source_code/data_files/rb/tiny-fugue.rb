class TinyFugue < Formula
  desc "Programmable MUD client"
  homepage "http://tinyfugue.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/tinyfugue/tinyfugue/5.0%20beta%208/tf-50b8.tar.gz"
  version "5.0b8"
  sha256 "3750a114cf947b1e3d71cecbe258cb830c39f3186c369e368d4662de9c50d989"

  bottle do
    rebuild 1
    sha256 "f4df3ef186829f13f9f4d5512faf3e65e01eaf14aefd42b0f6895aded918fe79" => :sierra
    sha256 "8b87d1b3de3a1ed16b2c587897c1716b00d011d152476ecdaa922a1406f2846a" => :el_capitan
    sha256 "fbc2ca2d91d2a3bb3df752a98306f7f7f04756870019eb7f72df06a68efa632e" => :yosemite
    sha256 "0d7db7bf7a3744de5cb572c013da516e98b5d6ed911a2f3bf4e0a028a160fd04" => :mavericks
  end

  conflicts_with "tee-clc", :because => "both install a `tf` binary"

  depends_on "libnet"
  depends_on "openssl"
  depends_on "pcre"

  # pcre deprecated pcre_info. Switch to HB pcre-8.31 and pcre_fullinfo.
  # Not reported upstream; project is in stasis since 2007.
  patch :DATA

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-getaddrinfo",
                          "--enable-termcap=ncurses"
    system "make", "install"
  end
end


__END__
--- a/src/malloc.c	2007-01-13 15:12:39.000000000 -0800
+++ b/src/malloc.c	2012-10-26 08:23:30.000000000 -0700
@@ -7,6 +7,7 @@
  ************************************************************************/
 static const char RCSid[] = "$Id: malloc.c,v 35004.22 2007/01/13 23:12:39 kkeys Exp $";
 
+#include "sys/types.h"
 #include "tfconfig.h"
 #include "port.h"
 #include "signals.h"
--- a/src/macro.c	2007-01-13 15:12:39.000000000 -0800
+++ b/src/macro.c	2012-10-26 08:15:31.000000000 -0700
@@ -893,7 +893,8 @@
     }
     spec->attr &= ~F_NONE;
     if (spec->nsubattr) {
-	int n = pcre_info(spec->trig.ri->re, NULL, NULL);
+	int n;
+	pcre_fullinfo(spec->trig.ri->re, NULL, PCRE_INFO_CAPTURECOUNT, &n);
 	for (i = 0; i < spec->nsubattr; i++) {
 	    spec->subattr[i].attr &= ~F_NONE;
 	    if (spec->subattr[i].subexp > n) {
--- a/src/pattern.c	2007-01-13 15:12:39.000000000 -0800
+++ b/src/pattern.c	2012-10-26 08:16:19.000000000 -0700
@@ -151,7 +151,7 @@
 	    emsg ? emsg : "unknown error");
 	goto tf_reg_compile_error;
     }
-    n = pcre_info(ri->re, NULL, NULL);
+    pcre_fullinfo(ri->re, NULL, PCRE_INFO_CAPTURECOUNT, &n);
     if (n < 0) goto tf_reg_compile_error;
     ri->ovecsize = 3 * (n + 1);
     ri->ovector = dmalloc(NULL, sizeof(int) * ri->ovecsize, file, line);
--- a/src/pattern.h	2007-01-13 15:12:39.000000000 -0800
+++ b/src/pattern.h	2012-10-26 08:17:54.000000000 -0700
@@ -10,7 +10,7 @@
 #ifndef PATTERN_H
 #define PATTERN_H
 
-#include "pcre-2.08/pcre.h"
+#include <pcre.h>
 
 typedef struct RegInfo {
     pcre *re;
