module Frameit
  class ConfigParser
    attr_reader :data

    def load(path)
      return nil unless File.exist?(path) # we are okay with no config at all
      UI.verbose("Parsing config file '#{path}'")
      @path = path
      self.parse(File.read(path))
    end

    # @param data (String) the JSON data to be parsed
    def parse(data)
      begin
        @data = JSON.parse(data)
      rescue => ex
        UI.error ex.message
        UI.user_error! "Invalid JSON file at path '#{@path}'. Make sure it's a valid JSON file"
      end

      self
    end

    # Fetches the finished configuration for a given path. This will try to look for a specific value
    # and fallback to a default value if nothing was found
    def fetch_value(path)
      specific = @data['data'].find { |a| path.include? a['filter'] }

      default = @data['default']

      values = default.fastlane_deep_merge(specific || {})

      change_paths_to_absolutes!(values)
      validate_values(values)

      values
    end

    # Use absolute paths instead of relative
    def change_paths_to_absolutes!(values)
      values.each do |key, value|
        if value.kind_of? Hash
          change_paths_to_absolutes!(value) # recursive call
        elsif value.kind_of? Array
          value.each do |current|
            change_paths_to_absolutes!(current) if current.kind_of? Hash # recursive call
          end
        else
          if ['font', 'background'].include? key
            # Change the paths to relative ones
            # `replace`: to change the content of the string, so it's actually stored
            if @path # where is the config file. We don't have a config file in tests
              containing_folder = File.expand_path('..', @path)
              value.replace File.join(containing_folder, value)
            end
          end
        end
      end
    end

    # Make sure the paths/colors are valid
    def validate_values(values)
      values.each do |key, value|
        if value.kind_of?(Hash)
          validate_values(value) # recursive call
        else
          if key == 'font'
            UI.user_error!("Could not find font at path '#{File.expand_path(value)}'") unless File.exist?(value)
          end

          if key == 'fonts'
            UI.user_error!("`fonts` must be an array") unless value.kind_of?(Array)

            value.each do |current|
              UI.user_error!("You must specify a font path") if current.fetch('font', '').length == 0
              UI.user_error!("Could not find font at path '#{File.expand_path(current.fetch('font'))}'") unless File.exist?(current.fetch('font'))
              UI.user_error!("`supported` must be an array") unless current.fetch('supported', []).kind_of? Array
            end
          end

          if key == 'background'
            UI.user_error!("Could not find background image at path '#{File.expand_path(value)}'") unless File.exist? value
          end

          if key == 'color'
            UI.user_error!("Invalid color '#{value}'. Must be valid Hex #123123") unless value.include?("#")
          end

          if key == 'padding'
            unless value.kind_of?(Integer) || value.split('x').length == 2
              UI.user_error!("padding must be type integer or pair of integers of format 'AxB'")
            end
          end
        end
      end
    end
  end
end
