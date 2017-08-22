module Spaceship
  module Tunes
    # Represents a geo json
    class TransitAppFile < TunesBase
      attr_accessor :asset_token

      attr_accessor :name

      attr_accessor :time_stamp

      attr_accessor :url

      attr_mapping(
        'assetToken' => :asset_token,
        'timeStemp' => :time_stamp,
        'url' => :url,
        'name' => :name
      )

      class << self
        def factory(attrs)
          self.new(attrs)
        end
      end
    end
  end
end
