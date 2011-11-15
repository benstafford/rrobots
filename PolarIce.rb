require 'robot'
require 'Matrix'

class PolarIce
   include Robot

  def initialize
    @accelerationRate = 0
    @hullRotation = 0
    @gunRotation = 0
    @radarRotation = 0
  end

  def tick events
     init_on_tick
     move
  end

  def init_on_tick
    @currentPosition = Vector[x, y]
  end

  def move
    turn @hullRotation
    turn_gun @gunRotation
    turn_radar @radarRotation
    accelerate @accelerationRate
  end

  def currentPosition
    @currentPosition
  end

  def accelerationRate
    @accelerationRate
  end

  def accelerationRate=(rate)
    @accelerationRate = rate
  end

  def hullRotation
    @hullRotation
  end

  def hullRotation=(rotation)
    @hullRotation = rotation
  end

  def gunRotation
    @gunRotation
  end

  def gunRotation=(rotation)
   @gunRotation = rotation
  end

  def radarRotation
    @radarRotation
  end

  def radarRotation=(rotation)
    @radarRotation = rotation
  end
end