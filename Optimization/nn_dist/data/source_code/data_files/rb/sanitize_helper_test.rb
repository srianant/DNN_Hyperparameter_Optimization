require "abstract_unit"

# The exhaustive tests are in test/controller/html/sanitizer_test.rb.
# This tests that the helpers hook up correctly to the sanitizer classes.
class SanitizeHelperTest < ActionView::TestCase
  tests ActionView::Helpers::SanitizeHelper

  def test_strip_links
    assert_equal "Dont touch me", strip_links("Dont touch me")
    assert_equal "on my mind\nall day long", strip_links("<a href='almost'>on my mind</a>\n<A href='almost'>all day long</A>")
    assert_equal "Magic", strip_links("<a href='http://www.rubyonrails.com/'>Mag<a href='http://www.ruby-lang.org/'>ic")
    assert_equal "My mind\nall <b>day</b> long", strip_links("<a href='almost'>My mind</a>\n<A href='almost'>all <b>day</b> long</A>")
  end

  def test_sanitize_form
    assert_equal "", sanitize("<form action=\"/foo/bar\" method=\"post\"><input></form>")
  end

  def test_should_sanitize_illegal_style_properties
    raw      = %(display:block; position:absolute; left:0; top:0; width:100%; height:100%; z-index:1; background-color:black; background-image:url(http://www.ragingplatypus.com/i/cam-full.jpg); background-x:center; background-y:center; background-repeat:repeat;)
    expected = %(display: block; width: 100%; height: 100%; background-color: black; background-x: center; background-y: center;)
    assert_equal expected, sanitize_css(raw)
  end

  def test_strip_tags
    assert_equal("Dont touch me", strip_tags("Dont touch me"))
    assert_equal("This is a test.", strip_tags("<p>This <u>is<u> a <a href='test.html'><strong>test</strong></a>.</p>"))
    assert_equal "This has a  here.", strip_tags("This has a <!-- comment --> here.")
    assert_equal "", strip_tags("<script>")
  end

  def test_strip_tags_will_not_encode_special_characters
    assert_equal "test\r\n\r\ntest", strip_tags("test\r\n\r\ntest")
  end

  def test_sanitize_is_marked_safe
    assert sanitize("<html><script></script></html>").html_safe?
  end
end
