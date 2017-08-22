require "isolation/abstract_unit"

module ApplicationTests
  module ConfigurationTests
    class CustomTest < ActiveSupport::TestCase
      def setup
        build_app
        FileUtils.rm_rf("#{app_path}/config/environments")
      end

      def teardown
        teardown_app
        FileUtils.rm_rf(new_app) if File.directory?(new_app)
      end

      test "access custom configuration point" do
        add_to_config <<-RUBY
          config.x.payment_processing.schedule = :daily
          config.x.payment_processing.retries  = 3
          config.x.super_debugger              = true
          config.x.hyper_debugger              = false
          config.x.nil_debugger                = nil
        RUBY
        require_environment

        x = Rails.configuration.x
        assert_equal :daily, x.payment_processing.schedule
        assert_equal 3, x.payment_processing.retries
        assert_equal true, x.super_debugger
        assert_equal false, x.hyper_debugger
        assert_equal nil, x.nil_debugger
        assert_nil x.i_do_not_exist.zomg
      end

      test "custom configuration responds to all messages" do
        x = Rails.configuration.x
        assert_equal true, x.respond_to?(:i_do_not_exist)
        assert_kind_of Method, x.method(:i_do_not_exist)
        assert_kind_of ActiveSupport::OrderedOptions, x.i_do_not_exist
      end

      private
        def new_app
          File.expand_path("#{app_path}/../new_app")
        end

        def copy_app
          FileUtils.cp_r(app_path, new_app)
        end

        def app
          @app ||= Rails.application
        end

        def require_environment
          require "#{app_path}/config/environment"
        end
    end
  end
end
