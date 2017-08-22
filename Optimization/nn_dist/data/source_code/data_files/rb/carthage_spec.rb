describe Fastlane do
  describe Fastlane::FastFile do
    describe "Carthage Integration" do
      it "raises an error if command is invalid" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            carthage(
              command: 'thisistest'
            )
          end").runner.execute(:test)
        end.to raise_error("Please pass a valid command. Use one of the following: build, bootstrap, update, archive")
      end

      it "raises an error if use_ssh is invalid" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            carthage(
              use_ssh: 'thisistest'
            )
          end").runner.execute(:test)
        end.to raise_error("Please pass a valid value for use_ssh. Use one of the following: true, false")
      end

      it "raises an error if use_submodules is invalid" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            carthage(
              use_submodules: 'thisistest'
            )
          end").runner.execute(:test)
        end.to raise_error("Please pass a valid value for use_submodules. Use one of the following: true, false")
      end

      it "raises an error if use_binaries is invalid" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            carthage(
              use_binaries: 'thisistest'
            )
          end").runner.execute(:test)
        end.to raise_error("Please pass a valid value for use_binaries. Use one of the following: true, false")
      end

      it "raises an error if no_build is invalid" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            carthage(
              no_build: 'thisistest'
            )
          end").runner.execute(:test)
        end.to raise_error("Please pass a valid value for no_build. Use one of the following: true, false")
      end

      it "raises an error if no_skip_current is invalid" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            carthage(
              no_skip_current: 'thisistest'
            )
          end").runner.execute(:test)
        end.to raise_error("Please pass a valid value for no_skip_current. Use one of the following: true, false")
      end

      it "raises an error if verbose is invalid" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            carthage(
              verbose: 'thisistest'
            )
          end").runner.execute(:test)
        end.to raise_error("Please pass a valid value for verbose. Use one of the following: true, false")
      end

      it "raises an error if platform is invalid" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            carthage(
              platform: 'thisistest'
            )
          end").runner.execute(:test)
        end.to raise_error("Please pass a valid platform. Use one of the following: all, iOS, Mac, tvOS, watchOS")
      end

      it "default use case is boostrap" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap")
      end

      it "sets the command to build" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(command: 'build')
          end").runner.execute(:test)

        expect(result).to eq("carthage build")
      end

      it "sets the command to bootstrap" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(command: 'bootstrap')
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap")
      end

      it "sets the command to update" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(command: 'update')
          end").runner.execute(:test)

        expect(result).to eq("carthage update")
      end

      it "sets the command to archive" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(command: 'archive')
          end").runner.execute(:test)

        expect(result).to eq("carthage archive")
      end

      it "adds use-ssh flag to command if use_ssh is set to true" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              use_ssh: true
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --use-ssh")
      end

      it "doesn't add a use-ssh flag to command if use_ssh is set to false" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              use_ssh: false
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap")
      end

      it "adds use-submodules flag to command if use_submodules is set to true" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              use_submodules: true
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --use-submodules")
      end

      it "doesn't add a use-submodules flag to command if use_submodules is set to false" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              use_submodules: false
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap")
      end

      it "adds no-use-binaries flag to command if use_binaries is set to false" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              use_binaries: false
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --no-use-binaries")
      end

      it "doesn't add a no-use-binaries flag to command if use_binaries is set to true" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              use_binaries: true
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap")
      end

      it "adds no-build flag to command if no_build is set to true" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              no_build: true
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --no-build")
      end

      it "does not add a no-build flag to command if no_build is set to false" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              no_build: false
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap")
      end

      it "adds no-skip-current flag to command if no_skip_current is set to true" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              command: 'build',
              no_skip_current: true
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage build --no-skip-current")
      end

      it "doesn't add a no-skip-current flag to command if no_skip_current is set to false" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              command: 'build',
              no_skip_current: false
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage build")
      end

      it "adds verbose flag to command if verbose is set to true" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              verbose: true
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --verbose")
      end

      it "does not add a verbose flag to command if verbose is set to false" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              verbose: false
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap")
      end

      it "sets the platform to all" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              platform: 'all'
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --platform all")
      end

      it "sets the platform to iOS" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              platform: 'iOS'
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --platform iOS")
      end

      it "sets the platform to (downcase) ios" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              platform: 'ios'
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --platform ios")
      end

      it "sets the platform to Mac" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              platform: 'Mac'
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --platform Mac")
      end

      it "sets the platform to tvOS" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              platform: 'tvOS'
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --platform tvOS")
      end

      it "sets the platform to watchOS" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              platform: 'watchOS'
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --platform watchOS")
      end

      it "can be set to multiple the platforms" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              platform: 'iOS,Mac'
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --platform iOS,Mac")
      end

      it "sets the configuration to Release" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              configuration: 'Release'
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --configuration Release")
      end

      it "raises an error if configuration is empty" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            carthage(
              configuration: ' '
            )
          end").runner.execute(:test)
        end.to raise_error("Please pass a valid build configuration. You can review the list of configurations for this project using the command: xcodebuild -list")
      end

      it "sets the toolchain to Swift_2_3" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              toolchain: 'com.apple.dt.toolchain.Swift_2_3'
            )
          end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --toolchain com.apple.dt.toolchain.Swift_2_3")
      end

      it "sets the project directory to other" do
        result = Fastlane::FastFile.new.parse("lane :test do
          carthage(project_directory: 'other')
        end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --project-directory other")
      end

      it "sets the project directory to other and the toolchain to Swift_2_3" do
        result = Fastlane::FastFile.new.parse("lane :test do
          carthage(toolchain: 'com.apple.dt.toolchain.Swift_2_3', project_directory: 'other')
        end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap --toolchain com.apple.dt.toolchain.Swift_2_3 --project-directory other")
      end

      it "does not set the project directory if none is provided" do
        result = Fastlane::FastFile.new.parse("lane :test do
          carthage
        end").runner.execute(:test)

        expect(result).to eq("carthage bootstrap")
      end

      it "use custom derived data" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              derived_data: '../derived data'
            )
          end").runner.execute(:test)

        expect(result).to \
          eq("carthage bootstrap --derived-data ../derived\\ data")
      end

      it "updates with a single dependency" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              command: 'update',
              dependencies: ['TestDependency']
            )
          end").runner.execute(:test)

        expect(result).to \
          eq("carthage update TestDependency")
      end

      it "updates with multiple dependencies" do
        result = Fastlane::FastFile.new.parse("lane :test do
            carthage(
              command: 'update',
              dependencies: ['TestDependency1', 'TestDependency2']
            )
          end").runner.execute(:test)

        expect(result).to \
          eq("carthage update TestDependency1 TestDependency2")
      end

      it "works with no parameters" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            carthage
          end").runner.execute(:test)
        end.not_to raise_error
      end

      it "works with valid parameters" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            carthage(
              use_ssh: true,
              use_submodules: true,
              use_binaries: false,
              platform: 'iOS'
            )
          end").runner.execute(:test)
        end.not_to raise_error
      end
    end
  end
end
