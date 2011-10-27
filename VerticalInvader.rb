require 'Invader'

class VerticalInvader < Invader
  def initialize
    @intent_heading = 270
    @name = "VerticalInvader"
    super
  end

  def tick events
    record_position x, y, battlefield_height, 180
    super events
  end

  def turn_radar_away_from_edge
    if @current_direction < 0
        if radar_heading <= 10
            turn_radar 10
        end
        if radar_heading > 10
            turn_radar -10
        end
    else
        if radar_heading <= 350 and radar_heading > 0
            turn_radar 10
        end
       if radar_heading > 350 or radar_heading == 0
            turn_radar -10
        end
    end
  end
end