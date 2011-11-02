require 'robot'

class Invader
   include Robot
  attr_accessor :last_scan_time
  attr_accessor :last_scan_pursued
  attr_accessor :distance_to_edge
  attr_accessor :position_on_edge
  attr_accessor :width_of_edge
  attr_accessor :heading_of_edge
  attr_accessor :name
  attr_accessor :intent_heading
  attr_accessor :currrent_direction

  def initialize
    @current_direction = 1
    @last_scan_time = 0
  end

  def record_position distance_to_edge, position_on_edge, width_of_edge, heading_of_edge
    @distance_to_edge = distance_to_edge
    @position_on_edge = position_on_edge
    @width_of_edge = width_of_edge
    @heading_of_edge = heading_of_edge
  end

  def tick events
    if events['robot_scanned'].count>0
      scan = events['robot_scanned'].pop.first
      broadcast scan
      if (events['broadcasts'].count > 0)
        if (@position_on_edge > size * 2)
          @last_scan_time = time
          @last_scan_pursued = false
        end
      else
        @last_scan_time = time
        @last_scan_pursued = false
      end
    else
      broadcast "I'm at #{@position_on_edge}"
    end

    if at_edge?
      if !get_heading_from_friend? events['broadcasts']
        check_recent_radar
      end
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
  def get_heading_from_friend? broadcast_events
    if broadcast_events.count > 0
      target_loc = broadcast_events[0].first.to_f
      if target_loc > 0
        if target_loc < @position_on_edge - size
          say "Coming Buddy!"
          @current_direction = -8
        else
          "Hold on, I'll get him!'"
          if target_loc > @position_on_edge + size
            @current_direction = 8
          end
        end
        true
      end
    end
    false
  end

  def check_recent_radar
    if time - 5 > @last_scan_time and @last_scan_pursued == false
      @current_direction = 0 - @current_direction
      @last_scan_pursued = true
    end
  end


  def at_edge?
    @distance_to_edge <= (size + 1)
  end

  def head_to_edge
    accelerate 8
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
    direction = opposite_edge
    if gun_heading < direction
        turn_gun 30
    end
    if gun_heading > direction
        turn_gun -30
    end
  end

  def fire_stream_but_dont_hit_friend
    if (events['broadcasts'].count > 0)
      if (@position_on_edge > size * 2)
        fire 0.2
      end
    else
      fire 0.2
    end
  end

  def full_speed_ahead
      accelerate @current_direction
  end

  def turn_radar_away_from_edge

  end

  def reaching_bottom_edge_turn_around
    if @current_direction < 0 and @position_on_edge <= size + 1
      @current_direction = 8
    end
  end

  def reaching_top_edge_turn_around
    if @current_direction > 0 and @position_on_edge >= @width_of_edge - size
      @current_direction = -8
    end
  end

  def opposite_edge
    direction = @heading_of_edge + 180
    if direction >= 360
      direction -= 360
    end
    direction
  end

end