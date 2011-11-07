require 'robot'

class LcfVersion01
   include Robot

  def tick events
    #if @is_master.nil?
      broadcast "Master?"
    #end

    unless events.empty?
      puts "#{events.inspect}"
      say "Inconceivable!" if got_hit(events)
      if (events['broadcasts'].count > 0)
        puts "#{events['broadcasts'].inspect}"
      end
    end

    if energy > 90
      sniper_mode
      if time == 0 then
        turn_radar 15
      else
        turn_radar 30 - (60 * (time % 2))
      end
    else
      turn_radar 1 if time == 0
      turn_gun 30 if time < 3
      accelerate 1
      turn 2
      fire 3 unless events['robot_scanned'].empty?
      broadcast "LcfVersion01"
      #say "#{events['broadcasts'].inspect}"
    end
  end

  def got_hit(events)
    return events.has_key? "got_hit"
  end
  def sniper_mode
    go_to_nearest_corner
    fire_last_found
  end

  def go_to_nearest_corner
    clipping_offset = 60

    accelerate 1
    if @battlefield_width.to_i / 2 < x then
      x_corner = @battlefield_width - clipping_offset
    else
      x_corner = 0 + clipping_offset
    end
    if @battlefield_height.to_i / 2 < y then
      y_corner = @battlefield_height - clipping_offset
    else
      y_corner = 0 + clipping_offset
    end
    go_to_location x_corner, y_corner
  end

  def go_to_location x, y
    if((get_x == x) && get_y == y)
      unless speed == 0
        stop
        say "Stopped"
      end
    else
      #puts "Current Location #{get_x}, #{get_y}"
      #puts "Trying to go to #{x}, #{y}"

      if(get_angle_to_location(x,y) == heading)
        accelerate 1 #unless speed > 0
       else
        turn (get_angle_to_location x, y) - heading
       end
    end
  end

  def get_angle_to_location x, y
    angle = Math.atan2(get_y - y, x - get_x) / Math::PI * 180 % 360
    #puts "Angle to location #{x},#{y} == #{angle}"
    return angle
  end

  def get_x
    x
  end

  def get_y
    y
  end

  def fire_last_found
    turn_radar 5 if time == 0
    fire 3 unless events['robot_scanned'].empty?
    turn_gun 10
  end

end