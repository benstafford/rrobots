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

  def initialize
    @accelerationRate = 0
    @hullRotation = 0
    @gunRotation = 0
    @radarRotation = 0
    @firePower = 0
    @broadcastMessage = ""
    @quote = "quote"
  end

  attr_reader(:currentPosition)
  attr_accessor(:accelerationRate)
  attr_accessor(:hullRotation)
  attr_accessor(:gunRotation)
  attr_accessor(:radarRotation)
  attr_accessor(:firePower)
  attr_accessor(:broadcastMessage)
  attr_accessor(:quote)
end
