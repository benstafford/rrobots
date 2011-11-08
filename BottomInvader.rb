require 'Invader'

class BottomInvader < Invader
  def initialize
    @intent_heading = 0
    @name = "SpaceInvader"
    super
  end

  def tick events
    record_position battlefield_height - y, x, battlefield_width, 270
    super events
  end

  def turn_radar_away_from_edge
    if radar_heading >= 90 and radar_heading< 270
      turn_radar -10 + radar_heading%10
    else
      turn_radar 10 - radar_heading%10
    end
  end
end