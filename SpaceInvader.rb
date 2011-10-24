require 'robot'

class SpaceInvader
   include Robot

  def initialize
    @reached_north = false
    @intent_heading = 180
  end

  def tick events
    turn_radar 1 if time == 0
    broadcast "SpaceInvader"
    if at_north_edge?
      if need_to_turn?
        turn_around
      else
        full_speed_ahead
        always_point_gun_to_south
        turn_radar_south
        fire_stream_but_dont_hit_friend
        reaching_west_edge_turn_east
        reaching_east_edge_turn_west
      end
    else
      head_to_north_edge
    end
  end

private

  def at_north_edge?
    y <= (size + 1)
  end

  def head_to_north_edge
    accelerate 1
    if heading != 90
      turn 10 - heading%10
    end
  end

  def need_to_turn?
    heading!=@intent_heading
  end

  def turn_around
      stop
      turn 10 - heading%10
  end

  def always_point_gun_to_south
    if gun_heading < 270
        turn_gun 30
    end
    if gun_heading > 270
        turn_gun -30
    end
  end

  def turn_radar_south
    if heading == 0
        if radar_heading <= 300
            turn_radar 30
        end
        if radar_heading > 300
            turn_radar -30
        end
    else
        if radar_heading <= 240
            turn_radar 30
        end
       if radar_heading > 240
            turn_radar -30
        end
    end
  end


  def fire_stream_but_dont_hit_friend
    if (events['broadcasts'].count > 0)
      if (x > size * 2)
        #if (!events['robot_scanned'].empty?)
        #  fire 3
        #else
          fire 0.1
        #end
      end
    else
      fire 0.1
    end
  end

  def full_speed_ahead
      accelerate 1
  end

  def reaching_west_edge_turn_east
    if heading == 180 and x <= size + 1
        @intent_heading = 0
    end
  end

  def reaching_east_edge_turn_west
    if heading == 0 and x >= battlefield_width - size
        @intent_heading = 180
    end
  end

end