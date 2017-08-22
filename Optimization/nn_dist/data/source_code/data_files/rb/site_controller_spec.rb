require 'rails_helper'

describe SiteController do
  describe '.basic_info' do

    it 'is visible always even for sites requiring login' do
      SiteSetting.login_required = true

      SiteSetting.title = "Hammer Time"
      SiteSetting.site_description= "A time for Hammer"
      SiteSetting.logo_url = "/uploads/logo.png"
      SiteSetting.logo_small_url = "http://boom.com/uploads/logo_small.png"
      SiteSetting.apple_touch_icon_url = "https://boom.com/apple/logo.png"
      SiteSetting.mobile_logo_url = "https://a.a/a.png"

      xhr :get, :basic_info
      json = JSON.parse(response.body)

      expect(json["title"]).to eq("Hammer Time")
      expect(json["description"]).to eq("A time for Hammer")
      expect(json["logo_url"]).to eq("http://test.localhost/uploads/logo.png")
      expect(json["apple_touch_icon_url"]).to eq("https://boom.com/apple/logo.png")
      expect(json["logo_small_url"]).to eq("http://boom.com/uploads/logo_small.png")
      expect(json["mobile_logo_url"]).to eq("https://a.a/a.png")
    end
  end
end
