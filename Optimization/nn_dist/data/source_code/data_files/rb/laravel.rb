module Docs
  class Laravel < UrlScraper
    self.name = 'Laravel'
    self.slug = 'laravel'
    self.type = 'laravel'

    self.base_url = 'https://laravel.com'

    self.links = {
      home: 'https://laravel.com/',
      code: 'https://github.com/laravel/laravel'
    }

    html_filters.push 'laravel/entries', 'laravel/clean_html'

    options[:container] = ->(filter) {
      filter.subpath.start_with?('/api') ? '#content' : '.docs-wrapper'
    }

    options[:skip_patterns] = [
      %r{\A/api/\d\.\d/\.html},
      %r{\A/api/\d\.\d/panel\.html},
      %r{\A/api/\d\.\d/namespaces\.html},
      %r{\A/api/\d\.\d/interfaces\.html},
      %r{\A/api/\d\.\d/traits\.html},
      %r{\A/api/\d\.\d/doc-index\.html},
      %r{\A/api/\d\.\d/Illuminate\.html},
      %r{\A/api/\d\.\d/search\.html} ]

    options[:attribution] = <<-HTML
      &copy; Taylor Otwell<br>
      Licensed under the MIT License.<br>
      Laravel is a trademark of Taylor Otwell.
    HTML

    version '5.3' do
      self.release = '5.3.15'
      self.root_path = '/api/5.3/index.html'
      self.initial_paths = %w(/docs/5.3/installation /api/5.3/classes.html)

      options[:only_patterns] = [%r{\A/api/5\.3/}, %r{\A/docs/5\.3/}]

      options[:fix_urls] = ->(url) do
        url.sub! %r{#{Regexp.escape(Laravel.base_url)}/docs\/(?!\d)}, "#{Laravel.base_url}/docs/5.3/"
        url
      end
    end

    version '5.2' do
      self.release = '5.2.31'
      self.root_path = '/api/5.2/index.html'
      self.initial_paths = %w(/docs/5.2/installation /api/5.2/classes.html)

      options[:only_patterns] = [%r{\A/api/5\.2/}, %r{\A/docs/5\.2/}]

      options[:fix_urls] = ->(url) do
        url.sub! %r{#{Regexp.escape(Laravel.base_url)}/docs\/(?!\d)}, "#{Laravel.base_url}/docs/5.2/"
        url
      end
    end

    version '5.1' do
      self.release = '5.1.33'
      self.root_path = '/api/5.1/index.html'
      self.initial_paths = %w(/docs/5.1/installation /api/5.1/classes.html)

      options[:only_patterns] = [%r{\A/api/5\.1/}, %r{\A/docs/5\.1/}]

      options[:fix_urls] = ->(url) do
        url.sub! %r{#{Regexp.escape(Laravel.base_url)}/docs\/(?!\d)}, "#{Laravel.base_url}/docs/5.1/"
        url
      end
    end
  end
end
