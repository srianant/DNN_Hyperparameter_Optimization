require "enum_site_setting"

class CategoryPageStyle < EnumSiteSetting

  def self.valid_value?(val)
    values.any? { |v| v[:value].to_s == val.to_s }
  end

  def self.values
    @values ||= [
      { name: 'category_page_style.categories_only', value: 'categories_only' },
      { name: 'category_page_style.categories_with_featured_topics', value: 'categories_with_featured_topics' },
      { name: 'category_page_style.categories_and_latest_topics', value: 'categories_and_latest_topics' },
    ]
  end

  def self.translate_names?
    true
  end

end
