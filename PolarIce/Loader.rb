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

module LoaderAccessor
  def desiredLoaderPower
    loader.power
  end

  def desiredLoaderPower= power
    loader.power = power
  end
  attr_accessor(:loader)
end
