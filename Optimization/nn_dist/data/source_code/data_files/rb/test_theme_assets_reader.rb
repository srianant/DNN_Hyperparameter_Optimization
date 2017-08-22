require "helper"

class TestThemeAssetsReader < JekyllUnitTest
  def setup
    @site = fixture_site(
      "theme"       => "test-theme",
      "theme-color" => "black"
    )
    assert @site.theme
  end

  def assert_file_with_relative_path(haystack, relative_path)
    assert haystack.any? { |f|
      f.relative_path == relative_path
    }, "Site should read in the #{relative_path} file, " \
      "but it was not found in #{haystack.inspect}"
  end

  def refute_file_with_relative_path(haystack, relative_path)
    refute haystack.any? { |f|
      f.relative_path == relative_path
    }, "Site should not have read in the #{relative_path} file, " \
      "but it was found in #{haystack.inspect}"
  end

  context "with a valid theme" do
    should "read all assets" do
      @site.reset
      ThemeAssetsReader.new(@site).read
      assert_file_with_relative_path @site.static_files, "assets/img/logo.png"
      assert_file_with_relative_path @site.pages, "assets/style.scss"
    end

    should "convert pages" do
      @site.process

      file = @site.pages.find { |f| f.relative_path == "assets/style.scss" }
      refute_nil file
      assert_equal @site.in_dest_dir("assets/style.css"), file.destination(@site.dest)
      assert_includes file.output, ".sample {\n  color: black; }"
    end

    should "not overwrite site content with the same relative path" do
      @site.reset
      @site.read

      file = @site.pages.find { |f| f.relative_path == "assets/application.coffee" }
      refute_nil file
      assert_includes file.content, "alert \"From your site.\""
    end
  end

  context "with a valid theme without an assets dir" do
    should "not read any assets" do
      site = fixture_site("theme" => "test-theme")
      allow(site.theme).to receive(:assets_path).and_return(nil)
      ThemeAssetsReader.new(site).read
      refute_file_with_relative_path site.static_files, "assets/img/logo.png"
      refute_file_with_relative_path site.pages, "assets/style.scss"
    end
  end

  context "with no theme" do
    should "not read any assets" do
      site = fixture_site("theme" => nil)
      ThemeAssetsReader.new(site).read
      refute_file_with_relative_path site.static_files, "assets/img/logo.png"
      refute_file_with_relative_path site.pages, "assets/style.scss"
    end
  end
end
