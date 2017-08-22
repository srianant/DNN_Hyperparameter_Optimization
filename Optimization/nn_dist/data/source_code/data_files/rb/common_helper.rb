module CommonHelper
  def render_google_universal_analytics_code
    if Rails.env.production? && SiteSetting.ga_universal_tracking_code.present?
      render partial: "common/google_universal_analytics"
    end
  end

  def render_google_analytics_code
    if Rails.env.production? && SiteSetting.ga_tracking_code.present?
      render partial: "common/google_analytics"
    end
  end

  def render_google_tag_manager_code
    if Rails.env.production? && SiteSetting.gtm_container_id.present?
      render partial: "common/google_tag_manager"
    end
  end
end
