class AvatarLookup

  def initialize(user_ids=[])
    @user_ids = user_ids.tap(&:compact!).tap(&:uniq!).tap(&:flatten!)
  end

  # Lookup a user by id
  def [](user_id)
    users[user_id]
  end

  private

  def self.lookup_columns
    @lookup_columns ||= %i{id email username uploaded_avatar_id}
  end

  def users
    @users ||= user_lookup_hash
  end

  def user_lookup_hash
    # adding tap here is a personal taste thing
    hash = {}
    User.where(:id => @user_ids)
        .select(AvatarLookup.lookup_columns)
        .each{ |user| hash[user.id] = user }
    hash
  end
end
