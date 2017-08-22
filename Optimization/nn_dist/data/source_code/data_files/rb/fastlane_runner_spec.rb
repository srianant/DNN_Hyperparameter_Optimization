require 'spec_helper'

describe Commander::Runner do
  describe 'tool collector interactions' do
    class CommandsGenerator
      include Commander::Methods

      def initialize(raise_error: nil)
        @raise_error = raise_error
      end

      def run
        program :name, 'tool_name'
        program :version, '1.9'
        program :description, 'Description'

        # This is required because we're running this real Commander instance inside of
        # the real rspec tests command. When we run rspec for all projects, these options
        # get set, and Commander is going to validate that they are something that our
        # fake program accepts.
        #
        # This is not ideal, but the downside is potential broken tests in the future,
        # which we can quickly adjust.
        global_option '--format', String
        global_option '--out', String

        command :run do |c|
          c.action do |args, options|
            raise @raise_error if @raise_error
          end
        end

        default_command :run

        run!
      end
    end

    let(:mock_tool_collector) { FastlaneCore::ToolCollector.new }

    before(:each) do
      allow(Commander::Runner).to receive(:instance).and_return(Commander::Runner.new)
      expect(FastlaneCore::ToolCollector).to receive(:new).and_return(mock_tool_collector)
    end

    it "calls the tool collector lifecycle methods for a successful run" do
      expect(mock_tool_collector).to receive(:did_launch_action).with("tool_name").and_call_original
      expect(mock_tool_collector).to receive(:did_finish).and_call_original

      CommandsGenerator.new.run
    end

    it "calls the tool collector lifecycle methods for a crash" do
      expect(mock_tool_collector).to receive(:did_launch_action).with("tool_name").and_call_original
      expect(mock_tool_collector).to receive(:did_crash).with("tool_name").and_call_original

      expect do
        CommandsGenerator.new(raise_error: StandardError).run
      end.to raise_error(StandardError)
    end

    it "calls the tool collector lifecycle methods for a user error" do
      expect(mock_tool_collector).to receive(:did_launch_action).with("tool_name").and_call_original
      expect(mock_tool_collector).to receive(:did_raise_error).with("tool_name").and_call_original

      expect do
        CommandsGenerator.new(raise_error: FastlaneCore::Interface::FastlaneError).run
      end.to raise_error(SystemExit)
    end
  end

  describe '#handle_unknown_error' do
    class CustomError < StandardError
      def preferred_error_info
        ['Title', 'Line 1', 'Line 2']
      end
    end

    class NilReturningError < StandardError
      def preferred_error_info
        nil
      end
    end

    it 'should reraise errors that are not of special interest' do
      expect do
        Commander::Runner.new.handle_unknown_error!(StandardError.new('my message'))
      end.to raise_error(StandardError, '[!] my message'.red)
    end

    it 'should reraise errors that return nil from #preferred_error_info' do
      expect do
        Commander::Runner.new.handle_unknown_error!(NilReturningError.new('my message'))
      end.to raise_error(StandardError, '[!] my message'.red)
    end

    it 'should abort and show custom info for errors that have the Apple error info provider method with $verbose=false' do
      runner = Commander::Runner.new
      expect(runner).to receive(:abort).with("\n[!] Title\n\tLine 1\n\tLine 2".red)

      with_verbose(false) do
        runner.handle_unknown_error!(CustomError.new)
      end
    end

    it 'should reraise and show custom info for errors that have the Apple error info provider method with $verbose=true' do
      with_verbose(true) do
        expect do
          Commander::Runner.new.handle_unknown_error!(CustomError.new)
        end.to raise_error(CustomError, "[!] Title\n\tLine 1\n\tLine 2".red)
      end
    end
  end
end
