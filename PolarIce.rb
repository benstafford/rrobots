require 'robot'
require 'Matrix'

class PolarIce
  include Robot

  def tick events
     initialize_tick
     perform_actions
  end

  def initialize_tick
    @currentPosition = Vector[x,y]
  end

  def perform_actions
    turn @hullRotation
    turn_gun @gunRotation
    turn_radar @radarRotation
    accelerate @accelerationRate
    fire @firePower
    broadcast @broadcastMessage
    say @quote
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

  def firePower
    @firePower
  end

  def firePower=(power)
    @firePower = power
  end

  def broadcastMessage
    @broadcastMessage
  end

  def broadcastMessage=(message)
    @broadcastMessage = message
  end

  def quote
    @quote
  end

  def quote=(message)
    @quote = message
  end

  def initialize
    @accelerationRate = 0
    @hullRotation = 0
    @gunRotation = 0
    @radarRotation = 0
    @firePower = 0
    @broadcastMessage = ""
    @quote = "quote"
  end
end
