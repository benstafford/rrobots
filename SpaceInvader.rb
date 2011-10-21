require 'robot'

class SpaceInvader
   include Robot

  def initialize
    @reached_north = false
    @intent_heading = 180
  end

  def tick events
    turn_radar 1 if time == 0
    start_by_heading_to_north_edge
    turn_around_if_not_going_right_direction
    always_point_gun_to_south
    turn_radar_south
    broadcast "SpaceInvader"
    fire_stream_but_dont_hit_friend
    when_going_correct_direction_full_speed
    reaching_west_edge_turn_east
    reaching_east_edge_turn_west
  end

private
  def start_by_heading_to_north_edge
    if @reached_north == false
      accelerate 1
      if heading != 90
        turn 10 - heading%10
      end
    end
  end

  def turn_around_if_not_going_right_direction
    if y <= size + 1
      @reached_north = true
    end
    if @reached_north and heading!=@intent_heading
      stop
      turn 10 - heading%10
    end
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
        if radar_heading < 300
            turn_radar 30
        end
        if radar_heading > 300
            turn_radar -30
        end
    else
        if radar_heading < 240
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
          fire 0.1
        #end
      end
    else
      fire 0.1
    end
  end

  def when_going_correct_direction_full_speed
    if @reached_north and heading==@intent_heading
        accelerate 1
    end
  end

  def reaching_west_edge_turn_east
    if @reached_north and heading==@intent_heading and heading == 180 and x <= size + 1
        @intent_heading = 0
    end
  end

  def reaching_east_edge_turn_west
    if @reached_north and heading==@intent_heading and heading == 0 and x >= battlefield_width - size
        @intent_heading = 180
    end
  end

end