module Docs
  class Knockout < UrlScraper
    self.name = 'Knockout.js'
    self.slug = 'knockout'
    self.type = 'knockout'
    self.release = '3.4.0'
    self.base_url = 'http://knockoutjs.com/documentation/'
    self.root_path = 'introduction.html'

    html_filters.push 'knockout/clean_html', 'knockout/entries'

    options[:follow_links] = ->(filter) { filter.root_page? }
    options[:container] = ->(filter) { filter.root_page? ? '#wrapper' : '.content' }

    options[:only] = %w(
      json-data.html
      extenders.html
      deferred-updates.html
      unobtrusive-event-handling.html
      microtasks.html
      asynchronous-error-handling.html
      fn.html
      amd-loading.html)

    options[:only_patterns] = [
      /observable/i,
      /computed/i,
      /component/i,
      /binding/,
      /plugin/]

    options[:attribution] = <<-HTML
      &copy; Steven Sanderson, the Knockout.js team, and other contributors<br>
      Licensed under the MIT License.
    HTML
  end
end
