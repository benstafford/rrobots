#The Loader is responsible for determining the fire power to use in the gun.
class Loader
  def tick
  end

  MINIMUM_FIRE_POWER = 0.0
  MAXIMUM_FIRE_POWER = 3.0

  INITIAL_FIRE_POWER = 0.3

  def initialize
    @power = INITIAL_FIRE_POWER
  end

  attr_accessor(:power)
end
