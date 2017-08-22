class Car < ActiveRecord::Base
  has_many :bulbs
  has_many :all_bulbs, -> { unscope where: :name }, class_name: "Bulb"
  has_many :funky_bulbs, class_name: "FunkyBulb", dependent: :destroy
  has_many :failed_bulbs, class_name: "FailedBulb", dependent: :destroy
  has_many :foo_bulbs, -> { where(name: "foo") }, class_name: "Bulb"
  has_many :awesome_bulbs, -> { awesome }, class_name: "Bulb"

  has_one :bulb

  has_many :tyres
  has_many :engines, dependent: :destroy, inverse_of: :my_car
  has_many :wheels, as: :wheelable, dependent: :destroy

  has_many :price_estimates, as: :estimate_of

  scope :incl_tyres, -> { includes(:tyres) }
  scope :incl_engines, -> { includes(:engines) }

  scope :order_using_new_style,  -> { order("name asc") }
end

class CoolCar < Car
  default_scope { order("name desc") }
end

class FastCar < Car
  default_scope { order("name desc") }
end
