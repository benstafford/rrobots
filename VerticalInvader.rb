require 'robot'

class VerticalInvader
   include Robot

  def initialize
    @reached_west = false
    @intent_heading = 90
  end

  def tick events
    start_by_heading_to_west_edge
    turn_around_if_not_going_right_direction
    always_point_gun_to_east
    broadcast "VerticalInvader"
    fire_stream_but_dont_hit_friend
    when_going_correct_direction_full_speed
    reaching_west_edge_turn_east
    reaching_east_edge_turn_west
  end

private
  def start_by_heading_to_west_edge
    if @reached_west == false
      accelerate 1
      if heading != 180
        turn 10 - heading%10
      end
    end
  end

  def turn_around_if_not_going_right_direction
    if x <= size + 1
      @reached_west = true
    end
    if @reached_west and heading!=@intent_heading
      stop
      turn 10 - heading%10
    end
  end

  def always_point_gun_to_east
    if gun_heading < 0
        turn_gun 30
    end
    if gun_heading > 0
        turn_gun -30
    end
  end

  def fire_stream_but_dont_hit_friend
    if (events['broadcasts'].count > 0)
      if (y > size * 2)
        fire 0.1
      end
    else
      fire 0.1
    end
  end

  def when_going_correct_direction_full_speed
    if @reached_west and heading==@intent_heading
        accelerate 1
    end
  end

  def reaching_west_edge_turn_east
    if @reached_west and heading==@intent_heading and heading == 90 and y <= size + 1
        @intent_heading = 270
    end
  end

  def reaching_east_edge_turn_west
    if @reached_west and heading==@intent_heading and heading == 270 and y >= battlefield_height - size
        @intent_heading = 90
    end
  end
end