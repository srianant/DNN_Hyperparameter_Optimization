class UuidItem < ActiveRecord::Base
end

class UuidValidatingItem < UuidItem
  validates_uniqueness_of :uuid
end
