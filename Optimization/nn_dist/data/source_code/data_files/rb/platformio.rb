class Platformio < Formula
  include Language::Python::Virtualenv

  desc "Ecosystem for IoT development (Arduino and ARM mbed compatible)"
  homepage "http://platformio.org"
  url "https://pypi.python.org/packages/b1/16/b74f0d085932905149118119aef58525bdb9b0f24e28bf25550b70581794/platformio-3.1.0.tar.gz"
  sha256 "6fc9e4c9a7b8271156daa3095b1efaba7940547e663f16e68f55f77247211c09"

  bottle do
    cellar :any_skip_relocation
    sha256 "e44b569b3f006c84b48f6ce29df065f2b4da9e7f10e4a04ee396be217c697e4a" => :sierra
    sha256 "281045c64b2a1d48854577781d9f72039196794b6900d82c35d5bee0fca594ea" => :el_capitan
    sha256 "55c116597881c9f59bdfcdfe3a36d939a86c3587ea03cbf4ca1cd9ab09600676" => :yosemite
  end

  depends_on :python if MacOS.version <= :snow_leopard

  resource "setuptools" do
    url "https://files.pythonhosted.org/packages/32/3c/e853a68b703f347f5ed86585c2dd2828a83252e1216c1201fa6f81270578/setuptools-26.1.1.tar.gz"
    sha256 "475ce28993d7cb75335942525b9fac79f7431a7f6e8a0079c0f2680641379481"
  end

  resource "bottle" do
    url "https://files.pythonhosted.org/packages/d2/59/e61e3dc47ed47d34f9813be6d65462acaaba9c6c50ec863db74101fa8757/bottle-0.12.9.tar.gz"
    sha256 "fe0a24b59385596d02df7ae7845fe7d7135eea73799d03348aeb9f3771500051"
  end

  resource "click" do
    url "https://files.pythonhosted.org/packages/b7/34/a496632c4fb6c1ee76efedf77bb8d28b29363d839953d95095b12defe791/click-5.1.tar.gz"
    sha256 "678c98275431fad324275dec63791e4a17558b40e5a110e20a82866139a85a5a"
  end

  resource "colorama" do
    url "https://files.pythonhosted.org/packages/f0/d0/21c6449df0ca9da74859edc40208b3a57df9aca7323118c913e58d442030/colorama-0.3.7.tar.gz"
    sha256 "e043c8d32527607223652021ff648fbb394d5e19cba9f1a698670b338c9d782b"
  end

  resource "lockfile" do
    url "https://files.pythonhosted.org/packages/17/47/72cb04a58a35ec495f96984dddb48232b551aafb95bde614605b754fe6f7/lockfile-0.12.2.tar.gz"
    sha256 "6aed02de03cba24efabcd600b30540140634fc06cfa603822d508d5361e9f799"
  end

  resource "pyserial" do
    url "https://files.pythonhosted.org/packages/3c/d8/a9fa247ca60b02b3bebbd61766b4f321393b57b13c53b18f6f62cf172c08/pyserial-3.1.1.tar.gz"
    sha256 "d657051249ce3cbd0446bcfb2be07a435e1029da4d63f53ed9b4cdde7373364c"
  end

  resource "requests" do
    url "https://files.pythonhosted.org/packages/2e/ad/e627446492cc374c284e82381215dcd9a0a87c4f6e90e9789afefe6da0ad/requests-2.11.1.tar.gz"
    sha256 "5acf980358283faba0b897c73959cecf8b841205bb4b2ad3ef545f46eae1a133"
  end

  resource "semantic_version" do
    url "https://files.pythonhosted.org/packages/8e/0e/33052dd97ab9d07dae8ddffcfb2740efe58c46d72efbc060cf6da250439f/semantic_version-2.5.0.tar.gz"
    sha256 "3baad35dcb074a49419539cea6a33b484706b6c2dd03f05b67763eba4c1bb65c"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    system bin/"platformio"
    system bin/"pio"
  end
end
