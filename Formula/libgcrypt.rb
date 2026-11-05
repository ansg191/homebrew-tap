class Libgcrypt < Formula
  desc "Cryptographic library based on the code from GnuPG"
  homepage "https://gnupg.org/related_software/libgcrypt/"
  url "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.12.4.tar.bz2"
  sha256 "d77f68f48879510e79a2f65977ccc68981781ea0923e5bdffac2a193ea3d660e"
  license all_of: ["LGPL-2.1-or-later", "GPL-2.0-or-later"]
  compatibility_version 1

  livecheck do
    url "https://gnupg.org/ftp/gcrypt/libgcrypt/"
    regex(/href=.*?libgcrypt[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "libgpg-error"

  patch :DATA

  deny_network_access!

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules",
                          "--enable-static",
                          "--with-libgpg-error-prefix=#{formula_opt_prefix("libgpg-error")}",
                          *std_configure_args

    # The jitter entropy collector must be built without optimisations
    ENV.O0 { system "make", "-C", "random", "rndjent.o", "rndjent.lo" }

    # Parallel builds work, but only when run as separate steps
    system "make"
    system "make", "check"
    system "make", "install"

    # avoid triggering mandatory rebuilds of software that hard-codes this path
    inreplace bin/"libgcrypt-config", prefix, opt_prefix
  end

  test do
    touch "testing"
    output = shell_output("#{bin}/hmac256 \"testing\" testing")
    assert_match "0e824ce7c056c82ba63cc40cffa60d3195b5bb5feccc999a47724cc19211aef6", output
  end
end

__END__
From 2175f338d139eaf875fd4dbc5cc80c25a662520b Mon Sep 17 00:00:00 2001
From: Jussi Kivilinna <jussi.kivilinna@iki.fi>
Date: Thu, 24 Sep 2026 19:39:03 +0300
Subject: [PATCH] aarch64-asm: fix macOS build and enable asm implementations

* build-aux/darwin-aarch64-as.sh: New.
* Makefile.am (EXTRA_DIST): Add 'build-aux/darwin-aarch64-as.sh'.
* cipher/Makefile.am (CLEANFILES): Add '*-darwin.s'.
* mpi/Makefile.am (CLEANFILES): New.
* configure.ac [*-apple-darwin*] (CCAS): Use 'darwin-aarch64-as.sh'
wrapper on macOS AArch64.
(GNUPG_SYS_SYMBOL_UNDERSCORE): Move before assembler checks.
(symbol_prefix): New.
(gcry_cv_gcc_aarch64_platform_as_ok)
(gcry_cv_gcc_inline_asm_aarch64_neon)
(gcry_cv_gcc_inline_asm_aarch64_crypto)
(gcry_cv_gcc_inline_asm_aarch64_sve)
(gcry_cv_gcc_inline_asm_aarch64_sve2)
(gcry_cv_gcc_inline_asm_aarch64_sha3_sha512_sm3_sm4): Add symbol
prefix to test function label.
* acinclude.m4 (GNUPG_SYS_SYMBOL_UNDERSCORE): Set underscore prefix
for AArch64 Darwin.
* cipher/asm-common-aarch64.h [__APPLE__] (SECTION_RODATA): New.
[__APPLE__] (GET_DATA_POINTER): Use '@PAGE' and '@PAGEOFF'.
--

Darwin assembler uses ';' as comment character, so statements after
first ';' in macro expansions were silently dropped. Commit 9b684f4a
added ';' separator in 'CFI_ENDPROC' and then caused macOS builds
fail with "Unfinished frame!" error in mpi/aarch64.

Also AArch64 cipher assembly was never built on macOS as configure
checks failed to link test function because of missing '_' symbol
prefix.

Patch adds assembler wrapper for AArch64 Darwin that is used as CCAS.
Wrapper runs C preprocessor on .S source, splits ';' separated
statements to separate lines, converts '.L' local labels to Darwin
'L' prefix and adds '_' prefix to _gcry symbols, and then assembles
the result. Darwin variant of 'GET_DATA_POINTER' used GOT relocation
with 'add' instruction, which assembler rejects, and 'SECTION_RODATA'
did not have Darwin variant.

Benchmark on Apple M1 Mac Mini:

Hash:
                |  nanosecs/byte   mebibytes/sec   cycles/byte  auto Mhz
 SHA1           |     0.408 ns/B      2336 MiB/s      1.30 c/B      3192
 SHA256         |     0.411 ns/B      2321 MiB/s      1.31 c/B      3192
 SHA512         |     0.693 ns/B      1377 MiB/s      2.21 c/B      3192
                =

Cipher:
 AES            |  nanosecs/byte   mebibytes/sec   cycles/byte  auto Mhz
        ECB enc |     0.077 ns/B     12370 MiB/s     0.246 c/B      3192
        ECB dec |     0.077 ns/B     12307 MiB/s     0.247 c/B      3192
        CBC enc |     0.634 ns/B      1505 MiB/s      2.02 c/B      3192
        CBC dec |     0.076 ns/B     12540 MiB/s     0.243 c/B      3192
        CFB enc |     0.637 ns/B      1498 MiB/s      2.03 c/B      3192
        CFB dec |     0.070 ns/B     13594 MiB/s     0.224 c/B      3192
        OFB enc |     0.751 ns/B      1270 MiB/s      2.40 c/B      3192
        OFB dec |     0.751 ns/B      1269 MiB/s      2.40 c/B      3192
        CTR enc |     0.078 ns/B     12192 MiB/s     0.250 c/B      3192
        CTR dec |     0.078 ns/B     12206 MiB/s     0.249 c/B      3192
        XTS enc |     0.124 ns/B      7714 MiB/s     0.395 c/B      3192
        XTS dec |     0.124 ns/B      7715 MiB/s     0.395 c/B      3192
        CCM enc |     0.710 ns/B      1343 MiB/s      2.27 c/B      3192
        CCM dec |     0.712 ns/B      1339 MiB/s      2.27 c/B      3192
       CCM auth |     0.632 ns/B      1509 MiB/s      2.02 c/B      3192
        EAX enc |     0.712 ns/B      1340 MiB/s      2.27 c/B      3192
        EAX dec |     0.715 ns/B      1334 MiB/s      2.28 c/B      3192
       EAX auth |     0.635 ns/B      1501 MiB/s      2.03 c/B      3192
        GCM enc |     0.180 ns/B      5292 MiB/s     0.575 c/B      3192
        GCM dec |     0.181 ns/B      5278 MiB/s     0.577 c/B      3192
       GCM auth |     0.101 ns/B      9420 MiB/s     0.323 c/B      3192
        OCB enc |     0.074 ns/B     12847 MiB/s     0.237 c/B      3192
        OCB dec |     0.072 ns/B     13155 MiB/s     0.231 c/B      3192
       OCB auth |     0.102 ns/B      9372 MiB/s     0.325 c/B      3192
        SIV enc |     0.713 ns/B      1337 MiB/s      2.28 c/B      3192
        SIV dec |     0.725 ns/B      1315 MiB/s      2.31 c/B      3192
       SIV auth |     0.633 ns/B      1506 MiB/s      2.02 c/B      3192
    GCM-SIV enc |     0.184 ns/B      5191 MiB/s     0.586 c/B      3192
    GCM-SIV dec |     0.191 ns/B      4991 MiB/s     0.610 c/B      3192
   GCM-SIV auth |     0.100 ns/B      9490 MiB/s     0.321 c/B      3192
                =
 CHACHA20       |  nanosecs/byte   mebibytes/sec   cycles/byte  auto Mhz
     STREAM enc |     0.709 ns/B      1346 MiB/s      2.26 c/B      3192
     STREAM dec |     0.708 ns/B      1346 MiB/s      2.26 c/B      3192
   POLY1305 enc |     0.721 ns/B      1322 MiB/s      2.30 c/B      3192
   POLY1305 dec |     0.705 ns/B      1353 MiB/s      2.25 c/B      3192
  POLY1305 auth |     0.291 ns/B      3274 MiB/s     0.930 c/B      3192
                =

GnuPG-bug-id: 8463
Signed-off-by: Jussi Kivilinna <jussi.kivilinna@iki.fi>
---
 Makefile.am                    |   1 +
 acinclude.m4                   |   3 +
 build-aux/darwin-aarch64-as.sh | 114 +++++++++++++++++++++++++++++++++
 cipher/Makefile.am             |   2 +-
 cipher/asm-common-aarch64.h    |   6 +-
 configure.ac                   |  38 +++++++----
 mpi/Makefile.am                |   1 +
 7 files changed, 149 insertions(+), 16 deletions(-)
 create mode 100644 build-aux/darwin-aarch64-as.sh

diff --git a/Makefile.am b/Makefile.am
index f4da0905d..14520bc55 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -49,6 +49,7 @@ EXTRA_DIST = autogen.sh autogen.rc README.GIT LICENSES			   \
 	     m4/ChangeLog-2011 cipher/ChangeLog-2011 src/ChangeLog-2011	   \
 	     random/ChangeLog-2011 tests/ChangeLog-2011 mpi/ChangeLog-2011 \
 	     build-aux/libtool-patch.sed 				   \
+	     build-aux/darwin-aarch64-as.sh				   \
 	     build-aux/git-log-footer build-aux/git-log-fix VERSION
 
 DISTCLEANFILES =
diff --git a/acinclude.m4 b/acinclude.m4
index 43e0e9068..1054d074f 100644
--- a/acinclude.m4
+++ b/acinclude.m4
@@ -73,6 +73,9 @@ case "${host}" in
     i386-emx-os2 | i[3456]86-pc-os2*emx | i386-pc-msdosdjgpp)
         ac_cv_sys_symbol_underscore=yes
         ;;
+    aarch64-apple-darwin*)
+        ac_cv_sys_symbol_underscore=yes
+        ;;
     *)
       if test "$cross_compiling" != yes; then
          tmp_do_check="yes"
