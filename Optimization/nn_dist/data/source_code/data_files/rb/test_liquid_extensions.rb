require "helper"

class TestLiquidExtensions < JekyllUnitTest
  context "looking up a variable in a Liquid context" do
    class SayHi < Liquid::Tag
      include Jekyll::LiquidExtensions

      def initialize(_tag_name, markup, _tokens)
        @markup = markup.strip
      end

      def render(context)
        "hi #{lookup_variable(context, @markup)}"
      end
    end
    Liquid::Template.register_tag("say_hi", SayHi)
    setup do
      # Parses and compiles the template
      @template = Liquid::Template.parse("{% say_hi page.name %}")
    end

    should "extract the var properly" do
      assert_equal @template.render({ "page" => { "name" => "tobi" } }), "hi tobi"
    end

    should "return the variable name if the value isn't there" do
      assert_equal @template.render({ "page" => { "title" => "tobi" } }), "hi page.name"
    end
  end
end
