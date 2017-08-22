require 'credentials_manager'

module Fastlane
  module Actions
    module SharedValues
      LATEST_TESTFLIGHT_BUILD_NUMBER = :LATEST_TESTFLIGHT_BUILD_NUMBER
    end

    class LatestTestflightBuildNumberAction < Action
      def self.run(params)
        build_number = AppStoreBuildNumberAction.run(params)
        Actions.lane_context[SharedValues::LATEST_TESTFLIGHT_BUILD_NUMBER] = build_number
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Fetches most recent build number from TestFlight"
      end

      def self.details
        [
          "Provides a way to have increment_build_number be based on the latest build you uploaded to iTC.",
          "Fetches most recent build number from TestFlight based on the version number. Provides a way to have `increment_build_number` be based on the latest build you uploaded to iTC."
        ].join("\n")
      end

      def self.available_options
        user = CredentialsManager::AppfileConfig.try_fetch_value(:itunes_connect_id)
        user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)

        [
          FastlaneCore::ConfigItem.new(key: :live,
                                       short_option: "-l",
                                       env_name: "CURRENT_BUILD_NUMBER_LIVE",
                                       description: "Query the live version (ready-for-sale)",
                                       optional: true,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                       short_option: "-a",
                                       env_name: "FASTLANE_APP_IDENTIFIER",
                                       description: "The bundle identifier of your app",
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)),
          FastlaneCore::ConfigItem.new(key: :username,
                                       short_option: "-u",
                                       env_name: "ITUNESCONNECT_USER",
                                       description: "Your Apple ID Username",
                                       default_value: user),
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: "LATEST_VERSION",
                                       description: "The version number whose latest build number we want",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :initial_build_number,
                                       env_name: "INITIAL_BUILD_NUMBER",
                                       description: "sets the build number to given value if no build is in current train",
                                       default_value: 1,
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :team_id,
                                       short_option: "-k",
                                       env_name: "LATEST_TESTFLIGHT_BUILD_NUMBER_TEAM_ID",
                                       description: "The ID of your iTunes Connect team if you're in multiple teams",
                                       optional: true,
                                       is_string: false, # as we also allow integers, which we convert to strings anyway
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_id),
                                       verify_block: proc do |value|
                                         ENV["FASTLANE_ITC_TEAM_ID"] = value.to_s
                                       end),
          FastlaneCore::ConfigItem.new(key: :team_name,
                                       short_option: "-e",
                                       env_name: "LATEST_TESTFLIGHT_BUILD_NUMBER_TEAM_NAME",
                                       description: "The name of your iTunes Connect team if you're in multiple teams",
                                       optional: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_name),
                                       verify_block: proc do |value|
                                         ENV["FASTLANE_ITC_TEAM_NAME"] = value.to_s
                                       end)
        ]
      end

      def self.output
        [
          ['LATEST_TESTFLIGHT_BUILD_NUMBER', 'The latest build number of the latest version of the app uploaded to TestFlight']
        ]
      end

      def self.return_value
        "Integer representation of the latest build number uploaded to TestFlight"
      end

      def self.authors
        ["daveanderson"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end

      def self.example_code
        [
          'latest_testflight_build_number(version: "1.3")',
          'increment_build_number({
            build_number: latest_testflight_build_number + 1
          })'
        ]
      end

      def self.sample_return_value
        2
      end

      def self.category
        :misc
      end
    end
  end
end