diff --git a/build-aux/darwin-aarch64-as.sh b/build-aux/darwin-aarch64-as.sh
new file mode 100644
index 000000000..83f80dcb9
--- /dev/null
+++ b/build-aux/darwin-aarch64-as.sh
@@ -0,0 +1,114 @@
+#!/bin/sh
+# Assembler wrapper for AArch64 Darwin.
+# Copyright (C) 2026 Jussi Kivilinna <jussi.kivilinna@iki.fi>
+#
+# This file is part of Libgcrypt.
+#
+# Libgcrypt is free software; you can redistribute it and/or modify
+# it under the terms of the GNU Lesser General Public License as
+# published by the Free Software Foundation; either version 2.1 of
+# the License, or (at your option) any later version.
+#
+# Libgcrypt is distributed in the hope that it will be useful,
+# but WITHOUT ANY WARRANTY; without even the implied warranty of
+# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
+# GNU Lesser General Public License for more details.
+#
+# You should have received a copy of the GNU Lesser General Public
+# License along with this program; if not, see <http://www.gnu.org/licenses/>.
+
+# Darwin assembler uses ';' as comment character, treats only 'L' prefixed
+# labels as assembler local and C symbols have '_' prefix.
+#
+# Run C preprocessor on the .S source, then split ';' separated
+# statements to separate lines, convert '.L' labels to 'L' and add
+# prefix to _gcry symbols, and assemble the result.
+#
+# Usage: darwin-aarch64-as.sh CC [CCFLAGS...] ARGS...
+
+# Preprocess only: '-c' becomes '-E' and output goes to "$pp".
+run_cpp ()
+{
+  n=$#
+  skip=
+  for a in "$@"; do
+    if test -n "$skip"; then
+      skip=
+      a="$pp"
+    else
+      case "$a" in
+        -c) a=-E ;;
+        -o) skip=1 ;;
+      esac
+    fi
+    set -- "$@" "$a"
+  done
+  shift $n
+  "$@"
+}
+
+# Assemble "$asm" in place of "$src", without dependency generation.
+run_as ()
+{
+  n=$#
+  skip=
+  for a in "$@"; do
+    if test -n "$skip"; then
+      skip=
+      continue
+    fi
+    case "$a" in
+      -MT|-MF|-MQ) skip=1; continue ;;
+      -MD|-MMD|-MP) continue ;;
+      "$src") a="$asm" ;;
+    esac
+    set -- "$@" "$a"
+  done
+  shift $n
+  "$@"
+}
+
+# Find .S source and output object; pass through non-.S compiles as is.
+src=
+out=
+prev=
+for a in "$@"; do
+  case "$prev" in
+    -o) out="$a" ;;
+  esac
+  case "$a" in
+    *.S) src="$a" ;;
+  esac
+  prev="$a"
+done
+
+if test -z "$src"; then
+  exec "$@"
+fi
+
+# Place converted source next to output object, as libtool compiles
+# PIC and non-PIC objects to separate directories.
+base="${src##*/}"
+if test -n "$out"; then
+  asm="$(dirname "$out")/${base%.S}-darwin.s"
+else
+  asm="${base%.S}-darwin.s"
+fi
+pp="$asm.i"
+
+trap 'rm -f "$pp"' EXIT
+
+run_cpp "$@" || exit 1
+
+# Convert to Darwin syntax
+#  * ; separator to newline
+#  * .L local symbol prefix to L
+#  * _gcry_ global symbol prefix to __gcry_
+tr ';' '\n' < "$pp" | \
+  sed -e 's/^\.L/L/' \
+      -e 's/\([^A-Za-z0-9_.]\)\.L/\1L/g' \
+      -e 's/^_gcry_/__gcry_/' \
+      -e 's/\([^A-Za-z0-9_]\)_gcry_/\1__gcry_/g' \
+  > "$asm" || exit 1
+
+run_as "$@"
diff --git a/cipher/Makefile.am b/cipher/Makefile.am
index 0c00d181e..486bd99ed 100644
--- a/cipher/Makefile.am
+++ b/cipher/Makefile.am
@@ -29,7 +29,7 @@ AM_CCASFLAGS = $(NOEXECSTACK_FLAGS)
 EXTRA_DIST = gost-s-box.c kyber-common.c kyber-kdep.c \
              dilithium-common.c dilithium-dep.c
 
