module Scan
  class SlackPoster
    def run(results)
      return if Scan.config[:skip_slack]
      return if Scan.config[:slack_only_on_failure] && results[:failures] == 0
      return if Scan.config[:slack_url].nil?

      require 'slack-notifier'
      notifier = Slack::Notifier.new(Scan.config[:slack_url])
      notifier.username = 'fastlane'

      if Scan.config[:slack_channel].to_s.length > 0
        notifier.channel = Scan.config[:slack_channel]
        notifier.channel = ('#' + notifier.channel) unless ['#', '@'].include?(notifier.channel[0]) # send message to channel by default
      end

      attachments = []

      if Scan.config[:slack_message]
        attachments << {
          text: Scan.config[:slack_message].to_s,
          color: "good"
        }
      end

      attachments << {
        text: "Build Errors: #{results[:build_errors] || 0}",
        color: results[:build_errors].to_i > 0 ? "danger" : "good",
        short: true
      }

      if results[:failures]
        attachments << {
          text: "Test Failures: #{results[:failures]}",
          color: results[:failures].to_i > 0 ? "danger" : "good",
          short: true
        }
      end

      if results[:tests] and results[:failures]
        attachments << {
          text: "Successful Tests: #{results[:tests] - results[:failures]}",
          color: "good",
          short: true
        }
      end

      result = notifier.ping "#{Scan.project.app_name} Tests:",
                             icon_url: 'https://s3-eu-west-1.amazonaws.com/fastlane.tools/fastlane.png',
                             attachments: attachments

      if result.code.to_i == 200
        UI.success('Successfully sent Slack notification')
      else
        UI.error(result.to_s)
      end
    end
  end
end
