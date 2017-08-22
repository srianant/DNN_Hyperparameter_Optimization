require 'rails_helper'

describe ColorScheme do

  let(:valid_params) { {name: "Best Colors Evar", enabled: true, colors: valid_colors} }
  let(:valid_colors) { [
    {name: '$primary_background_color', hex: 'FFBB00'},
    {name: '$secondary_background_color', hex: '888888'}
  ]}

  describe "new" do
    it "can take colors" do
      c = described_class.new(valid_params)
      expect(c.colors.size).to eq valid_colors.size
      expect(c.colors.first).to be_a(ColorSchemeColor)
      expect {
        expect(c.save).to eq true
      }.to change { ColorSchemeColor.count }.by(valid_colors.size)
    end
  end

  describe "create_from_base" do
    let(:base_colors) { {first_one: 'AAAAAA', second_one: '333333', third_one: 'BEEBEE'} }
    let!(:base) { Fabricate(:color_scheme, name: 'Base', color_scheme_colors: [
                    Fabricate(:color_scheme_color, name: 'first_one',  hex: base_colors[:first_one]),
                    Fabricate(:color_scheme_color, name: 'second_one', hex: base_colors[:second_one]),
                    Fabricate(:color_scheme_color, name: 'third_one', hex: base_colors[:third_one])]) }

    before do
      described_class.stubs(:base).returns(base)
    end

    it "creates a new color scheme" do
      c = described_class.create_from_base(name: 'Yellow', colors: {first_one: 'FFFF00', third_one: 'F00D33'})
      expect(c.colors.size).to eq base_colors.size
      first  = c.colors.find {|x| x.name == 'first_one'}
      second = c.colors.find {|x| x.name == 'second_one'}
      third  = c.colors.find {|x| x.name == 'third_one'}
      expect(first.hex).to eq 'FFFF00'
      expect(second.hex).to eq base_colors[:second_one]
      expect(third.hex).to eq 'F00D33'
    end

    context "hex_for_name without anything enabled" do
      before do
        ColorScheme.hex_cache.clear
      end

      it "returns nil for a missing attribute" do
        expect(described_class.hex_for_name('undefined')).to eq nil
      end

      it "returns the base color for an attribute" do
        expect(described_class.hex_for_name('second_one')).to eq base_colors[:second_one]
      end
    end
  end

  describe "destroy" do
    it "also destroys old versions" do
      c1 = described_class.create(valid_params.merge(version: 2))
      _c2 = described_class.create(valid_params.merge(versioned_id: c1.id, version: 1))
      _other = described_class.create(valid_params)
      expect {
        c1.destroy
      }.to change { described_class.count }.by(-2)
    end
  end

  describe "#enabled" do
    it "returns nil when there is no enabled record" do
      expect(described_class.enabled).to eq nil
    end

    it "returns the enabled color scheme" do
      ColorScheme.hex_cache.clear
      expect(described_class.hex_for_name('$primary_background_color')).to eq nil
      c = described_class.create(valid_params.merge(enabled: true))
      expect(described_class.enabled.id).to eq c.id
      expect(described_class.hex_for_name('$primary_background_color')).to eq "FFBB00"
    end
  end
end
