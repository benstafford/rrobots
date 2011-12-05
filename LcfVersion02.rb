require 'robot'

class LcfVersion02
  include Robot
  @@number_classes_initialized = 0
  @@was_here = 2
  @@master_tlrs = 100
  @@slave_tlrs = 100
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
  @@master_time_target = 0
  @@master_x_last_target = -1.0
  @@master_y_last_target = -1.0
  @@master_time_last_target = 0
  @@slave_x_target = -1.0
  @@slave_y_target = -1.0
  @@slave_time_target = 0
  @@slave_x_last_target = -1.0
  @@slave_y_last_target = -1.0
  @@slave_time_last_target = 0

  def initialize
    @@number_classes_initialized = @@number_classes_initialized + 1
    @x_destination = -1.0
    @y_destination = -1.0
    @x_last_target = -1.0
    @y_last_target = -1.0
    @time_last_target = 0
    @x_target = -1.0
    @y_target = -1.0
    @time_target = 0
    @clipping_offset = 60
    @ticks_last_robot_scanned = 0
    @has_scanned_enemy_robot = 0
    @history_ticks_last_robot_scanned = []
    @pair_is_alive = 1
    @max_tlrs_for_tracking_lock = 7
    @radar_scan_direction = 1
    @current_scan_angle = 60
    @last_scan_angle = 60
    @@was_here = 2
    @@master_tlrs = 100
    @@slave_tlrs = 100


    if @@number_classes_initialized % 2 == 1
      @is_master = 1
      @@master_x_location = x.to_f
      @@master_y_location = y.to_f
      @@master_x_destination = -1.0
      @@master_y_destination = -1.0
      @@master_x_target = -1.0
      @@master_y_target = -1.0
      @@master_time_target = 0
      @@master_x_last_target = -1.0
      @@master_y_last_target = -1.0
      @@master_time_last_target = 0
    else
      @is_master = 0
      @@slave_x_location = x.to_f
      @@slave_y_location = y.to_f
      @@slave_x_destination = -1.0
      @@slave_y_destination = -1.0
      @@slave_x_target = -1.0
      @@slave_y_target = -1.0
      @@slave_time_target = 0
      @@slave_x_last_target = -1.0
      @@slave_y_last_target = -1.0
      @@slave_time_last_target = 0
    end
    #puts "#{@is_master}"
   end

  def tick events
    @tick_bot_turn = 0
    @tick_gun_turn = 0
    @tick_radar_turn = 0
    determine_if_your_pair_is_alive
    set_dont_shoot
    slow_motion 0, 1.00
    say "Inconceivable!" if got_hit(events)
    determine_mode
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
      @is_master = 1
      @dont_shoot_max_right = nil
      @dont_shoot_max_left = nil
      @dont_shoot_distance = 0
      say "Nooooo!!!"
      #puts "Nooooo!!!"
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

  def set_dont_shoot_max_left_right x_pair, y_pair
    plus_minus_angle = get_angle_to_edge_of_bot_at_point x_pair, y_pair
    angle_to_pair = get_angle_to_location x_pair, y_pair
    @dont_shoot_max_left = angle_to_pair + plus_minus_angle
    @dont_shoot_max_right = angle_to_pair - plus_minus_angle
  end

  def get_angle_to_edge_of_bot_at_point x_bot, y_bot
    return Math.atan(@clipping_offset/(distance_between_points x.to_f, y.to_f, x_bot, y_bot)) / Math::PI * 180 % 360
  end

  def slow_motion enabled, seconds
    if (enabled == 1) && (@is_master == 1)
      sleep(seconds)
    end
  end

  def got_hit events
    return events.has_key? "got_hit"
  end

  def determine_mode
    if energy > 50
      sniper_mode
    else
      sniper_mode
    end
  end

  def set_location
    #puts "#{@is_master}|set_location"
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
    #puts "#{@is_master}|tick_radar_turn #{angle}" if @is_master == 1
    @tick_radar_turn = angle
  end

  def sniper_mode
    initialize_sniper_mode
    #if @got_first_target == 1
    #  fire_last_found
    #end
    fire_fire
    scan_for_next_target
    aim_at_target
    got_to_destination
  end

  def initialize_sniper_mode
    unless @initialize_sniper_mode
      #puts "initialize_sniper_mode"
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
    #CORNER calculations x, y
    #upper_left = @clipping_offset, @clipping_offset (@gun_turn_left_stop=0, @gun_turn_right_stop=270)
    #upper_right = @battlefield_width - @clipping_offset, @clipping_offset (@gun_turn_left_stop=270, @gun_turn_right_stop=180)
    #lower_right = @battlefield_width - @clipping_offset, @battlefield_height - @clipping_offset (@gun_turn_left_stop=180, @gun_turn_right_stop=90)
    #lower_left = @clipping_offset, @battlefield_height - @clipping_offset (@gun_turn_left_stop=90, @gun_turn_right_stop=0)
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
    set_gun_max_turn_stops
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

  def set_gun_max_turn_stops
    if(@x_destination == @clipping_offset) && (@y_destination == @clipping_offset)
      @gun_turn_max_left_stop=0
      @gun_turn_max_right_stop=(270-1)
      @gun_turn_left_stop=0
      @gun_turn_right_stop=(270-1)
    elsif(@x_destination == @battlefield_width - @clipping_offset) && (@y_destination == @clipping_offset)
      @gun_turn_max_left_stop=270
      @gun_turn_max_right_stop=(180-1)
      @gun_turn_left_stop=270
      @gun_turn_right_stop=(180-1)
    elsif(@x_destination == @battlefield_width - @clipping_offset) && (@y_destination == @battlefield_height - @clipping_offset)
      @gun_turn_max_left_stop=180
      @gun_turn_max_right_stop=(90-1)
      @gun_turn_left_stop=180
      @gun_turn_right_stop=(90-1)
    elsif(@x_destination == @clipping_offset) && (@y_destination == @battlefield_height - @clipping_offset)
      @gun_turn_max_left_stop=90
      @gun_turn_max_right_stop=359
      @gun_turn_left_stop=90
      @gun_turn_right_stop=359
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
    if(pair_dest_x.to_i == @clipping_offset) && (pair_dest_y.to_i == @clipping_offset)#upper_left
      @x_destination = @battlefield_width - @clipping_offset
      @y_destination = @battlefield_height - @clipping_offset
    elsif(pair_dest_x.to_i == @battlefield_width - @clipping_offset) && (pair_dest_y.to_i == @clipping_offset)#upper_right
      @x_destination = @clipping_offset
      @y_destination = @battlefield_height - @clipping_offset
    elsif(pair_dest_x.to_i == @battlefield_width - @clipping_offset) && (pair_dest_y.to_i == @battlefield_height - @clipping_offset)#lower_right
      @x_destination = @clipping_offset
      @y_destination = @clipping_offset
    elsif(pair_dest_x.to_i == @clipping_offset) && (pair_dest_y.to_i == @battlefield_height - @clipping_offset)#lower_left
      @x_destination = @battlefield_width - @clipping_offset
      @y_destination = @clipping_offset
    end
    set_destination
    set_gun_max_turn_stops
  end

  def fire_fire
    fire_power = 0.1
    if (@dont_shoot_max_right != nil) && (@dont_shoot_max_left != nil)
      if(@dont_shoot_max_right < gun_heading.to_f) && (gun_heading.to_f < @dont_shoot_max_left)
        #puts "#{@is_master}|Don'tShoot!!!'"
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
      #puts "#{@is_master}|nothing|#{@current_scan_angle} * #{@radar_scan_direction}|@last_scan_angle=#{@last_scan_angle} @current_scan_angle=#{@current_scan_angle}" if @is_master == 1
      if @last_scan_angle == @current_scan_angle
        @current_scan_angle = 60
        @last_scan_angle = 60
      else
        @last_scan_angle = @current_scan_angle
      end
    else
      dsd_ff = 1
      #puts "#{@is_master}|dif(#{(@dont_shoot_distance.to_i + dsd_ff)-events['robot_scanned'][0][0].to_i})(#{@dont_shoot_distance.to_i + dsd_ff} < #{events['robot_scanned'][0][0].to_i}) || (#{events['robot_scanned'][0][0].to_i} < #{@dont_shoot_distance.to_i - dsd_ff})dif(#{events['robot_scanned'][0][0].to_i - (@dont_shoot_distance.to_i - dsd_ff)})" if @is_master == 1
      if ((@dont_shoot_distance.to_f + dsd_ff) < events['robot_scanned'][0][0].to_f) || (events['robot_scanned'][0][0].to_f < (@dont_shoot_distance.to_f - dsd_ff))
        #puts "if #{@current_scan_angle} < #{(get_angle_to_edge_of_bot_from_distance events['robot_scanned'][0][0].to_f) * 2}" if @is_master == 1
        if @current_scan_angle < (get_angle_to_edge_of_bot_from_distance events['robot_scanned'][0][0].to_f)
          set_target events['robot_scanned'][0][0].to_f, (@current_scan_angle/2 * @radar_scan_direction * -1) + radar_heading.to_f
          #puts "#{@is_master}|First Target(#{@x_target},#{@y_target})|dist = #{events['robot_scanned'][0][0].to_f}, (#{@current_scan_angle}/2 * #{@radar_scan_direction} * -1) + #{radar_heading.to_f} = #{(@current_scan_angle/2 * @radar_scan_direction * -1) + radar_heading.to_f}" if @is_master == 1
          #puts "#{@is_master}|Targeted|#{time}" if @is_master == 1
          @current_scan_angle = @last_scan_angle
          @radar_scan_direction = @radar_scan_direction * -1
        else
          #puts "#{@is_master}|something|#{@current_scan_angle} * #{@radar_scan_direction}" if @is_master == 1
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

  def aim_at_target
    #puts "if (#{@x_target} != -1) && (#{@y_target} != -1)"
    #puts "#{@is_master}|unless #{get_angle_to_location(@x_target,@y_target).to_i} == #{gun_heading.to_i}"
    unless get_angle_to_location(@x_target,@y_target).to_i == gun_heading.to_i
      #puts "#{@is_master}|turn_gun #{(get_angle_to_location @x_target, @y_target).to_f - gun_heading.to_f}|to(#{@x_target},#{@y_target})"
      tick_gun_turn (get_angle_to_location @x_target, @y_target).to_f - gun_heading.to_f
    end
  end

  def predictive_aim_at_target
    if (@x_last_target == -1) && (@y_last_target == -1) && (@time_last_target == 0)
      x_target = @x_target
      y_target = @y_target
    else
      #can the 2 point be the same bot
      puts "#{@is_master}|if #{(distance_between_points @x_last_target, @y_last_target, @x_target, @y_target)/(@time_target - @time_last_target)} < 9"
      if (distance_between_points @x_last_target, @y_last_target, @x_target, @y_target)/(@time_target - @time_last_target) < 9
      else
        x_target = @x_target
        y_target = @y_target
      end
    end

    unless get_angle_to_location(x_target,y_target).to_i == gun_heading.to_i
      tick_gun_turn (get_angle_to_location x_target, y_target).to_f - gun_heading.to_f
    end
  end

  def get_angle_to_location arg_x, arg_y
    #puts "arg_x->#{arg_x}|arg_y->#{arg_y}|x->#{x}|y->#{y}"
    angle = Math.atan2(y - arg_y, arg_x - x) / Math::PI * 180 % 360
    #puts "Angle to location #{arg_x},#{arg_y} == #{angle}"
    return angle
  end

  def got_to_destination
    go_to_location @x_destination, @y_destination
  end

  def go_to_location arg_x, arg_y
    #puts "#{@is_master}|speed #{speed}"
    if(x == arg_x) && (y == arg_y)
      #puts "speed #{speed}"
      unless speed == 0
        stop
        say "Stopped"
        #puts "Current Location #{x}, #{y}"
        #your_pair_is_no_more_deal_with_it
      end
    else
      #puts "Current Location #{x}, #{y}"
      #puts "Trying to go to #{arg_x}, #{arg_y}"
      #puts "#{@is_master}|#{time}|#{(get_angle_to_location arg_x, arg_y) - heading}"
      unless get_angle_to_location(arg_x,arg_y) == heading
        tick_bot_turn (get_angle_to_location arg_x, arg_y) - heading
      end
      accelerate 1
    end
    @last_x_location = x
    @last_y_location = y
  end

  def angle_to_pairs_target fast_turn_amount
    if @is_master == 1
      pairs_tlrs = @@slave_tlrs
    else
      pairs_tlrs = @@master_tlrs
    end

    if (@pair_is_alive == 1) && (pairs_tlrs < @max_tlrs_for_tracking_lock)
      if @is_master == 1
        x_target = @@slave_x_target
        y_target = @@slave_y_target
      else
        x_target = @@master_x_target
        y_target = @@master_y_target
      end
      unless get_angle_to_location(x_target,y_target).to_i == gun_heading.to_i
        return (get_angle_to_location x_target, y_target) - gun_heading.to_f
      else
        return gun_heading.to_f
      end
    else
      @gun_turn_left_stop = @gun_turn_max_left_stop
      @gun_turn_right_stop = @gun_turn_max_right_stop
      return fast_turn_amount * @gun_turn_direction
    end
  end

  def found_enemy_robot
    @ticks_last_robot_scanned = 0
    if @is_master == 1
      @@master_tlrs = @ticks_last_robot_scanned
    else
      @@slave_tlrs = @ticks_last_robot_scanned
    end
    @history_ticks_last_robot_scanned[time] = 0
    set_target events['robot_scanned'][0][0].to_f
    @has_scanned_enemy_robot = 1
    @gun_heading_fired = gun_heading.to_i
    @distance_lasted_locked = events['robot_scanned'][0][0].to_i
  end

  def set_target distance_to_target, radar_heading_arg = radar_heading.to_f
    radi_angle = radar_heading_arg * Math::PI / 180
    #puts "#{@is_master}|#{gun_heading.to_f}|#{radi_angle}|#{distance_to_target}"
    @x_last_target = @x_target
    @y_last_target = @y_target
    @time_last_target = @time_target
    @x_target = x.to_f + (Math.cos(radi_angle) * distance_to_target)
    @y_target = y.to_f - (Math.sin(radi_angle) * distance_to_target)
    @time_target = time
    #puts "#{@is_master}|#{@x_target},#{@y_target}"
    if @is_master == 1
      @@master_x_last_target = @@master_x_target
      @@master_y_last_target = @@master_y_target
      @@master_time_last_target = @@master_time_target
      @@master_x_target = @x_target
      @@master_y_target = @y_target
      @@master_time_target = time
    else
      @@slave_x_last_target = @@slave_x_target
      @@slave_y_last_target = @@slave_y_target
      @@slave_time_last_target = @@slave_time_target
      @@slave_x_target = @x_target
      @@slave_y_target = @y_target
      @@slave_time_target = time
    end
  end

  def no_enemy_robot_found
    @ticks_last_robot_scanned = @ticks_last_robot_scanned + 1
    if @is_master == 1
      @@master_tlrs = @ticks_last_robot_scanned
    else
      @@slave_tlrs = @ticks_last_robot_scanned
    end
    @history_ticks_last_robot_scanned[time] = @ticks_last_robot_scanned
    #puts "#{@is_master}|#{@history_ticks_last_robot_scanned.inspect}"
    if (@has_scanned_enemy_robot == 1) && (@ticks_last_robot_scanned < @max_tlrs_for_tracking_lock)
      set_target @distance_lasted_locked
    end
  end

  def get_corner_to_corner_distance
    #Math.sqrt(((@battlefield_width - (@clipping_offset * 2))*((@battlefield_width - (@clipping_offset * 2)))) + ((@battlefield_height - (@clipping_offset * 2))*((@battlefield_height - (@clipping_offset * 2)))))
    distance_between_points @clipping_offset, @clipping_offset, (@battlefield_width - @clipping_offset), ((@battlefield_height - @clipping_offset))
  end

  def distance_between_points x1, y1, x2, y2
    temp_for_puts = Math.hypot(y2 - y1, x1 - x2)
    #puts "#{@is_master}|#{temp_for_puts}"
    temp_for_puts
  end

  def sidewalker_mode
    initialize_sidewalker_mode
    fire_last_found
    go_to_next_corner
    got_to_destination
  end

  def initialize_sidewalker_mode
    unless @initialize_sidewalker_mode
      puts "initialize_sidewalker_mode"
      go_to_next_corner
      @initialize_sidewalker_mode = true
    end
  end

  def go_to_next_corner
    #upper_left = @clipping_offset, @clipping_offset
    #upper_right = @battlefield_width - @clipping_offset, @clipping_offset
    #lower_right = @battlefield_width - @clipping_offset, @battlefield_height - @clipping_offset
    #lower_left = @clipping_offset, @battlefield_height - @clipping_offset
    #puts "got to next corner"

    #puts "#{@is_master}|(#{x.to_i} == #{@x_destination}) && (#{y.to_i} == #{@x_destination})"
    if(x.to_i == @x_destination) && (y.to_i == @x_destination)
      if(x.to_i == @clipping_offset) && (y.to_i == @clipping_offset)
        @x_destination = @battlefield_width - @clipping_offset
        @y_destination = @clipping_offset
      elsif(x.to_i == @battlefield_width - @clipping_offset) && (y.to_i == @clipping_offset)
        @x_destination = @battlefield_width - @clipping_offset
        @y_destination = @battlefield_height - @clipping_offset
      elsif(x.to_i == @battlefield_width - @clipping_offset) && (y.to_i == @battlefield_height - @clipping_offset)
        @x_destination = @clipping_offset
        @y_destination = @battlefield_height - @clipping_offset
      elsif(x.to_i == @clipping_offset) && (y.to_i == @battlefield_height - @clipping_offset)
        @x_destination = @clipping_offset
        @y_destination = @clipping_offset
      else
        #do some default
      end
      set_destination
      set_sidewalker_gun_max_turn_stops
      accelerate 1
    end
  end

  def set_sidewalker_gun_max_turn_stops
    if(@x_destination == @clipping_offset) && (@y_destination == @clipping_offset)
      @gun_turn_max_left_stop=90
      @gun_turn_max_right_stop=(270-1)
    elsif(@x_destination == @battlefield_width - @clipping_offset) && (@y_destination == @clipping_offset)
      @gun_turn_max_left_stop=0
      @gun_turn_max_right_stop=(180-1)
    elsif(@x_destination == @battlefield_width - @clipping_offset) && (@y_destination == @battlefield_height - @clipping_offset)
      @gun_turn_max_left_stop=270
      @gun_turn_max_right_stop=(90-1)
    elsif(@x_destination == @clipping_offset) && (@y_destination == @battlefield_height - @clipping_offset)
      @gun_turn_max_left_stop=180
      @gun_turn_max_right_stop=359
    end
  end

  def fire_last_found
    turn_amount = 1
    if @pair_is_alive == 1
      max_ticks_before_fast_turn = 26
    else
      max_ticks_before_fast_turn = 51
    end
    fast_turn_amount = 1
    target_lock_patterns_to_match = 7
    fire_power = 0.1

    if @has_scanned_enemy_robot == 1
      if @distance_lasted_locked > 275
        if @history_ticks_last_robot_scanned.last < 3
          target_lock_patterns_to_match = (@distance_lasted_locked / (30 * 4)).to_i
          #puts "#{@is_master}|#{@distance_lasted_locked}"
          if target_lock_patterns_to_match < 1
            target_lock_patterns_to_match = 1
          end
          #puts "#{@is_master}|#{target_lock_patterns_to_match}"
        end
      else
        fire_power = 3.0
      end
    end

    #puts "radar, gun heading #{radar_heading}, #{gun_heading}"
    #puts "gun_heading->#{gun_heading.to_i}|@gun_turn_left_stop->#{@gun_turn_left_stop}|@gun_turn_right_stop->#{@gun_turn_right_stop}|@gun_turn_direction->#{@gun_turn_direction}"
    set_gun_turn_stops
    if fire_power != 3.0
      if @history_ticks_last_robot_scanned.size >= (target_lock_patterns_to_match * 4)
        #if @is_master ==1
        #  puts @history_ticks_last_robot_scanned.inspect
        #end

        found = 0
        for i in (1..target_lock_patterns_to_match)
          if ((@history_ticks_last_robot_scanned[time-(i*3)-3] == 0) && (@history_ticks_last_robot_scanned[time-(i*3)-2] == 0) && (@history_ticks_last_robot_scanned[time-(i*3)-1] == 1) && (@history_ticks_last_robot_scanned[time-(i*3)] == 2)) ||
              ((@history_ticks_last_robot_scanned[time-(i*3)-3] == 0) && (@history_ticks_last_robot_scanned[time-(i*3)-2] == 1) && (@history_ticks_last_robot_scanned[time-(i*3)-1] == 2) && (@history_ticks_last_robot_scanned[time-(i*3)] == 0)) ||
              ((@history_ticks_last_robot_scanned[time-(i*3)-3] == 1) && (@history_ticks_last_robot_scanned[time-(i*3)-2] == 2) && (@history_ticks_last_robot_scanned[time-(i*3)-1] == 0) && (@history_ticks_last_robot_scanned[time-(i*3)] == 0)) ||
              ((@history_ticks_last_robot_scanned[time-(i*3)-3] == 2) && (@history_ticks_last_robot_scanned[time-(i*3)-2] == 0) && (@history_ticks_last_robot_scanned[time-(i*3)-1] == 0) && (@history_ticks_last_robot_scanned[time-(i*3)] == 1))
            found = 1
            #puts "#{@is_master}|found first pattern"
          else
            found = 0
            break
          end
        end

        if found == 1
          fire_power = 3.0
        else
          fire_power = 0.1
        end
      else
        fire_power = 0.1
      end
    end

    if @gun_turn_direction > 0
      if gun_heading.to_i == @gun_turn_left_stop
        @gun_turn_direction = (-1 * @gun_turn_direction)
        #puts "#{@is_master}|Max left Change direction #{gun_heading}"
      end
    else
      if gun_heading.to_i == @gun_turn_right_stop
        @gun_turn_direction = (-1 * @gun_turn_direction)
        #puts "#{@is_master}|Max right Change direction #{gun_heading}"
      end
    end

    if (@dont_shoot_max_right != nil) && (@dont_shoot_max_left != nil)
      if(@dont_shoot_max_right < gun_heading.to_f) && (gun_heading.to_f < @dont_shoot_max_left)
        #puts "#{@is_master}|Don'tShoot!!!'"
        fire_power = 0
      end
    end

    fire fire_power

    if @is_master == 1
      pairs_tlrs = @@slave_tlrs
    else
      pairs_tlrs = @@master_tlrs
    end

    unless events['robot_scanned'].empty?
      #puts "#{@is_master}|#{events['robot_scanned'][0][0].to_i} < #{@dont_shoot_distance.to_i}"
      #if events['robot_scanned'][0][0].to_i < @dont_shoot_distance.to_i
      dsd_ff = 1
      #puts "#{@is_master}|dif(#{(@dont_shoot_distance.to_i + dsd_ff)-events['robot_scanned'][0][0].to_i})(#{@dont_shoot_distance.to_i + dsd_ff} < #{events['robot_scanned'][0][0].to_i}) || (#{events['robot_scanned'][0][0].to_i} < #{@dont_shoot_distance.to_i - dsd_ff})dif(#{events['robot_scanned'][0][0].to_i - (@dont_shoot_distance.to_i - dsd_ff)})"
      if ((@dont_shoot_distance.to_i + dsd_ff) < events['robot_scanned'][0][0].to_i) || (events['robot_scanned'][0][0].to_i < (@dont_shoot_distance.to_i - dsd_ff))
        #if @pair_is_alive == 1
        #  puts "#{@is_master}|Got One!!!|#{@is_master}|dif(#{(@dont_shoot_distance.to_i + dsd_ff)-events['robot_scanned'][0][0].to_i})(#{@dont_shoot_distance.to_i + dsd_ff} < #{events['robot_scanned'][0][0].to_i}) || (#{events['robot_scanned'][0][0].to_i} < #{@dont_shoot_distance.to_i - dsd_ff})dif(#{events['robot_scanned'][0][0].to_i - (@dont_shoot_distance.to_i - dsd_ff)})"
        #end
        tick_gun_turn (-1 * turn_amount * @gun_turn_direction)
        found_enemy_robot
      else
        if (@has_scanned_enemy_robot == 1) && (@ticks_last_robot_scanned < max_ticks_before_fast_turn)
          tick_gun_turn (1 * turn_amount * @gun_turn_direction)
        else
          tick_gun_turn angle_to_pairs_target fast_turn_amount
        end
        no_enemy_robot_found
      end
    else
      if (@has_scanned_enemy_robot == 1) && (@ticks_last_robot_scanned < max_ticks_before_fast_turn)
        tick_gun_turn (1 * turn_amount * @gun_turn_direction)
      else
        tick_gun_turn angle_to_pairs_target fast_turn_amount
      end
      no_enemy_robot_found
    end
  end

  def set_gun_turn_stops
    if @has_scanned_enemy_robot == 1
      if @gun_turn_max_left_stop == 0
        using_max_left = 360
      else
        using_max_left = @gun_turn_max_left_stop
      end
      if @gun_turn_max_right_stop == 359
        using_max_right = 0
      else
        using_max_right = @gun_turn_max_right_stop
      end

      if @ticks_last_robot_scanned == 0
        if (@gun_heading_fired + 1) <= using_max_left
          @gun_turn_left_stop = @gun_heading_fired + 1
        else
          @gun_turn_left_stop = @gun_turn_max_left_stop
        end

        if (@gun_heading_fired - 1) >= using_max_right
          @gun_turn_right_stop = @gun_heading_fired - 1
        else
          @gun_turn_right_stop = @gun_turn_max_right_stop
        end
      else
        if (@gun_heading_fired + (0.5 * @ticks_last_robot_scanned)) <= using_max_left
          @gun_turn_left_stop = @gun_heading_fired + (0.5 * @ticks_last_robot_scanned)
        else
          @gun_turn_left_stop = @gun_turn_max_left_stop
        end

        if (@gun_heading_fired - (0.5 * @ticks_last_robot_scanned)) >= using_max_right
          @gun_turn_right_stop = @gun_heading_fired - (0.5 * @ticks_last_robot_scanned)
        else
          @gun_turn_right_stop = @gun_turn_max_right_stop
        end
      end
      #if @is_master == 1
      #  puts "#{@is_master}|#{@ticks_last_robot_scanned}|#{@gun_turn_max_left_stop}|#{@gun_turn_left_stop}|#{@gun_heading_fired}|#{@gun_turn_right_stop}|#{@gun_turn_max_right_stop}"
      #end
    end
  end
end