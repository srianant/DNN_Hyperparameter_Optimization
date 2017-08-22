require 'rails_helper'

require_dependency 'jobs/scheduled/clean_up_uploads'

describe Jobs::CleanUpUploads do

  def fabricate_upload
    Fabricate(:upload, created_at: 2.hours.ago)
  end

  before do
    Upload.destroy_all
    SiteSetting.clean_up_uploads = true
    SiteSetting.clean_orphan_uploads_grace_period_hours = 1
    @upload = fabricate_upload
  end

  it "deletes orphan uploads" do
    expect(Upload.count).to be(1)

    Jobs::CleanUpUploads.new.execute(nil)

    expect(Upload.count).to be(0)
  end

  it "does not clean up uploads in site settings" do
    logo_upload = fabricate_upload
    SiteSetting.logo_url = logo_upload.url

    Jobs::CleanUpUploads.new.execute(nil)

    expect(Upload.find_by(id: @upload.id)).to eq(nil)
    expect(Upload.find_by(id: logo_upload.id)).to eq(logo_upload)
  end

  it "does not delete profile background uploads" do
    profile_background_upload = fabricate_upload
    UserProfile.last.update_attributes!(profile_background: profile_background_upload.url)

    Jobs::CleanUpUploads.new.execute(nil)

    expect(Upload.find_by(id: @upload.id)).to eq(nil)
    expect(Upload.find_by(id: profile_background_upload.id)).to eq(profile_background_upload)
  end

  it "does not delete card background uploads" do
    card_background_upload = fabricate_upload
    UserProfile.last.update_attributes!(card_background: card_background_upload.url)

    Jobs::CleanUpUploads.new.execute(nil)

    expect(Upload.find_by(id: @upload.id)).to eq(nil)
    expect(Upload.find_by(id: card_background_upload.id)).to eq(card_background_upload)
  end

  it "does not delete category logo uploads" do
    category_logo_upload = fabricate_upload
    Fabricate(:category, logo_url: category_logo_upload.url)

    Jobs::CleanUpUploads.new.execute(nil)

    expect(Upload.find_by(id: @upload.id)).to eq(nil)
    expect(Upload.find_by(id: category_logo_upload.id)).to eq(category_logo_upload)
  end

  it "does not delete category background url uploads" do
    category_background_url = fabricate_upload
    Fabricate(:category, background_url: category_background_url.url)

    Jobs::CleanUpUploads.new.execute(nil)

    expect(Upload.find_by(id: @upload.id)).to eq(nil)
    expect(Upload.find_by(id: category_background_url.id)).to eq(category_background_url)
  end

  it "does not delete post uploads" do
    upload = fabricate_upload
    Fabricate(:post, uploads: [upload])

    Jobs::CleanUpUploads.new.execute(nil)

    expect(Upload.find_by(id: @upload.id)).to eq(nil)
    expect(Upload.find_by(id: upload.id)).to eq(upload)
  end

  it "does not delete user uploaded avatar" do
    upload = fabricate_upload
    Fabricate(:user, uploaded_avatar: upload)

    Jobs::CleanUpUploads.new.execute(nil)

    expect(Upload.find_by(id: @upload.id)).to eq(nil)
    expect(Upload.find_by(id: upload.id)).to eq(upload)
  end

  it "does not delete user gravatar" do
    upload = fabricate_upload
    Fabricate(:user, user_avatar: Fabricate(:user_avatar, gravatar_upload: upload))

    Jobs::CleanUpUploads.new.execute(nil)

    expect(Upload.find_by(id: @upload.id)).to eq(nil)
    expect(Upload.find_by(id: upload.id)).to eq(upload)
  end

  it "does not delete user custom upload" do
    upload = fabricate_upload
    Fabricate(:user, user_avatar: Fabricate(:user_avatar, custom_upload: upload))

    Jobs::CleanUpUploads.new.execute(nil)

    expect(Upload.find_by(id: @upload.id)).to eq(nil)
    expect(Upload.find_by(id: upload.id)).to eq(upload)
  end

  it "does not delete uploads in a queued post" do
    upload = fabricate_upload

    QueuedPost.create(
      queue: "uploads",
      state: QueuedPost.states[:new],
      user_id: Fabricate(:user).id,
      raw: upload.sha1,
      post_options: {}
    )

    Jobs::CleanUpUploads.new.execute(nil)

    expect(Upload.find_by(id: @upload.id)).to eq(nil)
    expect(Upload.find_by(id: upload.id)).to eq(upload)
  end

  it "does not delete uploads in a draft" do
    upload = fabricate_upload
    Draft.set(Fabricate(:user), "test", 0, upload.sha1)

    Jobs::CleanUpUploads.new.execute(nil)

    expect(Upload.find_by(id: @upload.id)).to eq(nil)
    expect(Upload.find_by(id: upload.id)).to eq(upload)
  end

end
