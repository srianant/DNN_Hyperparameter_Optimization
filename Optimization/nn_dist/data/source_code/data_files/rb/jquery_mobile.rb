module Docs
  class JqueryMobile < Jquery
    self.name = 'jQuery Mobile'
    self.slug = 'jquerymobile'
    self.release = '1.4.5'
    self.base_url = 'https://api.jquerymobile.com'
    self.root_path = '/category/all'

    html_filters.insert_before 'jquery/clean_html', 'jquery_mobile/entries'

    options[:root_title] = 'jQuery Mobile'
    options[:skip] = %w(/tabs /theme)
    options[:skip_patterns].concat [/\A\/icons/, /cdn-cgi/i]
    options[:replace_paths] = { '/select/' => '/selectmenu' }

    options[:fix_urls] = ->(url) do
      url.sub! 'http://api.jquerymobile.com/', 'https://api.jquerymobile.com/'
    end
  end
end
