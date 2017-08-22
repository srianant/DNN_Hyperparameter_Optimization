require 'rails_helper'

describe Jobs::Tl3Promotions do

  subject(:run_job) { described_class.new.execute({}) }

  it "promotes tl2 user who qualifies for tl3" do
    _tl2_user = Fabricate(:user, trust_level: TrustLevel[2])
    TrustLevel3Requirements.any_instance.stubs(:requirements_met?).returns(true)
    Promotion.any_instance.expects(:change_trust_level!).with(TrustLevel[3], anything).once
    run_job
  end

  it "doesn't promote tl1 and tl0 users who have met tl3 requirements" do
    _tl1_user = Fabricate(:user, trust_level: TrustLevel[1])
    _tl0_user = Fabricate(:user, trust_level: TrustLevel[0])
    TrustLevel3Requirements.any_instance.expects(:requirements_met?).never
    Promotion.any_instance.expects(:change_trust_level!).never
    run_job
  end

  context "tl3 user who doesn't qualify for tl3 anymore" do
    def create_leader_user
      user = Fabricate(:user, trust_level: TrustLevel[2])
      TrustLevel3Requirements.any_instance.stubs(:requirements_met?).returns(true)
      expect(Promotion.new(user).review_tl2).to eq(true)
      user
    end

    before do
      SiteSetting.tl3_promotion_min_duration = 3
    end

    it "demotes if was promoted more than X days ago" do
      user = nil
      Timecop.freeze(4.days.ago) do
        user = create_leader_user
      end

      TrustLevel3Requirements.any_instance.stubs(:requirements_met?).returns(false)
      TrustLevel3Requirements.any_instance.stubs(:requirements_lost?).returns(true)
      run_job
      expect(user.reload.trust_level).to eq(TrustLevel[2])
    end

    it "doesn't demote if user was promoted recently" do
      user = nil
      Timecop.freeze(1.day.ago) do
        user = create_leader_user
      end

      TrustLevel3Requirements.any_instance.stubs(:requirements_met?).returns(false)
      TrustLevel3Requirements.any_instance.stubs(:requirements_lost?).returns(true)
      run_job
      expect(user.reload.trust_level).to eq(TrustLevel[3])
    end

    it "doesn't demote if user hasn't lost requirements (low water mark)" do
      user = nil
      Timecop.freeze(4.days.ago) do
        user = create_leader_user
      end

      TrustLevel3Requirements.any_instance.stubs(:requirements_met?).returns(false)
      TrustLevel3Requirements.any_instance.stubs(:requirements_lost?).returns(false)
      run_job
      expect(user.reload.trust_level).to eq(TrustLevel[3])
    end

  end
end
