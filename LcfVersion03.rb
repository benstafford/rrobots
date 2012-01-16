require 'robot'
require 'LCF/destination_setter'
require 'LCF/side_walker_setter'
require 'LCF/tight_figure_eight_setter'
require 'LCF/foo_setter'

class LcfVersion03
  include Robot
  @@number_classes_initialized = 0
  @@was_here = 2
  @@pairs_x_destination = -1.0
  @@pairs_y_destination = -1.0
  @@pairs_x_location = -1.0
  @@pairs_y_location = -1.0
  @@pairs_x_target = -1.0
  @@pairs_y_target = -1.0
  @@pairs_time_target = 0
  @@pairs_x_last_target = -1.0
  @@pairs_y_last_target = -1.0
  @@pairs_time_last_target = 0
  @@pairs_energy = 100
  @@current_destination_setter = 0

  def initialize
    #Process.exit if (caller[1].to_s[0,10] != "rrobots.rb") && (caller[1].to_s[0,19] != "teamexperimenter.rb")
    @@number_classes_initialized = @@number_classes_initialized + 1
    @x_destination = -1.0
    @y_destination = -1.0
    @x_last_target = -1.0
    @y_last_target = -1.0
    @time_last_target = 0
    @x_target = -1.0
    @y_target = -1.0
    @distance_to_target = 0
    @time_target = 0
    @clipping_offset = 121
    @pair_is_alive = 1
    @radar_scan_direction = 1
    @current_scan_angle = 60
    @last_scan_angle = 60
    @@was_here = 2
    @@current_destination_setter = 0
    @destination_setters = []
    @time_last_destination_setter_change = 0
    @last_turns_energy = 100
    @@pairs_x_destination = -1.0
    @@pairs_y_destination = -1.0
    @@pairs_x_location = -1.0
    @@pairs_y_location = -1.0
    @@pairs_x_target = -1.0
    @@pairs_y_target = -1.0
    @@pairs_time_target = 0
    @@pairs_x_last_target = -1.0
    @@pairs_y_last_target = -1.0
    @@pairs_time_last_target = 0
    @@pairs_energy = 100
    @is_master = @@number_classes_initialized % 2
    @find_target_in = 1
  end

  attr_reader(:x_destination)
  attr_reader(:y_destination)
  attr_reader(:x_location)
  attr_reader(:y_location)
  attr_reader(:my_heading)
  attr_reader(:my_gun_heading)
  attr_reader(:pair_x_destination)
  attr_reader(:pair_y_destination)

  def tick events
    slow_motion 0, 0.75
    initialize_tick_vars
    determine_if_your_pair_is_alive
    set_dont_shoot
    assess_damage
    say "Inconceivable!" if got_hit events
    fire_fire
    determine_target
    aim_at_closest_target
    calculate_destination_based_on_damage
    got_to_destination
    resolve_all_turns
    send_pair_communication
  end

  def slow_motion enabled, seconds
    if (enabled == 1) && (@is_master == 1)
      sleep(seconds)
    end
  end

  def initialize_tick_vars
    @tick_bot_turn = 0
    @tick_gun_turn = 0
    @tick_radar_turn = 0
    @x_location = x.to_f
    @y_location = y.to_f
    @my_heading = heading.to_f
    @my_gun_heading = gun_heading.to_f
    @pair_x_destination = @@pairs_x_destination
    @pair_y_destination = @@pairs_y_destination

    if time == 0
      @destination_setters[0] = SideWalkerSetter.new @battlefield_width.to_f, @battlefield_height.to_f, @clipping_offset.to_f
      @destination_setters[1] = TightFigureEightSetter.new @battlefield_width.to_f, @battlefield_height.to_f, @clipping_offset.to_f
      #@destination_setters[2] = FooSetter.new @battlefield_width.to_f, @battlefield_height.to_f, @clipping_offset.to_f
    end
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
    end
  end

  def set_dont_shoot
    if @pair_is_alive == 1
      @dont_shoot_distance = distance_between_points x.to_i, y.to_i, @@pairs_x_location, @@pairs_y_location
      set_dont_shoot_max_left_right @@pairs_x_location, @@pairs_y_location
    end
  end

  def set_dont_shoot_max_left_right x_pair, y_pair
    plus_minus_angle = get_angle_to_edge_of_bot_at_point x_pair, y_pair
    angle_to_pair = get_angle_to_location x_pair, y_pair
    @dont_shoot_max_left = angle_to_pair + plus_minus_angle
    @dont_shoot_max_right = angle_to_pair - plus_minus_angle
  end

  def get_angle_to_edge_of_bot_at_point x_bot, y_bot
    Math.atan(size.to_f/(distance_between_points x.to_f, y.to_f, x_bot, y_bot)) / Math::PI * 180 % 360
  end

  def assess_damage
    if got_hit events
      @destination_setters[@@current_destination_setter].add_damage_for_this_tick(@last_turns_energy - energy)
      @last_turns_energy = energy
    end
    @destination_setters[@@current_destination_setter].add_tick if 0 < @destination_setters[@@current_destination_setter].damage_taken
  end

  def got_hit events
    events.has_key? "got_hit"
  end

  def fire_fire
    fire_power = 0.1
    if (@dont_shoot_max_right != nil) && (@dont_shoot_max_left != nil)
      if (@dont_shoot_max_right < gun_heading.to_f) && (gun_heading.to_f < @dont_shoot_max_left)
        fire_power = 0
      end
    end
    fire fire_power
  end

  def determine_target
    find_target_in_out
  end

  def find_target_in_out
    @ignore_scan_time = -1 if @ignore_scan_time.nil?
    if (events['robot_scanned'].empty?) || (time == @ignore_scan_time)
      #puts "EMPTY scan" if @is_master == 1
      handle_empty
    else
      if ((is_this_the_same_as_pairs_distance events['robot_scanned'][0][0].to_f) == 0)
        #puts "ENEMY scanned" if @is_master == 1
        if @current_scan_angle < (0.7 * 2 * (get_angle_to_edge_of_bot_from_distance events['robot_scanned'][0][0].to_f))
          if ((is_this_pairs_target events['robot_scanned'][0][0].to_f, (@current_scan_angle/2 * @radar_scan_direction * -1) + radar_heading.to_f) == 0)
            #puts "TARGET set" if @is_master == 1
            set_target_from_distance_heading events['robot_scanned'][0][0].to_f, (@current_scan_angle/2 * @radar_scan_direction * -1) + radar_heading.to_f
            @find_target_in = 0
          else
            @ignore_scan_time = time + 1
            handle_empty
          end
        else
          @last_scan_angle = @current_scan_angle
          @current_scan_angle = (@current_scan_angle.to_f / 2.0).to_f
          @find_target_in = 1
        end
        @radar_scan_direction *= -1
      else
        #puts "PAIR scanned" if @is_master == 1
        handle_empty
      end
    end
    @tick_radar_turn = @current_scan_angle * @radar_scan_direction
    #puts "@find_target_in#{@find_target_in}|scan at #{@current_scan_angle * @radar_scan_direction}" if @is_master == 1
  end

  def handle_empty
    if @find_target_in == 1
      if @last_scan_angle == @current_scan_angle
        @current_scan_angle = 60
        @last_scan_angle = 60
      else
        @last_scan_angle = @current_scan_angle
      end
    else
      @last_scan_angle = @current_scan_angle
      if @current_scan_angle < 30
        @current_scan_angle = ((get_angle_to_location @x_target, @y_target).to_f - radar_heading).abs + (@current_scan_angle * 1)
        @radar_scan_direction *= -1
      else
        @current_scan_angle = 60
        @last_scan_angle = 60
        @find_target_in = 1
      end
    end
  end

  def is_this_the_same_as_pairs_distance bots_distance
    return_val = 1
    dsd_ff = 2
    return_val = 0 if ((@dont_shoot_distance.to_f + dsd_ff) < bots_distance) || (bots_distance < (@dont_shoot_distance.to_f - dsd_ff))
    return_val
  end

  def is_this_pairs_target distance_to_target, radar_heading_arg
    return_val = 1
    radi_angle = radar_heading_arg * Math::PI / 180
    x_scanned = x.to_f + (Math.cos(radi_angle) * distance_to_target)
    y_scanned = y.to_f - (Math.sin(radi_angle) * distance_to_target)

    #puts "#{@is_master}|(#{x_scanned.to_i}, #{y_scanned.to_i})@#{time}|(#{@@pairs_x_target.to_i}, #{@@pairs_y_target.to_i})@#{@@pairs_time_target}"
    if time == @@pairs_time_target
      #puts "  dist #{distance_between_points @@pairs_x_target.to_f, @@pairs_y_target.to_f, x_scanned.to_f, y_scanned.to_f}"
      if (distance_between_points @@pairs_x_target.to_f, @@pairs_y_target.to_f, x_scanned.to_f, y_scanned.to_f) > 30
        return_val = 0
      else
        #puts "#{@is_master}|Pair's Target|keep looking|dist #{distance_between_points @@pairs_x_target.to_f, @@pairs_y_target.to_f, x_scanned.to_f, y_scanned.to_f}"
      end
    else
      #puts "  ave speed #{(((distance_between_points @@pairs_x_target.to_f, @@pairs_y_target.to_f, x_scanned.to_f, y_scanned.to_f).to_f)/(time - @@pairs_time_target).to_f).to_f}"
      if (@pair_is_alive == 0) || (((distance_between_points @@pairs_x_target.to_f, @@pairs_y_target.to_f, x_scanned.to_f, y_scanned.to_f).to_f/(time - @@pairs_time_target).to_f).to_f > 8)
        return_val = 0
      else
        #puts "#{@is_master}|Pair's Target|keep looking|avespeed #{((distance_between_points @@pairs_x_target.to_f, @@pairs_y_target.to_f, x_scanned.to_f, y_scanned.to_f).to_f/(time - @@pairs_time_target).to_f).to_f}"
      end
    end
    return_val
  end

  def set_target_from_distance_heading distance_to_target, radar_heading_arg = radar_heading.to_f
    radi_angle = radar_heading_arg * Math::PI / 180
    set_target x.to_f + (Math.cos(radi_angle) * distance_to_target), y.to_f - (Math.sin(radi_angle) * distance_to_target), distance_to_target
  end

  def set_target x_target, y_target, distance_to_target
    @x_last_target = @x_target
    @y_last_target = @y_target
    @time_last_target = @time_target
    @x_target = x_target
    @y_target = y_target
    @distance_to_target = distance_to_target
    @time_target = time
  end

  def return_cord x_start_from, y_start_from, heading, distance
    radi_angle = heading * Math::PI / 180
    return (x_start_from + (Math.cos(radi_angle) * distance)), (y_start_from - (Math.sin(radi_angle) * distance))
  end

  def get_angle_to_edge_of_bot_from_distance distance_from_bot
    Math.atan(size.to_i/distance_from_bot) / Math::PI * 180 % 360
  end

  def aim_at_closest_target
    if (@@pairs_x_target != -1) && (@@pairs_y_target != -1) && (@pair_is_alive == 1)
      if (@distance_to_target > distance_between_points(x.to_f, y.to_f, @@pairs_x_target, @@pairs_y_target)) || ((@x_target == -1) && (@y_target == -1))
        aim_at_pairs_target
        return
      end
    end
    aim_at_target
  end

  def aim_at_pairs_target heading_to_target = gun_heading.to_f
    @tick_gun_turn = (get_angle_to_location @@pairs_x_target, @@pairs_y_target).to_f - heading_to_target
  end

  def aim_at_target heading_to_target = gun_heading.to_f
    @tick_gun_turn = (get_angle_to_location @x_target, @y_target).to_f - heading_to_target
  end

  def get_angle_to_location arg_x, arg_y
    angle = 0
    unless (x == arg_x) && (y == arg_y)
      angle = Math.atan2(y - arg_y, arg_x - x) / Math::PI * 180 % 360
    end
    angle
  end

  def calculate_destination_based_on_damage
    if (energy.to_f < @@pairs_energy) || (@pair_is_alive == 0)
      lowest_damage_destination_setter = @@current_destination_setter
      @destination_setters.each_with_index { |x, i| lowest_damage_destination_setter = i if x.average_damage_per_tick < @destination_setters[lowest_damage_destination_setter].average_damage_per_tick}
      if (@time_last_destination_setter_change == 0) || ((time - @time_last_destination_setter_change) > 15)
        if (lowest_damage_destination_setter != @@current_destination_setter)
          say @destination_setters[lowest_damage_destination_setter].get_name
        end
        @@current_destination_setter = lowest_damage_destination_setter
        @time_last_destination_setter_change = time
      end
    end
    @x_destination, @y_destination = @destination_setters[@@current_destination_setter].calculate_destination self
  end

  def got_to_destination
    turn_to_location @x_destination, @y_destination
    accelerate_bot
  end

  def turn_to_location arg_x, arg_y
    @tick_bot_turn = (get_angle_to_location arg_x, arg_y) - heading.to_f
  end

  def accelerate_bot
    accelerate (Math.sqrt(distance_between_points x.to_f, y.to_f, @x_destination, @y_destination).to_i) - speed.to_i if (speed)
  end

  def distance_between_points x1, y1, x2, y2
    Math.hypot(y2 - y1, x1 - x2)
  end

  def resolve_all_turns
    @tick_bot_turn -= 360 if @tick_bot_turn > 180
    @tick_bot_turn += 360 if @tick_bot_turn < -180
    if @tick_bot_turn.abs > 10
      if @tick_bot_turn > 0
        @tick_bot_turn = 10
      else
        @tick_bot_turn = -10
      end
    end
    turn @tick_bot_turn

    @tick_gun_turn -= 360 if @tick_gun_turn > 180
    @tick_gun_turn += 360 if @tick_gun_turn < -180
    @tick_gun_turn -= @tick_bot_turn
    if (@tick_gun_turn).abs > 30
      if (@tick_gun_turn) > 0
        @tick_gun_turn =  30
      else
        @tick_gun_turn = -30
      end
    end
    turn_gun @tick_gun_turn

    @tick_radar_turn -= 360 if @tick_radar_turn > 180
    @tick_radar_turn += 360 if @tick_radar_turn < -180
    @tick_radar_turn -= @tick_gun_turn + @tick_bot_turn
    if (@tick_radar_turn).abs > 60
      if (@tick_radar_turn) > 0
        @tick_radar_turn = 60
      else
        @tick_radar_turn = -60
      end
    end
    turn_radar @tick_radar_turn
  end

  def send_pair_communication
    @@pairs_energy = energy
    @@pairs_x_destination = @x_destination
    @@pairs_y_destination = @y_destination
    @@pairs_x_location = x.to_f
    @@pairs_y_location = y.to_f
    @@pairs_x_target = @x_target
    @@pairs_y_target = @y_target
    @@pairs_time_target = @time_target
    @@pairs_x_last_target = @x_last_target
    @@pairs_y_last_target = @y_last_target
    @@pairs_time_last_target = @time_last_target
  end
end