-CLEANFILES = gost-s-box$(EXEEXT_FOR_BUILD)
+CLEANFILES = gost-s-box$(EXEEXT_FOR_BUILD) *-darwin.s
 DISTCLEANFILES = gost-sb.h
 
 noinst_LTLIBRARIES = libcipher.la
diff --git a/cipher/asm-common-aarch64.h b/cipher/asm-common-aarch64.h
index ec9b9b920..821eeda54 100644
--- a/cipher/asm-common-aarch64.h
+++ b/cipher/asm-common-aarch64.h
@@ -31,14 +31,16 @@
 
 #ifdef _WIN32
 # define SECTION_RODATA .section .rdata
+#elif defined(__APPLE__)
+# define SECTION_RODATA .section __TEXT,__const
 #else
 # define SECTION_RODATA .section .rodata
 #endif
 
 #ifdef __APPLE__
 #define GET_DATA_POINTER(reg, name) \
-	adrp    reg, name@GOTPAGE ; \
-	add     reg, reg, name@GOTPAGEOFF ;
+	adrp    reg, name@PAGE ; \
+	add     reg, reg, name@PAGEOFF ;
 #else
 #define GET_DATA_POINTER(reg, name) \
 	adrp    reg, name ; \
diff --git a/configure.ac b/configure.ac
index ea7ea7ae8..d9cbf5d26 100644
--- a/configure.ac
+++ b/configure.ac
@@ -297,6 +297,11 @@ case "${host}" in
         AC_DEFINE(USE_POSIX_SPAWN_FOR_TESTS, 1,
                   [defined if we use posix_spawn in test program])
         AC_CHECK_HEADERS(spawn.h)
