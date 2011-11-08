require 'Invader'

class VerticalInvader < Invader
  def initialize
    @intent_heading = 270
    super
  end

  def tick events
    record_position x, y, battlefield_height, 180
    super events
  end

  def turn_radar_away_from_edge
    if radar_heading >= 0 and radar_heading< 180
      turn_radar -10 + radar_heading%10
    end

    if radar_heading >= 180
      turn_radar 10 - radar_heading%10
    end
  end

  def get_scan_loc distance
      Point.new(@distance_to_edge + distance, @position_on_edge)
  end

  def get_target_position enemy
    return enemy.y
  end


  def check_top_corner?
   if ((gun_heading > 270) or (gun_heading < 90))
     turn_gun -30 + gun_heading%30
     return true
   else
     if (gun_heading != 270)
       turn_gun 30 - gun_heading%30
       return true
     end
   end
   if (gun_heading == 270)
     if time - 5 > @last_scan_time
       return false
     end
     fire 0.1
     return true
   end
   false
  end

  def check_bottom_corner?
   if ((gun_heading > 90) or (gun_heading < 270))
     turn_gun -30 + gun_heading%30
     return true
   else
     if (gun_heading != 90)
       turn_gun 30 - gun_heading%30
       return true
     end
   end
   if (gun_heading == 90)
     if time - 5 > @last_scan_time
       return false
     end
     fire 0.1
     return true
   end
   false
  end
end