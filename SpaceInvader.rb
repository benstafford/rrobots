require 'Invader'

class SpaceInvader < Invader
  def initialize
    @intent_heading = 0
    @name = "SpaceInvader"
    super
  end

  def tick events
    record_position y, x, battlefield_width, 90
    super events
  end

  def turn_radar_away_from_edge
    if radar_heading >= 270 or radar_heading< 90
      turn_radar -10 + radar_heading%10
    end

    if radar_heading >= 90 and radar_heading < 270
      turn_radar 10 - radar_heading%10
    end
  end


end