module Spaceship
  module Tunes
    # Represents an image hosted on iTunes Connect. Used for icons, screenshots, etc
    class AppImage < TunesBase
      HOST_URL = "https://is1-ssl.mzstatic.com/image/thumb"

      attr_accessor :asset_token

      attr_accessor :sort_order

      attr_accessor :original_file_name

      attr_accessor :url

      attr_mapping(
        'assetToken' => :asset_token,
        'sortOrder' => :sort_order,
        'url' => :url,
        'originalFileName' => :original_file_name
      )

      class << self
        def factory(attrs)
          self.new(attrs)
        end
      end

      def reset!(attrs = {})
        update_raw_data!(
          {
            asset_token: nil,
            original_file_name: nil,
            sort_order: nil,
            url: nil
          }.merge(attrs)
        )
      end

      def setup
        # Since September 2015 we don't get the url any more, so we have to manually build it
        self.url = "#{HOST_URL}/#{self.asset_token}/0x0ss.jpg"
      end

      private

      def update_raw_data!(hash)
        hash.each do |k, v|
          self.send("#{k}=", v)
        end
      end
    end
  end
end
