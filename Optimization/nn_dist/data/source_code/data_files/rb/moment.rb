module Docs
  class Moment < UrlScraper
    self.name = 'Moment.js'
    self.slug = 'moment'
    self.type = 'moment'
    self.release = '2.15.2'
    self.base_url = 'http://momentjs.com/docs/'

    html_filters.push 'moment/clean_html', 'moment/entries', 'title'

    options[:title] = 'Moment.js'
    options[:container] = '.docs-content'
    options[:skip_links] = true

    options[:attribution] = <<-HTML
      &copy; 2011&ndash;2016 Tim Wood, Iskren Chernev, Moment.js contributors<br>
      Licensed under the MIT License.
    HTML
  end
end
