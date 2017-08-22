module CategoryBadge

  def self.category_stripe(color, classes)
    style = color ? "style='background-color: ##{color};'" : ''
    "<span class='#{classes}' #{style}></span>"
  end

  def self.inline_category_stripe(color, styles = '', insert_blank = false)
    "<span style='background-color: ##{color};#{styles}'>#{insert_blank ? '&nbsp;' : ''}</span>"
  end

  def self.inline_badge_wrapper_style
    style = case (SiteSetting.category_style || :box).to_sym
            when :bar then 'line-height: 1.25; margin-right: 5px;'
            when :box then 'line-height: 1.5; margin-top: 5px; margin-right: 5px;'
            when :bullet then 'line-height: 1; margin-right: 10px;'
            end
    " style='font-size: 0.857em; white-space: nowrap; display: inline-block; position: relative; #{style}'"
  end

  def self.html_for(category, opts = nil)
    opts = opts || {}

    # If there is no category, bail
    return "" if category.blank?

    # By default hide uncategorized
    return "" if category.uncategorized? && !opts[:show_uncategorized]

    extra_classes = "#{opts[:extra_classes]} #{SiteSetting.category_style}"

    result = ''

    # parent span
    unless category.parent_category_id.nil? || opts[:hide_parent]
      parent_category = Category.find_by(id: category.parent_category_id)
      result << if opts[:inline_style]
        case (SiteSetting.category_style || :box).to_sym
        when :bar then inline_category_stripe(parent_category.color, 'display: inline-block; padding: 1px;', true)
        when :box then inline_category_stripe(parent_category.color, 'display: block; position: absolute; width: 100%; height: 100%;')
        when :bullet then inline_category_stripe(parent_category.color, 'display: inline-block; width: 5px; height: 10px; line-height: 1;')
        end
      else
        category_stripe(parent_category.color, 'badge-category-parent-bg')
      end
    end

    # sub parent or main category span
    result << if opts[:inline_style]
      case (SiteSetting.category_style || :box).to_sym
      when :bar then inline_category_stripe(category.color, 'display: inline-block; padding: 1px;', true)
      when :box then inline_category_stripe(category.color, 'left: 5px; display: block; position: absolute; width: calc(100% - 5px); height: 100%;')
      when :bullet then inline_category_stripe(category.color, "display: inline-block; width: #{category.parent_category_id.nil? ? 10 : 5}px; height: 10px;")
      end
    else
      category_stripe(category.color, 'badge-category-bg')
    end

    # category name
    class_names = 'badge-category clear-badge'
    text_color = "##{category.text_color}"
    description = category.description_text ? "title='#{category.description_text.html_safe}'" : ''
    category_url = opts[:absolute_url] ? "#{Discourse.base_url_no_prefix}#{category.url}" : category.url

    extra_span_classes = if opts[:inline_style]
        case (SiteSetting.category_style || :box).to_sym
        when :bar then 'padding: 3px; color: #222222 !important; vertical-align: text-top; margin-top: -3px; display: inline-block;'
        when :box then 'margin-left: 5px; position: relative; padding: 0 5px; margin-top: 2px;'
        when :bullet then 'color: #222222 !important; vertical-align: text-top; line-height: 1; margin-left: 4px; padding-left: 2px; display: inline;'
        end + 'max-width: 150px; overflow: hidden; text-overflow: ellipsis;'
      else
        ''
      end
    result << "<span style='color: #{text_color};#{extra_span_classes}' data-drop-close='true' class='#{class_names}'
                 #{description}>"

    result << category.name.html_safe << '</span>'
    "<a class='badge-wrapper #{extra_classes}' href='#{category_url}'" + (opts[:inline_style] ? inline_badge_wrapper_style : '') + ">#{result}</a>"
  end
end
