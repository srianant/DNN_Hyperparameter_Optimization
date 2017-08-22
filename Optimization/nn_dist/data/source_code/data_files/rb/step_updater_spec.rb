require 'rails_helper'
require_dependency 'wizard'
require_dependency 'wizard/builder'
require_dependency 'wizard/step_updater'

describe Wizard::StepUpdater do
  before do
    SiteSetting.wizard_enabled = true
  end

  let(:user) { Fabricate(:admin) }
  let(:wizard) { Wizard::Builder.new(user).build }

  context "locale" do
    it "does not require refresh when the language stays the same" do
      updater = wizard.create_updater('locale', default_locale: 'en')
      updater.update
      expect(updater.refresh_required?).to eq(false)
      expect(wizard.completed_steps?('locale')).to eq(true)
    end

    it "updates the locale and requires refresh when it does change" do
      updater = wizard.create_updater('locale', default_locale: 'ru')
      updater.update
      expect(SiteSetting.default_locale).to eq('ru')
      expect(updater.refresh_required?).to eq(true)
      expect(wizard.completed_steps?('locale')).to eq(true)
    end
  end

  it "updates the forum title step" do
    updater = wizard.create_updater('forum_title', title: 'new forum title', site_description: 'neat place')
    updater.update

    expect(updater.success?).to eq(true)
    expect(SiteSetting.title).to eq("new forum title")
    expect(SiteSetting.site_description).to eq("neat place")
    expect(wizard.completed_steps?('forum-title')).to eq(true)
  end

  it "updates the introduction step" do
    topic = Fabricate(:topic, title: "Welcome to Discourse")
    welcome_post = Fabricate(:post, topic: topic, raw: "this will be the welcome topic post\n\ncool!")

    updater = wizard.create_updater('introduction', welcome: "Welcome to my new awesome forum!")
    updater.update

    expect(updater.success?).to eq(true)
    welcome_post.reload
    expect(welcome_post.raw).to eq("Welcome to my new awesome forum!\n\ncool!")

    expect(wizard.completed_steps?('introduction')).to eq(true)

  end

  it "won't allow updates to the default value, when required" do
    updater = wizard.create_updater('forum_title', title: SiteSetting.title, site_description: 'neat place')
    updater.update

    expect(updater.success?).to eq(false)
  end

  context "privacy settings" do
    it "updates to open correctly" do
      updater = wizard.create_updater('privacy', privacy: 'open')
      updater.update
      expect(updater.success?).to eq(true)
      expect(SiteSetting.login_required?).to eq(false)
      expect(SiteSetting.invite_only?).to eq(false)
      expect(wizard.completed_steps?('privacy')).to eq(true)
    end

    it "updates to private correctly" do
      updater = wizard.create_updater('privacy', privacy: 'restricted')
      updater.update
      expect(updater.success?).to eq(true)
      expect(SiteSetting.login_required?).to eq(true)
      expect(SiteSetting.invite_only?).to eq(true)
      expect(wizard.completed_steps?('privacy')).to eq(true)
    end
  end

  context "contact step" do
    it "updates the fields correctly" do
      updater = wizard.create_updater('contact',
                                      contact_email: 'eviltrout@example.com',
                                      contact_url: 'http://example.com/custom-contact-url',
                                      site_contact: user.username)

      updater.update
      expect(updater).to be_success
      expect(SiteSetting.contact_email).to eq("eviltrout@example.com")
      expect(SiteSetting.contact_url).to eq("http://example.com/custom-contact-url")
      expect(SiteSetting.site_contact_username).to eq(user.username)
      expect(wizard.completed_steps?('contact')).to eq(true)
    end

    it "doesn't update when there are errors" do
      updater = wizard.create_updater('contact',
                                      contact_email: 'not-an-email',
                                      site_contact_username: 'not-a-username')
      updater.update
      expect(updater).to_not be_success
      expect(updater.errors).to be_present
      expect(wizard.completed_steps?('contact')).to eq(false)
    end
  end

  context "corporate step" do

    it "updates the fields properly" do

      p = Fabricate(:post, raw: 'company_domain - company_full_name - company_short_name template')
      SiteSetting.tos_topic_id = p.topic_id

      updater = wizard.create_updater('corporate',
                                      company_short_name: 'ACME',
                                      company_full_name: 'ACME, Inc.',
                                      company_domain: 'acme.com')
      updater.update
      expect(updater).to be_success
      expect(SiteSetting.company_short_name).to eq("ACME")
      expect(SiteSetting.company_full_name).to eq("ACME, Inc.")
      expect(SiteSetting.company_domain).to eq("acme.com")

      # Should update the TOS topic
      raw = Post.where(topic_id: SiteSetting.tos_topic_id, post_number: 1).pluck(:raw).first
      expect(raw).to eq("acme.com - ACME, Inc. - ACME template")

      # Can update the TOS topic again
      updater = wizard.create_updater('corporate',
                                      company_short_name: 'PPI',
                                      company_full_name: 'Pied Piper Inc',
                                      company_domain: 'piedpiper.com')
      updater.update
      raw = Post.where(topic_id: SiteSetting.tos_topic_id, post_number: 1).pluck(:raw).first
      expect(raw).to eq("piedpiper.com - Pied Piper Inc - PPI template")

      # Can update the TOS to nothing
      updater = wizard.create_updater('corporate', {})
      updater.update
      raw = Post.where(topic_id: SiteSetting.tos_topic_id, post_number: 1).pluck(:raw).first
      expect(raw).to eq("company_domain - company_full_name - company_short_name template")

      expect(wizard.completed_steps?('corporate')).to eq(true)
    end
  end

  context "colors step" do
    context "with an existing color scheme" do
      let!(:color_scheme) { Fabricate(:color_scheme, name: 'existing', via_wizard: true) }

      it "updates the scheme" do
        updater = wizard.create_updater('colors', theme_id: 'dark')
        updater.update
        expect(updater.success?).to eq(true)
        expect(wizard.completed_steps?('colors')).to eq(true)

        color_scheme.reload
        expect(color_scheme).to be_enabled
      end
    end

    context "without an existing scheme" do
      it "creates the scheme" do
        updater = wizard.create_updater('colors', theme_id: 'dark')
        updater.update
        expect(updater.success?).to eq(true)
        expect(wizard.completed_steps?('colors')).to eq(true)

        color_scheme = ColorScheme.where(via_wizard: true).first
        expect(color_scheme).to be_present
        expect(color_scheme).to be_enabled
        expect(color_scheme.colors).to be_present
      end
    end
  end

  context "logos step" do
    it "updates the fields correctly" do
      updater = wizard.create_updater('logos',
                                      logo_url: '/uploads/logo.png',
                                      logo_small_url: '/uploads/logo-small.png')
      updater.update

      expect(updater).to be_success
      expect(wizard.completed_steps?('logos')).to eq(true)
      expect(SiteSetting.logo_url).to eq('/uploads/logo.png')
      expect(SiteSetting.logo_small_url).to eq('/uploads/logo-small.png')
    end
  end

  context "icons step" do
    it "updates the fields correctly" do
      updater = wizard.create_updater('icons',
                                      favicon_url: "/uploads/favicon.png",
                                      apple_touch_icon_url: "/uploads/apple.png")
      updater.update

      expect(updater).to be_success
      expect(wizard.completed_steps?('icons')).to eq(true)
      expect(SiteSetting.favicon_url).to eq('/uploads/favicon.png')
      expect(SiteSetting.apple_touch_icon_url).to eq('/uploads/apple.png')
    end
  end

  context "emoji step" do
    it "updates the fields correctly" do
      updater = wizard.create_updater('emoji', emoji_set: "twitter")
      updater.update

      expect(updater).to be_success
      expect(wizard.completed_steps?('emoji')).to eq(true)
      expect(SiteSetting.emoji_set).to eq('twitter')
    end
  end

  context "homepage step" do
    it "updates the fields correctly" do
      updater = wizard.create_updater('homepage', homepage_style: "categories")
      updater.update

      expect(updater).to be_success
      expect(wizard.completed_steps?('homepage')).to eq(true)
      expect(SiteSetting.top_menu).to eq('categories|latest|new|unread|top')

      updater = wizard.create_updater('homepage', homepage_style: "latest")
      updater.update
      expect(updater).to be_success
      expect(SiteSetting.top_menu).to eq('latest|new|unread|top|categories')
    end
  end

  context "invites step" do
    let(:invites) {
      return [{ email: 'regular@example.com', role: 'regular'},
              { email: 'moderator@example.com', role: 'moderator'}]
    }

    it "updates the fields correctly" do
      updater = wizard.create_updater('invites', invite_list: invites.to_json)
      updater.update

      expect(updater).to be_success
      expect(wizard.completed_steps?('invites')).to eq(true)

      reg_invite = Invite.where(email: 'regular@example.com').first
      expect(reg_invite).to be_present
      expect(reg_invite.moderator?).to eq(false)

      mod_invite = Invite.where(email: 'moderator@example.com').first
      expect(mod_invite).to be_present
      expect(mod_invite.moderator?).to eq(true)
    end
  end

end
