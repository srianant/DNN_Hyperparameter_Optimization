class ReplyByEmailAddressValidator
  def initialize(opts={})
    @opts = opts
  end

  def valid_value?(val)
    return true if val.blank?

    !!val["@"] &&
    !!val["%{reply_key}"] &&
    val.gsub(/\+?%{reply_key}/, "") != SiteSetting.notification_email
  end

  def error_message
    I18n.t('site_settings.errors.invalid_reply_by_email_address')
  end
end
