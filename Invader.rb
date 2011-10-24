require 'robot'

class Invader
   include Robot

  attr_state :distance_to_edge
  attr_state :position_on_edge
  attr_state :width_of_edge
  attr_state :heading_of_edge

  def initialize
    @intent_heading = 180
  end

  def record_position distance_to_edge, position_on_edge, width_of_edge, heading_of_edge
    @distance_to_edge = distance_to_edge
    @position_on_edge = position_on_edge
    @width_of_edge = width_of_edge
    @heading_of_edge = heading_of_edge
  end

  def process_tick events, name
    turn_radar 1 if time == 0
    broadcast name
    if at_edge?
      if need_to_turn?
        turn_around
      else
        full_speed_ahead
        point_gun_away_from_edge
        turn_radar_away_from_edge
        fire_stream_but_dont_hit_friend
        reaching_bottom_edge_turn_around
        reaching_top_edge_turn_around
      end
    else
      head_to_edge
    end
  end

private

  def at_edge?
    @distance_to_edge <= (size + 1)
  end

  def head_to_edge
    accelerate 1
    if heading != @heading_of_edge
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

  def point_gun_away_from_edge
    direction = 360 - @heading_of_edge
    if gun_heading < direction
        turn_gun 30
    end
    if gun_heading > direction
        turn_gun -30
    end
  end

  def turn_radar_away_from_edge
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
      if (@position_on_edge > size * 2)
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

  def reaching_bottom_edge_turn_around
    if heading == @heading_of_edge + 90 and @position_on_edge <= size + 1
        @intent_heading = @heading_of_edge - 90
    end
  end

  def reaching_top_edge_turn_around
    if heading == @heading_of_edge - 90 and @position_on_edge >= @width_of_edge - size
        @intent_heading = @heading_of_edge + 90
    end
  end

end