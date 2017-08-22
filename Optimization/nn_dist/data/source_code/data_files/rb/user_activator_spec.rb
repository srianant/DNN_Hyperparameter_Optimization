require 'rails_helper'

describe UserActivator do

  describe 'email_activator' do

    it 'does not create new email token unless required' do
      SiteSetting.email_token_valid_hours = 24
      user = Fabricate(:user)
      activator = EmailActivator.new(user, nil, nil, nil)

      Jobs.expects(:enqueue).with(:critical_user_email, has_entries(type: :signup, email_token: user.email_tokens.first.token))
      activator.activate
    end

    it 'creates and send new email token if the existing token expired' do
      SiteSetting.email_token_valid_hours = 24
      user = Fabricate(:user)
      email_token = user.email_tokens.first
      email_token.update_column(:created_at, 48.hours.ago)
      activator = EmailActivator.new(user, nil, nil, nil)

      Jobs.expects(:enqueue).with(:critical_user_email, has_entries(type: :signup))
      Jobs.expects(:enqueue).with(:critical_user_email, has_entries(type: :signup, email_token: email_token.token)).never
      activator.activate

      user.reload
      expect(user.email_tokens.last.created_at).to be_within_one_second_of(Time.zone.now)
    end

    it "escapes the email in the message" do
      user = Fabricate(:user, email: '<strike>eviltrout@example.com</strike>')
      activator = EmailActivator.new(user, nil, nil, nil)
      msg = activator.activate

      expect(msg).to match(/eviltrout@example.com/)
      expect(msg).not_to match(/<strike>/)
    end

  end
end
