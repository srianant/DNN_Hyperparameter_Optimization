class Electron < ActiveRecord::Base
  belongs_to :molecule

  validates_presence_of :name
end
