module Docs
  class Marionette < UrlScraper
    self.name = 'Marionette.js'
    self.slug = 'marionette'
    self.type = 'marionette'
    self.root_path = 'index'
    self.links = {
      home: 'https://marionettejs.com/',
      code: 'https://github.com/marionettejs/backbone.marionette'
    }

    html_filters.push 'marionette/clean_html'

    options[:container] = '.docs__content'

    options[:attribution] = <<-HTML
      &copy; 2016 Muted Solutions, LLC<br>
      Licensed under the MIT License.
    HTML

    version '3' do
      self.release = '3.1.0'
      self.base_url = "https://marionettejs.com/docs/v#{release}/"

      html_filters.push 'marionette/entries_v3'
    end

    version '2' do
      self.release = '2.4.7'
      self.base_url = "https://marionettejs.com/docs/v#{release}/"

      html_filters.push 'marionette/entries_v2'
    end
  end
end
