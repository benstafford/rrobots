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
    if @current_direction > 0
        if radar_heading <= 280
            turn_radar 10
        end
        if radar_heading > 280
            turn_radar -10
        end
    else
        if radar_heading <= 260
            turn_radar 10
        end
       if radar_heading > 260
            turn_radar -10
        end
    end
  end


end