require 'rails_helper'
require_dependency 'plugin/metadata'

describe Plugin::Metadata do
  context "parse" do
    it "correctly parses plugin info" do
      metadata = Plugin::Metadata.parse <<TEXT
# name: plugin-name
# about: about: my plugin
# version: 0.1
# authors: Frank Zappa
# url: http://discourse.org
# required version: 1.3.0beta6+48

some_ruby
TEXT

      expect(metadata.name).to eq("plugin-name")
      expect(metadata.about).to eq("about: my plugin")
      expect(metadata.version).to eq("0.1")
      expect(metadata.authors).to eq("Frank Zappa")
      expect(metadata.url).to eq("http://discourse.org")
      expect(metadata.required_version).to eq("1.3.0beta6+48")
    end
  end

end
