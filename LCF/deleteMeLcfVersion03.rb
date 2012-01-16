require 'robot'
require 'LCF/destination_setter'
require 'LCF/dont_move_setter'
require 'LCF/go_to_corner_setter'
require 'LCF/side_walker_setter'
require 'LCF/get_on_target_setter'
require 'LCF/tight_figure_eight_setter'

class DeleteMeLcfVersion03
  include Robot

  attr_reader(:x_destination)
  attr_reader(:y_destination)
  attr_reader(:x_location)
  attr_reader(:y_location)
  attr_reader(:my_speed)
  attr_reader(:x_target)
  attr_reader(:y_target)
  attr_reader(:my_gun_heading)
  attr_reader(:my_heading)
  attr_reader(:my_radar_heading)
  attr_reader(:my_time)
  attr_reader(:battlefield_width)
  attr_reader(:battlefield_height)
  attr_reader(:clipping_offset)
  attr_reader(:is_master)
  attr_reader(:pair_x_destination)
  attr_reader(:pair_y_destination)

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
  @@current_destination_setter = 0
  @@pairs_energy = 100

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
    @distance_to_target = -1.0
    @clipping_offset = 121
    @has_scanned_enemy_robot = 0
    @pair_is_alive = 1
    @radar_scan_direction = 1
    @current_scan_angle = 60
    @last_scan_angle = 60
    @@was_here = 2
    @@current_destination_setter = 0
    @destination_setters = []
    @last_turns_energy = 100
    @@pairs_energy = 100
    @time_last_destination_setter_change = 0

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
    @x_location = x.to_f
    @y_location = y.to_f
    @my_speed = speed.to_i
    @my_gun_heading = gun_heading.to_f
    @my_radar_heading = radar_heading.to_f
    @my_heading = heading.to_f
    @my_time = time
    if @is_master == 1
      @pair_x_destination = @@slave_x_destination
      @pair_y_destination = @@slave_y_destination
    else
      @pair_x_destination = @@master_x_destination
      @pair_y_destination = @@master_y_destination
    end
    do_on_first_tick
    determine_if_your_pair_is_alive
    set_dont_shoot
    slow_motion 0, 1.00
    assess_damage
    say "Inconceivable!" if got_hit events
    #say "speed #{speed}"
    sniper_mode
    set_location
    resolve_all_turns
    @@pairs_energy = energy
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
      @@pairs_energy = 100
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
    return Math.atan(size.to_f/(distance_between_points x.to_f, y.to_f, x_bot, y_bot)) / Math::PI * 180 % 360
  end

  def slow_motion enabled, seconds
    if (enabled == 1) && (@is_master == 1)
      sleep(seconds)
    end
  end

  def assess_damage
    if got_hit events
      @destination_setters[@@current_destination_setter].add_damage_for_this_tick(@last_turns_energy - energy)
      #puts "#{@is_master}|#{@destination_setters[@@current_destination_setter].average_damage_per_tick}" if @is_master == 1
      #puts "#{@is_master}|took #{@last_turns_energy - energy} damage" if @is_master == 1
      @last_turns_energy = energy
    end
    @destination_setters[@@current_destination_setter].add_tick if 0 < @destination_setters[@@current_destination_setter].damage_taken
  end

  def got_hit events
    #puts "#{@is_master}|time = #{time}|#{events["got_hit"]}" if events.has_key? "got_hit"
    return events.has_key? "got_hit"
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
    #puts "#{@tick_bot_turn} #{@tick_gun_turn} #{@tick_radar_turn}" if @is_master == 1
    @tick_bot_turn -= 360 if @tick_bot_turn > 180
    @tick_bot_turn += 360 if @tick_bot_turn < -180
    if @tick_bot_turn.abs > 10
      #puts "#{@is_master}|over max turn #{@tick_bot_turn}" if @is_master == 1
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
      #puts "#{@is_master}|over max turn_gun #{@tick_gun_turn}" if @is_master == 1
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
      #puts "#{@is_master}|over max turn_radar #{@tick_radar_turn}" if @is_master == 1
      if (@tick_radar_turn) > 0
        @tick_radar_turn = 60
      else
        @tick_radar_turn = -60
      end
    end
    turn_radar @tick_radar_turn
    #puts "#{@is_master}|#{@x_target.to_i},#{@y_target.to_i}|#{@tick_bot_turn}|#{@tick_gun_turn}|#{@tick_radar_turn}" if @is_master == 1
  end

  def tick_bot_turn angle
    #puts "#{@is_master}|tick_bot_turn #{angle}" if @is_master == 1
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
    fire_fire
    scan_for_next_target
    aim_at_target
    #aim_at_masters_target
    #aim_at_left_edge_of_target
    #aim_at_newest_target
    #aim_at_right_edge_of_newest_target
    calculate_destination_based_on_damage
    got_to_destination
  end

  def initialize_sniper_mode
    unless @initialize_sniper_mode
      #puts "initialize_sniper_mode"
      @initialize_sniper_mode = true
      @gun_turn_direction = 1
    end
  end

  def set_destination
    if @is_master == 1
      @@master_x_destination = @x_destination
      @@master_y_destination = @y_destination
    else
      @@slave_x_destination = @x_destination
      @@slave_y_destination = @y_destination
    end
    #puts "currLoc(#{x},#{y})|dest(#{@x_destination},#{@y_destination})|get_angle_to_location#{get_angle_to_location @x_destination, @y_destination}|heading#{heading}" if @is_master == 1
    if (@x_destination == @battlefield_width - @clipping_offset) && (@y_destination == @clipping_offset)
      @start_logging = 1
    end
    #puts "currLoc(#{x},#{y})|dest(#{@x_destination},#{@y_destination})" if @is_master == 1
  end

  def fire_fire
    fire_power = 3.0
    if (@dont_shoot_max_right != nil) && (@dont_shoot_max_left != nil)
      if (@dont_shoot_max_right < gun_heading.to_f) && (gun_heading.to_f < @dont_shoot_max_left)
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
      dsd_ff = 2
      #puts "#{@is_master}|dif(#{(@dont_shoot_distance.to_i + dsd_ff)-events['robot_scanned'][0][0].to_i})(#{@dont_shoot_distance.to_i + dsd_ff} < #{events['robot_scanned'][0][0].to_i}) || (#{events['robot_scanned'][0][0].to_i} < #{@dont_shoot_distance.to_i - dsd_ff})dif(#{events['robot_scanned'][0][0].to_i - (@dont_shoot_distance.to_i - dsd_ff)})" if @is_master == 1
      if ((@dont_shoot_distance.to_f + dsd_ff) < events['robot_scanned'][0][0].to_f) || (events['robot_scanned'][0][0].to_f < (@dont_shoot_distance.to_f - dsd_ff))
        #set_target events['robot_scanned'][0][0].to_f, (@current_scan_angle/2 * @radar_scan_direction * -1) + radar_heading.to_f if @current_scan_angle < 30
        #puts "if #{@current_scan_angle} < #{(get_angle_to_edge_of_bot_from_distance events['robot_scanned'][0][0].to_f) * 2}" if @is_master == 1
        if @current_scan_angle < (0.9 * 2 * (get_angle_to_edge_of_bot_from_distance events['robot_scanned'][0][0].to_f))
          set_target events['robot_scanned'][0][0].to_f, (@current_scan_angle/2 * @radar_scan_direction * -1) + radar_heading.to_f
          #puts "#{@is_master}|First Target(#{@x_target},#{@y_target})|dist = #{events['robot_scanned'][0][0].to_f}, (#{@current_scan_angle}/2 * #{@radar_scan_direction} * -1) + #{radar_heading.to_f} = #{(@current_scan_angle/2 * @radar_scan_direction * -1) + radar_heading.to_f}" if @is_master == 1
          #puts "#{@is_master}|Targeted|#{time}" if @is_master == 1
          #@current_scan_angle = @last_scan_angle
          @current_scan_angle = 60
          @last_scan_angle = 60
          @radar_scan_direction = @radar_scan_direction * -1
          return
        else
          #puts "#{@is_master}|something|#{@current_scan_angle} * #{@radar_scan_direction}" if @is_master == 1
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
    return Math.atan(size.to_i/distance_from_bot) / Math::PI * 180 % 360
  end

  def aim_at_target heading_to_target = gun_heading.to_f
    unless get_angle_to_location(@x_target, @y_target).to_i == heading_to_target.to_i
      tick_gun_turn (get_angle_to_location @x_target, @y_target).to_f - heading_to_target
    end
  end

  def aim_at_left_edge_of_target
    heading_to_target = (get_angle_to_location @x_target, @y_target).to_f + (1 * get_angle_to_edge_of_bot_from_distance(@distance_to_target) * 1.0)
    unless heading_to_target.to_i == gun_heading.to_i
      tick_gun_turn heading_to_target - gun_heading.to_f
    end
  end

  def aim_at_masters_target
    if (@@master_x_target != -1) && (@@master_y_target != -1)
      @x_target = @@master_x_target
      @y_target = @@master_y_target
      aim_at_target
    end
  end

  def aim_at_newest_target
    if @is_master == 1
      if (@@slave_x_target != -1) && (@@slave_y_target != -1)
        if @@slave_time_target > @@master_time_target
          @x_target = @@slave_x_target
          @y_target = @@slave_y_target
        end
      end
    else
      if (@@master_x_target != -1) && (@@master_y_target != -1)
        if @@master_time_target > @@slave_time_target
          @x_target = @@master_x_target
          @y_target = @@master_y_target
        end
      end
    end
    aim_at_target
  end

  def aim_at_closest_target
    if @is_master == 1
      if (@@slave_x_target != -1) && (@@slave_y_target != -1)
        if @distance_to_target > distance_between_points(@x_target, @y_target, @@slave_x_target, @@slave_y_target)
          @x_target = @@slave_x_target
          @y_target = @@slave_y_target
        end
      end
    else
      if (@@master_x_target != -1) && (@@master_y_target != -1)
        if @distance_to_target > distance_between_points(@x_target, @y_target, @@master_x_target, @@master_y_target)
          @x_target = @@master_x_target
          @y_target = @@master_y_target
        end
      end
    end
    aim_at_target
  end

  def aim_at_right_edge_of_newest_target
    aim_at_newest_target
    aim_at_right_edge_of_target
  end

  def predictive_aim_at_target
    if (@x_last_target == -1) && (@y_last_target == -1) && (@time_last_target == 0)
      x_target = @x_target
      y_target = @y_target
    else
      #can the 2 point be the same bot
      if speed.to_i == 0
        puts "#{@is_master}|if #{(distance_between_points @x_last_target, @y_last_target, @x_target, @y_target)/(@time_target - @time_last_target)} < 30"
        if ((distance_between_points @x_last_target.to_f, @y_last_target.to_f, @x_target.to_f, @y_target.to_f).to_f/(@time_target - @time_last_target).to_f).to_f < 30
          #puts "#{@is_master}|Doing predictive shoot!!!|Same" if @is_master == 1

        else
          x_target = @x_target
          y_target = @y_target
        end
      end
    end

    unless get_angle_to_location(x_target, y_target).to_i == gun_heading.to_i
      tick_gun_turn (get_angle_to_location x_target.to_f, y_target.to_f).to_f - gun_heading.to_f
    end
  end

  def get_angle_to_location arg_x, arg_y
    unless (x == arg_x) && (y == arg_y)
      #puts "arg_x->#{arg_x}|arg_y->#{arg_y}|x->#{x}|y->#{y}" if @is_master == 1
      angle = Math.atan2(y - arg_y, arg_x - x) / Math::PI * 180 % 360
      #puts "Angle to location #{arg_x},#{arg_y} == #{angle}" if !@start_logging.nil?
    else
      #puts "Error|Trying to get an angle to the same point|arg_x->#{arg_x}|arg_y->#{arg_y}|x->#{x}|y->#{y}"
      angle = 0
    end
    return angle
  end

  def calculate_destination_based_on_damage

    #puts "#{@is_master}|if (#{energy.to_f} < #{@@pairs_energy}) || (#{@is_master} == 1)"
    if (energy.to_f < @@pairs_energy) #|| (@is_master == 1)
      #@destination_setters.each_with_index { |x, i| lowest_damage_destination_setter = i if x.average_damage_per_tick < @destination_setters[@@current_destination_setter].average_damage_per_tick}
      lowest_damage_destination_setter = calculate_the_best_destination_setter_now
      if (@time_last_destination_setter_change == 0) || ((time - @time_last_destination_setter_change) > 15)
        #puts "#{@is_master}|if (#{@time_last_destination_setter_change} == 0) || ((#{time} - #{@time_last_destination_setter_change}) > 15)"
        if (lowest_damage_destination_setter != @@current_destination_setter)
          say @destination_setters[lowest_damage_destination_setter].get_name
          #puts "#{@is_master}|#{@destination_setters[lowest_damage_destination_setter].get_name}#{@destination_setters[lowest_damage_destination_setter].average_damage_per_tick}"
        end
        @@current_destination_setter = lowest_damage_destination_setter
        @time_last_destination_setter_change = time
      end
    end
    #say "distance from target #{distance_between_points(@x_location, @y_location, @x_target, @x_target).to_i}" if (@x_target != -1) && (@y_target != -1)
    @x_destination, @y_destination = @destination_setters[@@current_destination_setter].calculate_destination self
    set_destination
  end

  def calculate_the_best_destination_setter_now
    the_best_destination_setter = @@current_destination_setter
    #@destination_setters.each_with_index { |x, i| lowest_damage_destination_setter = i if x.average_damage_per_tick < @destination_setters[@@current_destination_setter].average_damage_per_tick}
    for i in 0 ... @destination_setters.size
      #puts "#{@is_master}|#{time}|#{@destination_setters[i].get_name}|#{@destination_setters[i].average_damage_per_tick}|#{@destination_setters[i].damage_taken}|#{@destination_setters[i].ticks_used}"
      if @destination_setters[i].average_damage_per_tick < @destination_setters[the_best_destination_setter].average_damage_per_tick
        the_best_destination_setter = i
      end
    end
    #puts "#{@is_master}|#{time}|#{@destination_setters[the_best_destination_setter].get_name} is the best!!!"
    return the_best_destination_setter
  end

  def got_to_destination
    #puts "#{@is_master}|at(#{x},#{y})dest(#{@x_destination},#{@y_destination})"
    turn_to_location @x_destination, @y_destination
    accelerate_bot
    @last_x_location = x
    @last_y_location = y
  end

  def turn_to_location arg_x, arg_y
    #puts "Current Location #{x}, #{y}" if @is_master == 1
    #puts "Trying to go to #{arg_x}, #{arg_y}" if @is_master == 1
    #puts "#{@is_master}|#{time}|#{(get_angle_to_location arg_x, arg_y) - heading}"
    unless get_angle_to_location(arg_x, arg_y) == heading.to_i
      #puts "before tick_bot_turn|currLoc(#{x},#{y})|dest(#{@x_destination},#{@y_destination})|get_angle_to_location#{get_angle_to_location @x_destination, @y_destination}|heading#{heading}" if @is_master == 1
      tick_bot_turn (get_angle_to_location arg_x, arg_y) - heading.to_f
    end
  end

  def accelerate_bot
    #puts "#{@is_master}|accelerate #{(Math.sqrt(distance_between_points x.to_f, y.to_f, @x_destination, @y_destination).to_i)}" if @is_master == 1
    accelerate (Math.sqrt(distance_between_points x.to_f, y.to_f, @x_destination, @y_destination).to_i) - speed.to_i if (speed)
  end

  def set_target distance_to_target, radar_heading_arg = radar_heading.to_f
    radi_angle = radar_heading_arg * Math::PI / 180
    #puts "#{@is_master}|#{gun_heading.to_f}|#{radi_angle}|#{distance_to_target}"
    @x_last_target = @x_target
    @y_last_target = @y_target
    @time_last_target = @time_target

    @x_target = x.to_f + (Math.cos(radi_angle) * distance_to_target)
    @y_target = y.to_f - (Math.sin(radi_angle) * distance_to_target)
    @distance_to_target = distance_to_target
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

  def get_corner_to_corner_distance
    distance_between_points @clipping_offset, @clipping_offset, (@battlefield_width - @clipping_offset), ((@battlefield_height - @clipping_offset))
  end

  def distance_between_points x1, y1, x2, y2
    Math.hypot(y2 - y1, x1 - x2)
  end
end