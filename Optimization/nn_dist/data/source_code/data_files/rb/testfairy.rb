module Fastlane
  module Actions
    module SharedValues
      TESTFAIRY_BUILD_URL = :TESTFAIRY_BUILD_URL
    end

    class TestfairyAction < Action
      def self.run(params)
        require 'shenzhen'
        require 'shenzhen/plugins/testfairy'

        UI.success('Starting with ipa upload to TestFairy...')

        client = Shenzhen::Plugins::TestFairy::Client.new(
          params[:api_key]
        )

        return params[:ipa] if Helper.test?

        metrics_to_client = lambda do |metrics|
          metrics.map do |metric|
            case metric
            when :cpu, :memory, :network, :gps, :battery, :mic, :wifi
              metric.to_s
            when :phone_signal
              'phone-signal'
            else
              UI.user_error!("Unknown metric: #{metric}")
            end
          end
        end

        options_to_client = lambda do |options|
          options.map do |option|
            case option
            when :shake, :anonymous
              option.to_s
            when :video_only_wifi
              'video-only-wifi'
            else
              UI.user_error!("Unknown option: #{option}")
            end
          end
        end

        client_options = Hash[params.values.map do |key, value|
          case key
          when :api_key
            [key, value]
          when :ipa
            [key, value]
          when :symbols_file
            [key, value]
          when :testers_groups
            [key, value.join(',')]
          when :metrics
            [key, metrics_to_client.call(value).join(',')]
          when :icon_watermark
            ['icon-watermark', value]
          when :comment
            [key, value]
          when :auto_update
            ['auto-update', value]
          when :notify
            [key, value]
          when :options
            [key, options_to_client.call(value).join(',')]
          else
            UI.user_error!("Unknown parameter: #{key}")
          end
        end]

        response = client.upload_build(params[:ipa], client_options)
        if parse_response(response)
          UI.success("Build URL: #{Actions.lane_context[SharedValues::TESTFAIRY_BUILD_URL]}")
          UI.success("Build successfully uploaded to TestFairy.")
        else
          UI.user_error!("Error when trying to upload ipa to TestFairy")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.parse_response(response)
        if response.body && response.body.key?('status') && response.body['status'] == 'ok'
          build_url = response.body['build_url']

          Actions.lane_context[SharedValues::TESTFAIRY_BUILD_URL] = build_url

          return true
        else
          UI.error("Error uploading to TestFairy: #{response.body}")

          return false
        end
      end
      private_class_method :parse_response

      def self.description
        'Upload a new build to TestFairy'
      end

      def self.details
        "You can retrieve your API key on [your settings page](https://free.testfairy.com/settings/)"
      end

      def self.available_options
        [
          # required
          FastlaneCore::ConfigItem.new(key: :api_key,
                                       env_name: "FL_TESTFAIRY_API_KEY", # The name of the environment variable
                                       description: "API Key for TestFairy", # a short description of this parameter
                                       verify_block: proc do |value|
                                         UI.user_error!("No API key for TestFairy given, pass using `api_key: 'key'`") unless value.to_s.length > 0
                                       end),
          FastlaneCore::ConfigItem.new(key: :ipa,
                                       env_name: 'TESTFAIRY_IPA_PATH',
                                       description: 'Path to your IPA file. Optional if you use the _gym_ or _xcodebuild_ action',
                                       default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find ipa file at path '#{value}'") unless File.exist?(value)
                                       end),
          # optional
          FastlaneCore::ConfigItem.new(key: :symbols_file,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_SYMBOLS_FILE",
                                       description: "Symbols mapping file",
                                       default_value: Actions.lane_context[SharedValues::DSYM_OUTPUT_PATH],
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find dSYM file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :testers_groups,
                                       optional: true,
                                       type: Array,
                                       short_option: '-g',
                                       env_name: "FL_TESTFAIRY_TESTERS_GROUPS",
                                       description: "Array of tester groups to be notified",
                                       default_value: []), # the default value is an empty list
          FastlaneCore::ConfigItem.new(key: :metrics,
                                       optional: true,
                                       type: Array,
                                       env_name: "FL_TESTFAIRY_METRICS",
                                       description: "Array of metrics to record (cpu,memory,network,phone_signal,gps,battery,mic,wifi)",
                                       default_value: []),
          # max-duration
          # video
          # video-quality
          # video-rate
          FastlaneCore::ConfigItem.new(key: :icon_watermark,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_ICON_WATERMARK",
                                       description: "Add a small watermark to app icon",
                                       default_value: 'off'),
          FastlaneCore::ConfigItem.new(key: :comment,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_COMMENT",
                                       description: "Additional release notes for this upload. This text will be added to email notifications",
                                       default_value: 'No comment provided'), # the default value if the user didn't provide one
          FastlaneCore::ConfigItem.new(key: :auto_update,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_AUTO_UPDATE",
                                       description: "Allows easy upgrade of all users to current version",
                                       default_value: 'off'),
          # not well documented
          FastlaneCore::ConfigItem.new(key: :notify,
                                       optional: true,
                                       env_name: "FL_TESTFAIRY_NOTIFY",
                                       description: "Send email to testers",
                                       default_value: 'off'),
          FastlaneCore::ConfigItem.new(key: :options,
                                       optional: true,
                                       type: Array,
                                       env_name: "FL_TESTFAIRY_OPTIONS",
                                       description: "Array of options (shake,video_only_wifi,anonymous)",
                                       default_value: [])
        ]
      end

      def self.example_code
        [
          'testfairy(
            api_key: "...",
            ipa: "./ipa_file.ipa",
            comment: "Build #{lane_context[SharedValues::BUILD_NUMBER]}",
          )'
        ]
      end

      def self.category
        :beta
      end

      def self.output
        [
          ['TESTFAIRY_BUILD_URL', 'URL of the newly uploaded build']
        ]
      end

      def self.authors
        ["taka0125", "tcurdt"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
