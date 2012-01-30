require 'robot'

class LazerBotLcf
  include Robot
  @@number_classes_initialized = 0
  @@was_here = 2
  @@master_x_destination = -1.0
  @@master_y_destination = -1.0
  @@slave_x_destination = -1.0
  @@slave_y_destination = -1.0
  @@master_x_location = -1.0
  @@master_y_location = -1.0
  @@slave_x_location = -1.0
  @@slave_y_location = -1.0
  @@master_x_target = -1.0
  @@master_y_target = -1.0
  @@slave_x_target = -1.0
  @@slave_y_target = -1.0

  def initialize
    @@number_classes_initialized = @@number_classes_initialized + 1
    @x_destination = -1.0
    @y_destination = -1.0
    @x_target = -1.0
    @y_target = -1.0
    @clipping_offset = 60
    @ticks_last_robot_scanned = 0
    @pair_is_alive = 1
    @radar_scan_direction = 1
    @current_scan_angle = 60
    @times_scanned_half = 0
    @@was_here = 2

    if @@number_classes_initialized % 2 == 1
      @is_master = 1
      @@master_x_location = x.to_f
      @@master_y_location = y.to_f
      @@master_x_destination = -1.0
      @@master_y_destination = -1.0
      @@master_x_target = -1.0
      @@master_y_target = -1.0
    else
      @is_master = 0
      @@slave_x_location = x.to_f
      @@slave_y_location = y.to_f
      @@slave_x_destination = -1.0
      @@slave_y_destination = -1.0
      @@slave_x_target = -1.0
      @@slave_y_target = -1.0
    end
   end

  def tick events
    @tick_bot_turn = 0
    @tick_gun_turn = 0
    @tick_radar_turn = 0
    determine_if_your_pair_is_alive
    set_dont_shoot
    say "Inconceivable!" if got_hit(events)
    sniper_mode
    set_location
    resolve_all_turns
  end

  def determine_if_your_pair_is_alive
    if @pair_is_alive == 1
      if @@was_here == @is_master
        your_pair_is_no_more_deal_with_it
      else
        @@was_here = @is_master
      end
    end
  end

  def your_pair_is_no_more_deal_with_it
    if @pair_is_alive == 1
      @pair_is_alive = 0
      @dont_shoot_max_right = nil
      @dont_shoot_max_left = nil
      @dont_shoot_distance = 0
      say "Nooooo!!!"
    end
  end

  def set_dont_shoot
    if @pair_is_alive == 1
      if @is_master == 1
        @dont_shoot_distance = distance_between_points x.to_i, y.to_i, @@slave_x_location, @@slave_y_location
        set_dont_shoot_max_left_right @@slave_x_location, @@slave_y_location
      else
        @dont_shoot_distance = distance_between_points x.to_i, y.to_i, @@master_x_location, @@master_y_location
        set_dont_shoot_max_left_right @@master_x_location, @@master_y_location
      end
    end
  end

  def distance_between_points x1, y1, x2, y2
    Math.hypot(y2 - y1, x1 - x2)
  end

  def set_dont_shoot_max_left_right x_pair, y_pair
    plus_minus_angle = get_angle_to_edge_of_bot_at_point x_pair, y_pair
    angle_to_pair = get_angle_to_location x_pair, y_pair
    @dont_shoot_max_left = angle_to_pair + plus_minus_angle
    @dont_shoot_max_right = angle_to_pair - plus_minus_angle
  end

  def get_angle_to_edge_of_bot_at_point x_bot, y_bot
    return Math.atan(@clipping_offset/(distance_between_points x.to_f, y.to_f, x_bot, y_bot)) / Math::PI * 180 % 360
  end

  def get_angle_to_location arg_x, arg_y
    angle = Math.atan2(y - arg_y, arg_x - x) / Math::PI * 180 % 360
    return angle
  end

  def got_hit events
    return events.has_key? "got_hit"
  end

  def set_location
    if @is_master == 1
      @@master_x_location = x.to_f
      @@master_y_location = y.to_f
    else
      @@slave_x_location = x.to_f
      @@slave_y_location = y.to_f
    end
  end

  def resolve_all_turns
    turn @tick_bot_turn
    turn_gun @tick_gun_turn - @tick_bot_turn
    turn_radar @tick_radar_turn - @tick_gun_turn - @tick_bot_turn
  end

  def tick_bot_turn angle
    @tick_bot_turn = angle
  end

  def tick_gun_turn angle
    @tick_gun_turn = angle
  end

  def tick_radar_turn angle
    @tick_radar_turn = angle
  end

  def sniper_mode
    initialize_sniper_mode
    fire_fire
    scan_for_next_target
    aim_at_target
    got_to_destination
  end

  def initialize_sniper_mode
    unless @initialize_sniper_mode
      if ((@is_master == 1) && (@@slave_x_destination == -1) && (@@slave_y_destination == -1)) || ((@is_master == 0) && (@@master_x_destination == -1) && (@@master_y_destination == -1))
        go_to_nearest_corner
      else
        find_catty_corner
      end
      @initialize_sniper_mode = true
      @gun_turn_direction = 1
    end
  end

  def go_to_nearest_corner
    if @battlefield_width.to_i / 2 < x then
      @x_destination = @battlefield_width - @clipping_offset
    else
      @x_destination = 0 + @clipping_offset
    end
    if @battlefield_height.to_i / 2 < y then
      @y_destination = @battlefield_height - @clipping_offset
    else
      @y_destination = 0 + @clipping_offset
    end
    set_destination
  end

  def set_destination
    if @is_master == 1
      @@master_x_destination = @x_destination
      @@master_y_destination = @y_destination
    else
      @@slave_x_destination = @x_destination
      @@slave_y_destination = @y_destination
    end
  end

  def find_catty_corner
    if @is_master == 1
      pair_dest_x = @@slave_x_destination
      pair_dest_y = @@slave_y_destination
    else
      pair_dest_x = @@master_x_destination
      pair_dest_y = @@master_y_destination
    end
    if(pair_dest_x.to_i == @clipping_offset) && (pair_dest_y.to_i == @clipping_offset)
      @x_destination = @battlefield_width - @clipping_offset
      @y_destination = @battlefield_height - @clipping_offset
    elsif(pair_dest_x.to_i == @battlefield_width - @clipping_offset) && (pair_dest_y.to_i == @clipping_offset)
      @x_destination = @clipping_offset
      @y_destination = @battlefield_height - @clipping_offset
    elsif(pair_dest_x.to_i == @battlefield_width - @clipping_offset) && (pair_dest_y.to_i == @battlefield_height - @clipping_offset)
      @x_destination = @clipping_offset
      @y_destination = @clipping_offset
    elsif(pair_dest_x.to_i == @clipping_offset) && (pair_dest_y.to_i == @battlefield_height - @clipping_offset)
      @x_destination = @battlefield_width - @clipping_offset
      @y_destination = @clipping_offset
    end
    set_destination
  end

  def fire_fire
    fire_power = 0.1
    if (@dont_shoot_max_right != nil) && (@dont_shoot_max_left != nil)
      if(@dont_shoot_max_right < gun_heading.to_f) && (gun_heading.to_f < @dont_shoot_max_left)
        fire_power = 0
      end
    end
    fire fire_power
  end

  def scan_for_next_target
    find_target
  end

  def find_target
    if (events['robot_scanned'].empty?)
      if @last_scan_angle == @current_scan_angle
        @current_scan_angle = 60
        @last_scan_angle = 60
      else
        @last_scan_angle = @current_scan_angle
      end
    else
      dsd_ff = 1
      if ((@dont_shoot_distance.to_f + dsd_ff) < events['robot_scanned'][0][0].to_f) || (events['robot_scanned'][0][0].to_f < (@dont_shoot_distance.to_f - dsd_ff))
        if @current_scan_angle < (get_angle_to_edge_of_bot_from_distance events['robot_scanned'][0][0].to_f)
          set_target events['robot_scanned'][0][0].to_f, (@current_scan_angle/2 * @radar_scan_direction * -1) + radar_heading.to_f
          @current_scan_angle = @last_scan_angle
          @radar_scan_direction = @radar_scan_direction * -1
        else
          @radar_scan_direction = -1 * @radar_scan_direction
          @current_scan_angle = (@current_scan_angle.to_f / 2.0).to_f
        end
      end
    end
    tick_radar_turn @current_scan_angle * @radar_scan_direction
  end

  def get_angle_to_edge_of_bot_from_distance distance_from_bot
    return Math.atan(@clipping_offset/distance_from_bot) / Math::PI * 180 % 360
  end

  def set_target distance_to_target, radar_heading_arg = radar_heading.to_f
    radi_angle = radar_heading_arg * Math::PI / 180
    @x_target = x.to_f + (Math.cos(radi_angle) * distance_to_target)
    @y_target = y.to_f - (Math.sin(radi_angle) * distance_to_target)
    if @is_master == 1
      @@master_x_target = @x_target
      @@master_y_target = @y_target
    else
      @@slave_x_target = @x_target
      @@slave_y_target = @y_target
    end
  end

  def aim_at_target
    unless get_angle_to_location(@x_target,@y_target).to_i == gun_heading.to_i
      tick_gun_turn (get_angle_to_location @x_target, @y_target).to_f - gun_heading.to_f
    end
  end

  def got_to_destination
    go_to_location @x_destination, @y_destination
  end

  def go_to_location arg_x, arg_y
    if(x == arg_x) && (y == arg_y)
      unless speed == 0
        stop
        say "Stopped"
      end
    else
      unless get_angle_to_location(arg_x,arg_y) == heading
        tick_bot_turn (get_angle_to_location arg_x, arg_y) - heading
      end
      accelerate 1
    end
  end
end