+
+        if test "$host_cpu" = aarch64; then
+            CCAS="\$(SHELL) \$(top_srcdir)/build-aux/darwin-aarch64-as.sh $CCAS"
+        fi
+
         ;;
 
     *-openedition*)
@@ -874,6 +879,20 @@ AC_TYPE_PID_T
 
 AC_CHECK_TYPES([byte, ushort, u16, u32, u64])
 
+
+#
+# Check whether underscores in symbols are required.  This needs to be
+# done before setting up the assembler stuff.
+#
+GNUPG_SYS_SYMBOL_UNDERSCORE()
+
+if test "$ac_cv_sys_symbol_underscore" = "yes" ; then
+  symbol_prefix=_
+else
+  symbol_prefix=
+fi
+
+
 #
 # Check for __builtin_bswap32 intrinsic.
 #
@@ -1247,7 +1266,7 @@ AC_CACHE_CHECK([whether GCC assembler is compatible for ARMv8/Aarch64 assembly i
           AC_LINK_IFELSE([AC_LANG_PROGRAM(
             [[__asm__(
                 ".text\n\t"
-                "asmfunc:\n\t"
+                "$symbol_prefix" "asmfunc:\n\t"
                 "eor x0, x0, x30, ror #12;\n\t"
                 "add x0, x0, x30, asr #12;\n\t"
                 "eor v0.16b, v0.16b, v31.16b;\n\t"
@@ -1310,13 +1329,6 @@ if test "$gcry_cv_gcc_asm_elf_directives" = "yes" ; then
 fi
 
 
-#
-# Check whether underscores in symbols are required.  This needs to be
-# done before setting up the assembler stuff.
-#
-GNUPG_SYS_SYMBOL_UNDERSCORE()
-
-
 #################################
 ####                         ####
 #### Setup assembler stuff.  ####
@@ -2200,7 +2212,7 @@ AC_CACHE_CHECK([whether GCC inline assembler supports AArch64 NEON instructions]
           [[__asm__(
                 ".cpu generic+simd\n\t"
                 ".text\n\t"
-                "testfn:\n\t"
+                "$symbol_prefix" "testfn:\n\t"
                 "mov w0, \#42;\n\t"
                 "dup v0.8b, w0;\n\t"
                 "ld4 {v0.8b,v1.8b,v2.8b,v3.8b},[x0],\#32;\n\t"
@@ -2229,7 +2241,7 @@ AC_CACHE_CHECK([whether GCC inline assembler supports AArch64 Crypto Extension i
           [[__asm__(
                 ".cpu generic+simd+crypto\n\t"
                 ".text\n\t"
-                "testfn:\n\t"
+                "$symbol_prefix" "testfn:\n\t"
                 "mov w0, \#42;\n\t"
                 "dup v0.8b, w0;\n\t"
                 "ld4 {v0.8b,v1.8b,v2.8b,v3.8b},[x0],\#32;\n\t"
@@ -2278,7 +2290,7 @@ AC_CACHE_CHECK([whether GCC inline assembler supports AArch64 SVE instructions],
           [[__asm__(
                 ".cpu generic+simd+sve\n\t"
                 ".text\n\t"
-                "testfn:\n\t"
+                "$symbol_prefix" "testfn:\n\t"
                 "mov x0, \#60;\n\t"
                 "whilelo p0.s, xzr, x0;\n\t"
                 "mov z0.s, p0/z, \#55;\n\t"
@@ -2308,7 +2320,7 @@ AC_CACHE_CHECK([whether GCC inline assembler supports AArch64 SVE2 instructions]
           [[__asm__(
                 ".cpu generic+simd+sve2\n\t"
                 ".text\n\t"
-                "testfn:\n\t"
+                "$symbol_prefix" "testfn:\n\t"
                 ";\n\t"
                 "eor3 z0.d, z0.d, z1.d, z2.d;\n\t"
                 "ext z8.b, {z20.b, z21.b}, \#3;\n\t"
@@ -2342,7 +2354,7 @@ AC_CACHE_CHECK([whether GCC inline assembler supports AArch64 SHA3/SHA512/SM3/SM
           [[__asm__(
                 ".arch armv8.2-a+sha3+sm4\n\t"
                 ".text\n\t"
-                "testfn:\n\t"
+                "$symbol_prefix" "testfn:\n\t"
 
                 /* Test for SHA512 instructions */
                 "sha512h q0, q0, v0.2d;\n\t"
diff --git a/mpi/Makefile.am b/mpi/Makefile.am
index a7268e2ba..960a73add 100644
--- a/mpi/Makefile.am
+++ b/mpi/Makefile.am
@@ -30,6 +30,7 @@ AM_ASFLAGS = $(MPI_SFLAGS)
 AM_CCASFLAGS = $(NOEXECSTACK_FLAGS)
 
 EXTRA_DIST = config.links
+CLEANFILES = *-darwin.s
 DISTCLEANFILES = mpi-asm-defs.h \
                  mpih-add1-asm.S mpih-mul1-asm.S mpih-mul2-asm.S mpih-mul3-asm.S  \
 		 mpih-lshift-asm.S mpih-rshift-asm.S mpih-sub1-asm.S asm-syntax.h \

