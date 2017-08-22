require "rails_helper"
require 'sidekiq/testing'

describe DiscourseSingleSignOn do
  before do
    @sso_url = "http://somesite.com/discourse_sso"
    @sso_secret = "shjkfdhsfkjh"

    SiteSetting.enable_sso = true
    SiteSetting.sso_url = @sso_url
    SiteSetting.sso_secret = @sso_secret
  end

  def make_sso
    sso = SingleSignOn.new
    sso.sso_url = "http://meta.discorse.org/topics/111"
    sso.sso_secret = "supersecret"
    sso.nonce = "testing"
    sso.email = "some@email.com"
    sso.username = "sam"
    sso.name = "sam saffron"
    sso.external_id = "100"
    sso.avatar_url = "https://cdn.discourse.org/user_avatar.png"
    sso.avatar_force_update = false
    sso.bio = "about"
    sso.admin = false
    sso.moderator = false
    sso.suppress_welcome_message = false
    sso.require_activation = false
    sso.custom_fields["a"] = "Aa"
    sso.custom_fields["b.b"] = "B.b"
    sso
  end

  def test_parsed(parsed, sso)
    expect(parsed.nonce).to eq sso.nonce
    expect(parsed.email).to eq sso.email
    expect(parsed.username).to eq sso.username
    expect(parsed.name).to eq sso.name
    expect(parsed.external_id).to eq sso.external_id
    expect(parsed.avatar_url).to eq sso.avatar_url
    expect(parsed.avatar_force_update).to eq sso.avatar_force_update
    expect(parsed.bio).to eq sso.bio
    expect(parsed.admin).to eq sso.admin
    expect(parsed.moderator).to eq sso.moderator
    expect(parsed.suppress_welcome_message).to eq sso.suppress_welcome_message
    expect(parsed.require_activation).to eq false
    expect(parsed.custom_fields["a"]).to eq "Aa"
    expect(parsed.custom_fields["b.b"]).to eq "B.b"
  end

  it "can do round trip parsing correctly" do
    sso = SingleSignOn.new
    sso.sso_secret = "test"
    sso.name = "sam saffron"
    sso.username = "sam"
    sso.email = "sam@sam.com"

    sso = SingleSignOn.parse(sso.payload, "test")

    expect(sso.name).to eq "sam saffron"
    expect(sso.username).to eq "sam"
    expect(sso.email).to eq "sam@sam.com"
  end

  let(:ip_address) { "127.0.0.1" }

  it "can lookup or create user when name is blank" do
    # so we can create system messages
    Fabricate(:admin)
    sso = DiscourseSingleSignOn.new
    sso.username = "test"
    sso.name = ""
    sso.email = "test@test.com"
    sso.external_id = "A"
    user = sso.lookup_or_create_user(ip_address)
    expect(user).to_not be_nil
  end

  it "unstaged users" do
    email = "staged@user.com"
    Fabricate(:user, staged: true, email: email)

    sso = DiscourseSingleSignOn.new
    sso.username = "staged"
    sso.name = "Staged User"
    sso.email = email
    sso.external_id = "B"
    user = sso.lookup_or_create_user(ip_address)

    expect(user).to_not be_nil
    expect(user.staged).to be(false)
  end

  it "can set admin and moderator" do
    admin_group = Group[:admins]
    mod_group = Group[:moderators]
    staff_group = Group[:staff]

    sso = DiscourseSingleSignOn.new
    sso.username = "misteradmin"
    sso.name = "Bob Admin"
    sso.email = "admin@admin.com"
    sso.external_id = "id"
    sso.admin = true
    sso.moderator = true

    user = sso.lookup_or_create_user(ip_address)
    staff_group.reload

    expect(mod_group.users.where('users.id = ?', user.id).exists?).to eq(true)
    expect(staff_group.users.where('users.id = ?', user.id).exists?).to eq(true)
    expect(admin_group.users.where('users.id = ?', user.id).exists?).to eq(true)
  end

  it "can override name / email / username" do
    admin = Fabricate(:admin)

    SiteSetting.sso_overrides_name = true
    SiteSetting.sso_overrides_email = true
    SiteSetting.sso_overrides_username = true

    sso = DiscourseSingleSignOn.new
    sso.username = "bob%the$admin"
    sso.name = "Bob Admin"
    sso.email = admin.email
    sso.external_id = "A"

    sso.lookup_or_create_user(ip_address)

    admin.reload

    expect(admin.name).to eq "Bob Admin"
    expect(admin.username).to eq "bob_the_admin"
    expect(admin.email).to eq admin.email

    sso.email = "TEST@bob.com"

    sso.name = "Louis C.K."

    sso.lookup_or_create_user(ip_address)

    admin.reload

    expect(admin.email).to eq("test@bob.com")
    expect(admin.username).to eq "bob_the_admin"
    expect(admin.name).to eq "Louis C.K."
  end

  it "can fill in data on way back" do
    sso = make_sso

    url, payload = sso.to_url.split("?")
    expect(url).to eq sso.sso_url
    parsed = SingleSignOn.parse(payload, "supersecret")

    test_parsed(parsed, sso)
  end

  it "handles sso_url with query params" do
    sso = make_sso
    sso.sso_url = "http://tcdev7.wpengine.com/?action=showlogin"

    expect(sso.to_url.split('?').size).to eq 2

    url, payload = sso.to_url.split("?")
    expect(url).to eq "http://tcdev7.wpengine.com/"
    parsed = SingleSignOn.parse(payload, "supersecret")

    test_parsed(parsed, sso)
  end

  it "validates nonce" do
    _ , payload = DiscourseSingleSignOn.generate_url.split("?")

    sso = DiscourseSingleSignOn.parse(payload)
    expect(sso.nonce_valid?).to eq true

    sso.expire_nonce!

    expect(sso.nonce_valid?).to eq false

  end

  it "generates a correct sso url" do
    url, payload = DiscourseSingleSignOn.generate_url.split("?")
    expect(url).to eq @sso_url

    sso = DiscourseSingleSignOn.parse(payload)
    expect(sso.nonce).to_not be_nil
  end

  context 'trusting emails' do
    let(:sso) {
      sso = DiscourseSingleSignOn.new
      sso.username = "test"
      sso.name = "test"
      sso.email = "test@example.com"
      sso.external_id = "A"
      sso
    }

    it 'activates users by default' do
      user = sso.lookup_or_create_user(ip_address)
      expect(user.active).to eq(true)
    end

    it 'does not activate user when asked not to' do
      sso.require_activation = true
      user = sso.lookup_or_create_user(ip_address)
      expect(user.active).to eq(false)
    end

  end

  context 'welcome emails' do
    let(:sso) {
      sso = DiscourseSingleSignOn.new
      sso.username = "test"
      sso.name = "test"
      sso.email = "test@example.com"
      sso.external_id = "A"
      sso
    }

    it "sends a welcome email by default" do
      User.any_instance.expects(:enqueue_welcome_message).once
      user = sso.lookup_or_create_user(ip_address)
    end

    it "suppresses the welcome email when asked to" do
      User.any_instance.expects(:enqueue_welcome_message).never
      sso.suppress_welcome_message = true
      user = sso.lookup_or_create_user(ip_address)
    end
  end

  context 'setting bio for a user' do
    let(:sso) {
      sso = DiscourseSingleSignOn.new
      sso.username = "test"
      sso.name = "test"
      sso.email = "test@test.com"
      sso.external_id = "100"
      sso.bio = "This **is** the bio"
      sso
    }

    it 'can set bio if supplied on new users or users with empty bio' do
      # new account
      user = sso.lookup_or_create_user(ip_address)
      expect(user.user_profile.bio_cooked).to match_html("<p>This <strong>is</strong> the bio</p>")


      # no override by default
      sso.bio = "new profile"
      user = sso.lookup_or_create_user(ip_address)

      expect(user.user_profile.bio_cooked).to match_html("<p>This <strong>is</strong> the bio</p>")

      # yes override for blank
      user.user_profile.bio_raw = " "
      user.user_profile.save!

      user = sso.lookup_or_create_user(ip_address)
      expect(user.user_profile.bio_cooked).to match_html("<p>new profile</p>")


      # yes override if site setting
      sso.bio = "new profile 2"
      SiteSetting.sso_overrides_bio = true

      user = sso.lookup_or_create_user(ip_address)
      expect(user.user_profile.bio_cooked).to match_html("<p>new profile 2</p>")
    end

  end

  context 'when sso_overrides_avatar is not enabled' do


    it "correctly handles provided avatar_urls" do
      Sidekiq::Testing.inline! do
        sso = DiscourseSingleSignOn.new
        sso.external_id = 666
        sso.email = "sam@sam.com"
        sso.name = "sam"
        sso.username = "sam"
        sso.avatar_url = "http://awesome.com/image.png"

        FileHelper.stubs(:download).returns(file_from_fixtures("logo.png"))
        user = sso.lookup_or_create_user(ip_address)
        user.reload
        avatar_id = user.uploaded_avatar_id

        # initial creation ...
        expect(avatar_id).to_not eq(nil)

        # junk avatar id should be updated
        old_id = user.uploaded_avatar_id
        Upload.destroy(old_id)

        user = sso.lookup_or_create_user(ip_address)
        user.reload
        avatar_id = user.uploaded_avatar_id

        expect(avatar_id).to_not eq(nil)
        expect(old_id).to_not eq(avatar_id)

        FileHelper.stubs(:download) { raise "should not be called" }
        sso.avatar_url = "https://some.new/avatar.png"
        user = sso.lookup_or_create_user(ip_address)
        user.reload

        # avatar updated but no override specified ...
        expect(user.uploaded_avatar_id).to eq(avatar_id)

        sso.avatar_force_update = true
        FileHelper.stubs(:download).returns(file_from_fixtures("logo-dev.png"))
        user = sso.lookup_or_create_user(ip_address)
        user.reload

        # we better have a new avatar
        expect(user.uploaded_avatar_id).not_to eq(avatar_id)
        expect(user.uploaded_avatar_id).not_to eq(nil)

        avatar_id = user.uploaded_avatar_id

        sso.avatar_force_update = true
        FileHelper.stubs(:download) { raise "not found" }
        user = sso.lookup_or_create_user(ip_address)
        user.reload

        # we better have the same avatar
        expect(user.uploaded_avatar_id).to eq(avatar_id)
      end
    end

  end

  context 'when sso_overrides_avatar is enabled' do
    let!(:sso_record) { Fabricate(:single_sign_on_record, external_avatar_url: "http://example.com/an_image.png") }

    let!(:sso) {
      sso = DiscourseSingleSignOn.new
      sso.username = "test"
      sso.name = "test"
      sso.email = sso_record.user.email
      sso.external_id = sso_record.external_id
      sso
    }

    let(:logo) { file_from_fixtures("logo.png") }

    before do
      SiteSetting.sso_overrides_avatar = true
    end

    it "deal with no avatar url passed for an existing user with an avatar" do
      Sidekiq::Testing.inline! do
        # Deliberately not setting avatar_url so it should not update
        sso_record.user.update_columns(uploaded_avatar_id: -1)
        user = sso.lookup_or_create_user(ip_address)
        user.reload

        expect(user).to_not be_nil
        expect(user.uploaded_avatar_id).to eq(-1)
      end
    end

    it "deal with no avatar_force_update passed as a boolean" do
      Sidekiq::Testing.inline! do
        FileHelper.stubs(:download).returns(logo)

        sso_record.user.update_columns(uploaded_avatar_id: -1)

        sso.avatar_url = "http://example.com/a_different_image.png"
        sso.avatar_force_update = false

        user = sso.lookup_or_create_user(ip_address)
        user.reload

        expect(user).to_not be_nil
        expect(user.uploaded_avatar_id).to_not eq(-1)
      end
    end
  end
end
