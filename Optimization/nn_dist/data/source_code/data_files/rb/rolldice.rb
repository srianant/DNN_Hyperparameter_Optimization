class Rolldice < Formula
  desc "Rolls an amount of virtual dice"
  homepage "https://github.com/sstrickl/rolldice"
  url "https://github.com/sstrickl/rolldice/archive/v1.16.tar.gz"
  sha256 "8bc82b26c418453ef0fe79b43a094641e7a76dae406032423a2f0fb270930775"

  bottle do
    cellar :any_skip_relocation
    sha256 "a7019dfc0a37c4cb814f8d116140b9fac999d6d97e6650e0806c02cb633087fb" => :sierra
    sha256 "3ee6afe89723d119075feffe735f4b4d4552d51bab5d79df6b8e100f90d21109" => :el_capitan
    sha256 "9525132a3c9a1b1ac679102a2a2f39e51dcd1f2ae299a1038701bdf4f945bd4c" => :yosemite
  end

  def install
    system "make", "CC=#{ENV.cc}"
    bin.install "rolldice"
    man6.install gzip("rolldice.6")
  end

  test do
    assert_match "Roll #1", shell_output("#{bin}/rolldice -s 1x2d6")
  end
end
