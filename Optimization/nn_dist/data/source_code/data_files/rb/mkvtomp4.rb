class Mkvtomp4 < Formula
  desc "Convert mkv files to mp4"
  homepage "https://github.com/gavinbeatty/mkvtomp4/"
  url "https://github.com/gavinbeatty/mkvtomp4/archive/mkvtomp4-v1.3.tar.gz"
  sha256 "cc644b9c0947cf948c1b0f7bbf132514c6f809074ceed9edf6277a8a1b81c87a"
  revision 1

  bottle do
    cellar :any_skip_relocation
    sha256 "4c085a7e2cbfada2a722dc1d676fab80dacc1f490c14d2a2aff10a4fa60f5225" => :sierra
    sha256 "f7610334538d3e3df8cfeab0a5cd7d9a44acfb141212b4852e340064657e50a8" => :el_capitan
    sha256 "7ae6b5351e551f6f04811cc5b963fd67adc18132f9b4dc91fc07886f05b0d10f" => :yosemite
    sha256 "3346ab8be87d01200616db3887ed05d0d6693d2003ca4c3d5530c439ef732544" => :mavericks
  end

  depends_on "gpac"
  depends_on "ffmpeg" => :recommended
  depends_on "mkvtoolnix"
  depends_on :python if MacOS.version <= :snow_leopard

  def install
    ENV["PYTHONPATH"] = lib+"python2.7/site-packages"
    ENV.prepend_create_path "PYTHONPATH", lib+"python2.7/site-packages"

    system "make"
    system "python", "setup.py", "install", "--prefix=#{prefix}"

    bin.install "mkvtomp4.py" => "mkvtomp4"
    bin.env_script_all_files(libexec+"bin", :PYTHONPATH => ENV["PYTHONPATH"])
  end

  test do
    system "#{bin}/mkvtomp4", "--help"
  end
end
