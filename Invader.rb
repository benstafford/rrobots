require 'robot'

class Invader
   include Robot

  attr_accessor :distance_to_edge
  attr_accessor :position_on_edge
  attr_accessor :width_of_edge
  attr_accessor :heading_of_edge
  attr_accessor :heading_of_bottom_edge
  attr_accessor :heading_of_top_edge
  attr_accessor :direction_of_turn

  def initialize
    @direction_of_turn = 10
  end

  def record_position distance_to_edge, position_on_edge, width_of_edge, heading_of_edge, bottom_edge, top_edge
    @distance_to_edge = distance_to_edge
    @position_on_edge = position_on_edge
    @width_of_edge = width_of_edge
    @heading_of_edge = heading_of_edge
    @heading_of_bottom_edge = bottom_edge
    @heading_of_top_edge = top_edge
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
      turn @direction_of_turn - heading%@direction_of_turn
  end

  def point_gun_away_from_edge
    direction = opposite_edge
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
    if heading == @heading_of_bottom_edge and @position_on_edge <= size + 1
      if heading == left
        @direction_of_turn = -10
      else
        @direction_of_turn = 10
      end
      @intent_heading = @heading_of_top_edge
    end
  end

  def reaching_top_edge_turn_around
    if heading == @heading_of_top_edge  and @position_on_edge >= @width_of_edge - size
      if heading == left
        @direction_of_turn = -10
      else
        @direction_of_turn = 10
      end
      @intent_heading = @heading_of_bottom_edge
    end
  end

  def opposite_edge
    direction = @heading_of_edge + 180
    if direction >= 360
      direction -= 360
    end
    direction
  end

  def left
    result = heading_of_edge + 90
    if result >= 360
      result -= 360
    end
    result
  end

  def right
    result = heading_of_edge - 90
    if result < 0
      result += 360
    end
  end

end