module Docs
  class Css < Mdn
    self.name = 'CSS'
    self.base_url = 'https://developer.mozilla.org/en-US/docs/Web/CSS'
    self.root_path = '/Reference'

    html_filters.push 'css/clean_html', 'css/entries', 'title'

    options[:root_title] = 'CSS'

    options[:skip] = %w(/CSS3 /Media/Visual /paged_media)
    options[:skip] += %w(/mq-boolean /single-transition-timing-function) # bug
    options[:skip_patterns] = [/Extensions/, /Tools/, /@media\/-webkit/, /webkit-mask/, /-moz-system-metric/]

    options[:replace_paths] = {
      '/%3Cbasic-shape%3E' => '/basic-shape',
      '/fallback' => '/@counter-style/fallback',
      '/range' => '/@counter-style/range',
      '/symbols' => '/@counter-style/symbols',
      '/system' => '/@counter-style/system',
      '/var' => '/var()',
      '/Flexbox' => '/CSS_Flexible_Box_Layout/Using_CSS_flexible_boxes'
    }

    options[:fix_urls] = ->(url) do
      url.sub! %r{https://developer\.mozilla\.org/en\-US/docs/CSS/([\w\-@:])}, "#{Css.base_url}/\\1"
      url.sub! '%3A', ':'
      url.sub! '%40', '@'
      url
    end
  end
end
