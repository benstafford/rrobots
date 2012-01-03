require 'robot'
require 'LCF/destination_setter'
require 'LCF/side_walker_setter'
require 'LCF/tight_figure_eight_setter'

class LcfVersion002
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
    @@number_classes_initialized = @@number_classes_initialized + 1
    @x_destination = -1.0
    @y_destination = -1.0
    @x_last_target = -1.0
    @y_last_target = -1.0
    @time_last_target = 0
    @x_target = -1.0
    @y_target = -1.0
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
  end

  attr_reader(:x_destination)
  attr_reader(:y_destination)
  attr_reader(:x_location)
  attr_reader(:y_location)
  attr_reader(:my_heading)
  attr_reader(:pair_x_destination)
  attr_reader(:pair_y_destination)

  def tick events
    @tick_bot_turn = 0
    @tick_gun_turn = 0
    @tick_radar_turn = 0
    @x_location = x.to_f
    @y_location = y.to_f
    @my_heading = heading.to_f
    @pair_x_destination = @@pairs_x_destination
    @pair_y_destination = @@pairs_y_destination
    do_on_first_tick
    determine_if_your_pair_is_alive
    set_dont_shoot
    assess_damage
    say "Inconceivable!" if got_hit events
    sniper_mode
    resolve_all_turns
    send_pair_communication
  end

  def do_on_first_tick
    if time == 0
      @destination_setters[0] = SideWalkerSetter.new @battlefield_width.to_f, @battlefield_height.to_f, @clipping_offset.to_f
      @destination_setters[1] = TightFigureEightSetter.new @battlefield_width.to_f, @battlefield_height.to_f, @clipping_offset.to_f
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
    return Math.atan(size.to_f/(distance_between_points x.to_f, y.to_f, x_bot, y_bot)) / Math::PI * 180 % 360
  end

  def assess_damage
    if got_hit events
      @destination_setters[@@current_destination_setter].add_damage_for_this_tick(@last_turns_energy - energy)
      @last_turns_energy = energy
    end
    @destination_setters[@@current_destination_setter].add_tick if 0 < @destination_setters[@@current_destination_setter].damage_taken
  end

  def got_hit events
    return events.has_key? "got_hit"
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
    fire_fire
    find_target
    aim_at_target
    calculate_destination_based_on_damage
    got_to_destination
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

  def find_target
    if (events['robot_scanned'].empty?)
      if @last_scan_angle == @current_scan_angle
        @current_scan_angle = 60
        @last_scan_angle = 60
      else
        @last_scan_angle = @current_scan_angle
      end
    else
      dsd_ff = 2
      if ((@dont_shoot_distance.to_f + dsd_ff) < events['robot_scanned'][0][0].to_f) || (events['robot_scanned'][0][0].to_f < (@dont_shoot_distance.to_f - dsd_ff))
        if @current_scan_angle < (0.9 * 2 * (get_angle_to_edge_of_bot_from_distance events['robot_scanned'][0][0].to_f))
          set_target events['robot_scanned'][0][0].to_f, (@current_scan_angle/2 * @radar_scan_direction * -1) + radar_heading.to_f
          @current_scan_angle = 60
          @last_scan_angle = 60
          @radar_scan_direction = @radar_scan_direction * -1
          return
        else
          @radar_scan_direction = -1 * @radar_scan_direction
          @current_scan_angle = (@current_scan_angle.to_f / 2.0).to_f
        end
      end
    end
    tick_radar_turn @current_scan_angle * @radar_scan_direction
  end

  def return_cord x_start_from, y_start_from, heading, distance
    radi_angle = heading * Math::PI / 180
    x_return = x_start_from + (Math.cos(radi_angle) * distance)
    y_return = y_start_from - (Math.sin(radi_angle) * distance)
    return x_return, y_return
  end

  def get_angle_to_edge_of_bot_from_distance distance_from_bot
    Math.atan(size.to_i/distance_from_bot) / Math::PI * 180 % 360
  end

  def aim_at_target heading_to_target = gun_heading.to_f
    unless get_angle_to_location(@x_target, @y_target).to_i == heading_to_target.to_i
      tick_gun_turn (get_angle_to_location @x_target, @y_target).to_f - heading_to_target
    end
  end

  def get_angle_to_location arg_x, arg_y
    unless (x == arg_x) && (y == arg_y)
      angle = Math.atan2(y - arg_y, arg_x - x) / Math::PI * 180 % 360
    else
      angle = 0
    end
    return angle
  end

  def calculate_destination_based_on_damage
    if (energy.to_f < @@pairs_energy) || (@pair_is_alive == 0)
      lowest_damage_destination_setter = calculate_the_best_destination_setter_now
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

  def calculate_the_best_destination_setter_now
    the_best_destination_setter = @@current_destination_setter
    for i in 0 ... @destination_setters.size
      if @destination_setters[i].average_damage_per_tick < @destination_setters[the_best_destination_setter].average_damage_per_tick
        the_best_destination_setter = i
      end
    end
    return the_best_destination_setter
  end

  def got_to_destination
    turn_to_location @x_destination, @y_destination
    accelerate_bot
  end

  def turn_to_location arg_x, arg_y
    unless get_angle_to_location(arg_x, arg_y) == heading.to_i
      tick_bot_turn (get_angle_to_location arg_x, arg_y) - heading.to_f
    end
  end

  def accelerate_bot
    accelerate (Math.sqrt(distance_between_points x.to_f, y.to_f, @x_destination, @y_destination).to_i) - speed.to_i if (speed)
  end

  def set_target distance_to_target, radar_heading_arg = radar_heading.to_f
    radi_angle = radar_heading_arg * Math::PI / 180
    @x_last_target = @x_target
    @y_last_target = @y_target
    @time_last_target = @time_target
    @x_target = x.to_f + (Math.cos(radi_angle) * distance_to_target)
    @y_target = y.to_f - (Math.sin(radi_angle) * distance_to_target)
    @time_target = time
  end

  def distance_between_points x1, y1, x2, y2
    Math.hypot(y2 - y1, x1 - x2)
  end
end