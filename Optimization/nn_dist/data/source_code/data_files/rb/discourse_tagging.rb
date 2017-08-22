module DiscourseTagging

  TAGS_FIELD_NAME = "tags"
  TAGS_FILTER_REGEXP = /[\/\?#\[\]@!\$&'\(\)\*\+,;=\.%\\`^\s|\{\}"<>]+/ # /?#[]@!$&'()*+,;=.%\`^|{}"<>


  def self.tag_topic_by_names(topic, guardian, tag_names_arg)
    if SiteSetting.tagging_enabled
      tag_names = DiscourseTagging.tags_for_saving(tag_names_arg, guardian) || []

      old_tag_names = topic.tags.map(&:name) || []
      new_tag_names = tag_names - old_tag_names
      removed_tag_names = old_tag_names - tag_names

      # Protect staff-only tags
      unless guardian.is_staff?
        staff_tags = DiscourseTagging.staff_only_tags(new_tag_names)
        if staff_tags.present?
          topic.errors[:base] << I18n.t("tags.staff_tag_disallowed", tag: staff_tags.join(" "))
          return false
        end

        staff_tags = DiscourseTagging.staff_only_tags(removed_tag_names)
        if staff_tags.present?
          topic.errors[:base] << I18n.t("tags.staff_tag_remove_disallowed", tag: staff_tags.join(" "))
          return false
        end
      end

      if tag_names.present?
        category = topic.category
        tags = filter_allowed_tags(Tag.where(name: tag_names), guardian, { for_input: true, category: category, selected_tags: tag_names }).to_a

        if tags.size < tag_names.size && (category.nil? || category.tags.count == 0)
          tag_names.each do |name|
            unless Tag.where(name: name).exists?
              tags << Tag.create(name: name)
            end
          end
        end

        topic.tags = tags
      else
        topic.tags = []
      end
      topic.tags_changed=true
    end
    true
  end

  # Options:
  #   term: a search term to filter tags by name
  #   category: a Category to which the object being tagged belongs
  #   for_input: result is for an input field, so only show permitted tags
  #   selected_tags: an array of tag names that are in the current selection
  def self.filter_allowed_tags(query, guardian, opts={})
    term = opts[:term]
    if term.present?
      term.downcase!
      term.gsub!(/[^a-z0-9\.\-\_]*/, '')
      term.gsub!("_", "\\_")
      query = query.where('tags.name like ?', "%#{term}%")
    end

    # Filters for category-specific tags:
    category = opts[:category]

    if category && (category.tags.count > 0 || category.tag_groups.count > 0)
      if category.tags.count > 0 && category.tag_groups.count > 0
        tag_group_ids = category.tag_groups.pluck(:id)

        query = query.where(
          "tags.id IN (SELECT tag_id FROM category_tags WHERE category_id = ?
            UNION
            SELECT tag_id FROM tag_group_memberships WHERE tag_group_id IN (?))",
          category.id, tag_group_ids
        )
      elsif category.tags.count > 0
        query = query.where("tags.id IN (SELECT tag_id FROM category_tags WHERE category_id = ?)", category.id)
      else # category.tag_groups.count > 0
        tag_group_ids = category.tag_groups.pluck(:id)

        query = query.where("tags.id IN (SELECT tag_id FROM tag_group_memberships WHERE tag_group_id IN (?))", tag_group_ids)
      end
    elsif opts[:for_input] || category
      # exclude tags that are restricted to other categories
      if CategoryTag.exists?
        query = query.where("tags.id NOT IN (SELECT tag_id FROM category_tags)")
      end

      if CategoryTagGroup.exists?
        tag_group_ids = CategoryTagGroup.pluck(:tag_group_id).uniq
        query = query.where("tags.id NOT IN (SELECT tag_id FROM tag_group_memberships WHERE tag_group_id IN (?))", tag_group_ids)
      end
    end

    if opts[:for_input]
      selected_tag_ids = opts[:selected_tags] ? Tag.where(name: opts[:selected_tags]).pluck(:id) : []

      unless guardian.nil? || guardian.is_staff?
        staff_tag_names = SiteSetting.staff_tags.split("|")
        query = query.where('tags.name NOT IN (?)', staff_tag_names) if staff_tag_names.present?
      end

      # exclude tag groups that have a parent tag which is missing from selected_tags

      select_sql = <<-SQL
      SELECT tag_id
            FROM tag_group_memberships tgm
      INNER JOIN tag_groups tg
              ON tgm.tag_group_id = tg.id
      SQL

      if selected_tag_ids.empty?
        sql = "tags.id NOT IN (#{select_sql} WHERE tg.parent_tag_id IS NOT NULL)"
        query = query.where(sql)
      else
        # One tag per group restriction
        exclude_group_ids = TagGroup.where(one_per_topic: true)
                                    .joins(:tag_group_memberships)
                                    .where('tag_group_memberships.tag_id in (?)', selected_tag_ids)
                                    .pluck(:id)

        if exclude_group_ids.empty?
          sql = "tags.id NOT IN (#{select_sql} WHERE tg.parent_tag_id NOT IN (?))"
          query = query.where(sql, selected_tag_ids)
        else
          # It's possible that the selected tags violate some one-tag-per-group restrictions,
          # so filter them out by picking one from each group.
          limit_tag_ids = TagGroupMembership.select('distinct on (tag_group_id) tag_id')
                                            .where(tag_id: selected_tag_ids)
                                            .where(tag_group_id: exclude_group_ids)
                                            .map(&:tag_id)
          sql = "(tags.id NOT IN (#{select_sql} WHERE (tg.parent_tag_id NOT IN (?) OR tg.id in (?))) OR tags.id IN (?))"
          query = query.where(sql, selected_tag_ids, exclude_group_ids, limit_tag_ids)
        end
      end
    end

    query
  end

  def self.clean_tag(tag)
    tag.downcase.strip
       .gsub(/\s+/, '-').squeeze('-')
       .gsub(TAGS_FILTER_REGEXP, '')[0...SiteSetting.max_tag_length]
  end

  def self.staff_only_tags(tags)
    return nil if tags.nil?

    staff_tags = SiteSetting.staff_tags.split("|")

    tag_diff = tags - staff_tags
    tag_diff = tags - tag_diff

    tag_diff.present? ? tag_diff : nil
  end

  def self.tags_for_saving(tags_arg, guardian, opts={})

    return [] unless guardian.can_tag_topics? && tags_arg.present?

    tag_names = Tag.where(name: tags_arg).pluck(:name)

    if guardian.can_create_tag?
      tag_names += (tags_arg - tag_names).map { |t| clean_tag(t) }
      tag_names.delete_if { |t| t.blank? }
      tag_names.uniq!
    end

    return opts[:unlimited] ? tag_names : tag_names[0...SiteSetting.max_tags_per_topic]
  end

  def self.add_or_create_tags_by_name(taggable, tag_names_arg, opts={})
    tag_names = DiscourseTagging.tags_for_saving(tag_names_arg, Guardian.new(Discourse.system_user), opts) || []
    if taggable.tags.pluck(:name).sort != tag_names.sort
      taggable.tags = Tag.where(name: tag_names).all
      if taggable.tags.size < tag_names.size
        new_tag_names = tag_names - taggable.tags.map(&:name)
        new_tag_names.each do |name|
          taggable.tags << Tag.create(name: name)
        end
      end
    end
  end

  def self.muted_tags(user)
    return [] unless user
    TagUser.lookup(user, :muted).joins(:tag).pluck('tags.name')
  end
end
