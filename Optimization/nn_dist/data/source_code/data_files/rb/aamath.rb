class Aamath < Formula
  desc "Renders mathematical expressions as ASCII art"
  homepage "http://fuse.superglue.se/aamath/"
  url "http://fuse.superglue.se/aamath/aamath-0.3.tar.gz"
  sha256 "9843f4588695e2cd55ce5d8f58921d4f255e0e65ed9569e1dcddf3f68f77b631"

  bottle do
    cellar :any_skip_relocation
    sha256 "d537cb11d2dcbac9b5d5356c471775699312e83450635ba7676083f381a531cd" => :sierra
    sha256 "8b805e37fd5f4536b4fbf7f3ae6251b645b4b132027d56ccd015a6036c304744" => :el_capitan
    sha256 "1e22022e621e7d2337edf4a80ae2c1618a89089132656d85cc141774565e34d7" => :yosemite
    sha256 "0212e0b5844ea1a491bc7d4fcab2b590921042b28bc50e79c36cd9e15d08e2aa" => :mavericks
  end

  # Fix build on clang; patch by Homebrew team
  # https://github.com/Homebrew/homebrew/issues/23872
  patch :DATA

  def install
    ENV.j1
    system "make"

    bin.install "aamath"
    man1.install "aamath.1"
    prefix.install "testcases"
  end

  test do
    s = pipe_output("#{bin}/aamath", (prefix/"testcases").read)
    assert_match /#{Regexp.escape("f(x + h) = f(x) + h f'(x)")}/, s
  end
end

__END__
diff --git a/expr.cc b/expr.cc
index 7bc0ee3..8f4eaf7 100644
--- a/expr.cc
+++ b/expr.cc
@@ -1192,7 +1192,7 @@ IntegralOnInterval::render_head() const
 
 class SumSymbol : public OpSymbol {
   public:
-	void render(Canvas& c, int r, int c) const;
+	void render(Canvas& canvas, int r, int c) const;
 };
 
 void
@@ -1208,7 +1208,7 @@ SumSymbol::render(Canvas& canvas, int r, int c) const
 
 class ProductSymbol : public OpSymbol {
   public:
-	void render(Canvas& c, int r, int c) const;
+	void render(Canvas& canvas, int r, int c) const;
 };
 
 void
@@ -1612,7 +1612,7 @@ Matrix::render() const
 	int cols = num_cols();
 	int rows = num_rows();
 
-	CanvasPtr ec[cols * rows];
+	CanvasPtr *ec = new CanvasPtr[cols * rows];
 	Size sz[cols * rows];
 
 	int row_height[rows];
@@ -1692,6 +1692,8 @@ Matrix::render() const
 
 	canvas->center();
 
+    delete[] ec;
+
 	return canvas;
 }
 
diff --git a/expr.h b/expr.h
index 000ebd4..d233da9 100644
--- a/expr.h
+++ b/expr.h
@@ -451,7 +451,7 @@ class Integral : public OpOnFunction {
 
 	virtual CanvasPtr render_head() const;
 
-	void render_symbol(Canvas& c, int r, int c, int h) const;
+	void render_symbol(Canvas& canvas, int r, int c, int h) const;
 
 	virtual CanvasPtr render() const;
 };
@@ -467,7 +467,7 @@ class IntegralOnInterval : public Integral, public OpOverInterval {
 
 class OpSymbol {
   public:
-	virtual void render(Canvas& c, int r, int c) const = 0;
+	virtual void render(Canvas& canvas, int r, int c) const = 0;
 };
 
 class SumOrProduct : public OpOnFunction {
