require 'deliver/submit_for_review'
require 'active_support/core_ext/numeric/time.rb'
require 'active_support/core_ext/time/calculations.rb'
require 'ostruct'

describe Deliver::SubmitForReview do
  let(:review_submitter) { Deliver::SubmitForReview.new }

  # Create a fake app with number_of_builds candidate builds
  # the builds will be in date ascending order
  def make_fake_builds(number_of_builds)
    (0...number_of_builds).map do |num|
      OpenStruct.new({ upload_date: num.minutes.from_now })
    end
  end

  describe :find_build do
    context 'one build' do
      let(:fake_builds) { make_fake_builds(1) }
      it 'finds the one build' do
        only_build = fake_builds.first
        expect(review_submitter.find_build(fake_builds)).to eq(only_build)
      end
    end

    context 'no builds' do
      let(:fake_builds) { make_fake_builds(0) }
      it 'throws a UI error' do
        expect { review_submitter.find_build(fake_builds) }.to raise_error FastlaneCore::Interface::FastlaneCrash
      end
    end

    context 'two builds' do
      let(:fake_builds) { make_fake_builds(2) }
      it 'finds the one build' do
        newest_build = fake_builds.last
        expect(review_submitter.find_build(fake_builds)).to eq(newest_build)
      end
    end
  end
end
