class Pwsafe < Formula
  desc "Generate passwords and manage encrypted password databases"
  homepage "http://nsd.dyndns.org/pwsafe/"
  url "http://nsd.dyndns.org/pwsafe/releases/pwsafe-0.2.0.tar.gz"
  sha256 "61e91dc5114fe014a49afabd574eda5ff49b36c81a6d492c03fcb10ba6af47b7"
  revision 2

  bottle do
    cellar :any
    sha256 "2e8928d27de84dac239832ba22f66ebbc85d14ac8c420f5971db90b407e5781e" => :sierra
    sha256 "124f8d5da3927bf76826f0a3ccfeb59e1fc8674b7f7c8ed4e2b6aed3e86a5263" => :el_capitan
    sha256 "6c8fffd07460664b877c97d00a9507b232d6fae885a29ed5f0842192bee410f4" => :yosemite
  end

  depends_on "openssl"
  depends_on "readline"

  # A password database for testing is provided upstream. How nice!
  resource "test-pwsafe-db" do
    url "http://nsd.dyndns.org/pwsafe/test.dat"
    sha256 "7ecff955871e6e58e55e0794d21dfdea44a962ff5925c2cd0683875667fbcc79"
  end

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--mandir=#{man}"
    system "make", "install"
  end

  test do
    test_db_passphrase = "abc"
    test_account_name = "testing"
    test_account_pass = "sg1rIWHL?WTOV=d#q~DmxiQq%_j-$f__U7EU"

    resource("test-pwsafe-db").stage do
      Utils.popen(
        "#{bin}/pwsafe -f test.dat -p #{test_account_name}", "r+"
      ) do |pipe|
        pipe.puts test_db_passphrase
        assert_match(/^#{Regexp.escape(test_account_pass)}$/, pipe.read)
      end
    end
  end
end
