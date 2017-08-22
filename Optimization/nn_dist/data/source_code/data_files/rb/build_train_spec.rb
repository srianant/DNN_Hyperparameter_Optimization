require 'spec_helper'

describe Spaceship::Tunes::BuildTrain do
  before { Spaceship::Tunes.login }
  subject { Spaceship::Tunes.client }
  let(:username) { 'spaceship@krausefx.com' }
  let(:password) { 'so_secret' }

  describe "properly parses the train" do
    let(:app) { Spaceship::Application.all.first }

    it "inspect works" do
      expect(Spaceship::Application.all.first.build_trains.values.first.inspect).to include("Tunes::BuildTrain")
    end

    it "works filled in all required values" do
      trains = app.build_trains

      expect(trains.count).to eq(2)
      train = trains.values.first

      expect(train.version_string).to eq("1.0")
      expect(train.platform).to eq("ios")
      expect(train.application).to eq(app)

      # TestFlight
      expect(trains.values.first.external_testing_enabled).to eq(false)
      expect(trains.values.first.internal_testing_enabled).to eq(true)
      expect(trains.values.last.external_testing_enabled).to eq(false)
      expect(trains.values.last.internal_testing_enabled).to eq(false)
    end

    it "returns all processing builds" do
      builds = app.all_processing_builds
      expect(builds.count).to eq(3)
    end

    describe "Accessing builds" do
      it "lets the user fetch the builds for a given train" do
        train = app.build_trains.values.first
        expect(train.builds.count).to eq(1)
      end

      it "lets the user fetch the builds using the version as a key" do
        train = app.build_trains['1.0']
        expect(train.version_string).to eq('1.0')
        expect(train.platform).to eq('ios')
        expect(train.internal_testing_enabled).to eq(true)
        expect(train.external_testing_enabled).to eq(false)
        expect(train.builds.count).to eq(1)
      end
    end

    describe "Processing builds" do
      it "extracts builds that are stuck or pre-processing" do
        expect(app.all_invalid_builds.count).to eq(2)

        invalid_binary = app.all_invalid_builds.first
        expect(invalid_binary.upload_date).to eq(1_436_381_720_000)
        expect(invalid_binary.processing_state).to eq("invalidBinary")

        processing_failed = app.all_invalid_builds[1]
        expect(processing_failed.upload_date).to eq(1_461_108_334_000)
        expect(processing_failed.processing_state).to eq("processingFailed")
      end

      it "properly extracted the processing builds from a train" do
        train = app.build_trains['1.0']
        expect(train.processing_builds.count).to eq(0)
      end
    end

    describe "#update_testing_status" do
      it "just works (tm)" do
        train1 = app.build_trains['1.0']
        train2 = app.build_trains['1.1']
        expect(train1.internal_testing_enabled).to eq(true)
        expect(train2.internal_testing_enabled).to eq(false)

        train2.update_testing_status!(true, 'internal')

        expect(train2.internal_testing_enabled).to eq(true)
      end
    end
  end
end
