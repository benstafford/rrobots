require 'Invader'

class SpaceInvader < Invader
  def initialize
    @intent_heading = 0
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

  def get_target_position enemy
    return enemy.x
  end


  def check_top_corner?
   if (gun_heading <180)
     turn_gun -30 + gun_heading%30
     return true
   else
     if (gun_heading != 0)
       turn_gun 30 - gun_heading%30
       return true
     end
   end
   if (gun_heading == 0)
     if time - 5 > @last_scan_time
       return false
     end
     fire 0.1
     return true
   end
   false
  end

  def check_bottom_corner?
   if (gun_heading > 180)
     turn_gun -30 + gun_heading%30
     return true
   else
     if (gun_heading != 180)
       turn_gun 30 - gun_heading%30
       return true
     end
   end
   if (gun_heading == 180)
     if time - 5 > @last_scan_time
       return false
     end
     fire 0.1
     return true
   end
   false
  end

end