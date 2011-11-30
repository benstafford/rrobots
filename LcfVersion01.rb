require 'robot'

class LcfVersion01
   include Robot

   def initialize
     @x_destination = x
     @y_destination = y
     @clipping_offset = 60
     @is_master = 0
     @ticks_last_robot_scanned = 0
     @has_fired = 0
     @history_ticks_last_robot_scanned = []
     @pair_is_alive = 1
   end

  def tick events
    @sent_message = false
    #puts time

    if time == 0
      send_message_to_pair "Master|?"
      @dont_shoot_distance = get_corner_to_corner_distance
      #puts "#{@is_master}|@dont_shoot_distance = #{@dont_shoot_distance}"
    end

    #slowmotion
    #sleep(0.02)

    unless events.empty?
      #puts "#{events.inspect}"
      say "Inconceivable!" if got_hit(events)

      unless events['broadcasts'].empty?
        read_pairs_message events['broadcasts'][0][0]
      else
        if (@pair_is_alive == 1) && (time > 1)
          #puts "#{@is_master}|#{time}|No pair noooooo!!!"
          @pair_is_alive = 0
          say "Nooooo!!!"
          @is_master = 1
          @dont_shoot_max_right = nil
          @dont_shoot_max_left = nil
        end
      end
    end

    def read_pairs_message raw_message
      raw_message_ray = raw_message.split("|")
      if raw_message_ray[0] == "@"
        set_dont_shoot_distance raw_message_ray[1].split(",")[0], raw_message_ray[1].split(",")[1]
      elsif raw_message_ray[0] == "^"
        #puts "#{@is_master}|#{raw_message}"
        find_catty_corner raw_message_ray[1].split(",")[0], raw_message_ray[1].split(",")[1]
      elsif raw_message_ray[0] == "Master"
        #puts "#{@is_master}|#{raw_message}"
        @is_master = time % 2
        if @is_master == 1
          #puts "#{@is_master}|I'm Master'"
          send_message_to_pair "^|#{@x_destination},#{@y_destination}"
        end
        if @is_master == 0
          #puts "#{@is_master}|Yes Master..."
        end
      else
        puts "#{@is_master}|Unhandled broadcast Message->#{raw_message}<-"
      end
    end

    def set_dont_shoot_distance pair_x, pair_y
      #puts "set_dont_shoot_distance #{pair_x}, #{pair_y}"
      @dont_shoot_distance = distance_between_points x.to_i, y.to_i, pair_x.to_i, pair_y.to_i
      #puts "#{@is_master}|@dont_shoot_distance = #{@dont_shoot_distance}"
    end

    def find_catty_corner pair_dest_x, pair_dest_y
      #puts "#{@is_master}|find_catty_corner #{pair_dest_x}, #{pair_dest_y}"
      if (@is_master == 0) #&& ("#{pair_dest_x},#{pair_dest_y}" == "#{@x_destination},#{@y_destination}")
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
        #send_message_to_pair "^|#{@x_destination},#{@y_destination}"
        #puts "#{@is_master}|Ill Go to my corner|#{@x_destination},#{@y_destination}"
        set_gun_max_turn_stops
      end
    end

    if energy > 50
      sniper_mode
    #elsif energy > 80
    #  aggressive_mode
    else
      sniper_mode
      #sidewalker_mode
      #turn_radar 1 if time == 0
      #turn_gun 30 if time < 3
      #accelerate 1
      #turn 2
      #fire 3 unless events['robot_scanned'].empty?
    end

    send_message_to_pair "@|#{x.to_i},#{y.to_i}"
  end

  def got_hit(events)
    return events.has_key? "got_hit"
  end

  def send_message_to_pair message
    #puts "send_message_to_pair"
    unless @sent_message
      #puts message
      @sent_message = true
      broadcast message
    end
  end

  def sniper_mode
    initialize_sniper_mode
    fire_last_found
    got_to_destination
  end

  def initialize_sniper_mode
    unless @initialize_sniper_mode
      #puts "initialize_sniper_mode"
      go_to_nearest_corner
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
    unless(x == @x_destination) && (y == @y_destination)
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
    end

    send_message_to_pair "^|#{@x_destination},#{@y_destination}"
    set_gun_max_turn_stops
  end

  def set_gun_max_turn_stops
    if(@x_destination == @clipping_offset) && (@y_destination == @clipping_offset)
      @gun_turn_max_left_stop=0
      @gun_turn_max_right_stop=(270-1)
      @gun_turn_left_stop=0
      @gun_turn_right_stop=(270-1)
      @dont_shoot_max_left=316
      @dont_shoot_max_right=314
    elsif(@x_destination == @battlefield_width - @clipping_offset) && (@y_destination == @clipping_offset)
      @gun_turn_max_left_stop=270
      @gun_turn_max_right_stop=(180-1)
      @gun_turn_left_stop=270
      @gun_turn_right_stop=(180-1)
      @dont_shoot_max_left=226
      @dont_shoot_max_right=224
    elsif(@x_destination == @battlefield_width - @clipping_offset) && (@y_destination == @battlefield_height - @clipping_offset)
      @gun_turn_max_left_stop=180
      @gun_turn_max_right_stop=(90-1)
      @gun_turn_left_stop=180
      @gun_turn_right_stop=(90-1)
      @dont_shoot_max_left=136
      @dont_shoot_max_right=134
    elsif(@x_destination == @clipping_offset) && (@y_destination == @battlefield_height - @clipping_offset)
      @gun_turn_max_left_stop=90
      @gun_turn_max_right_stop=359
      @gun_turn_left_stop=90
      @gun_turn_right_stop=359
      @dont_shoot_max_left=46
      @dont_shoot_max_right=44
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

   def set_gun_turn_stops
    if @has_fired == 1
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
      if @is_master == 1
        #puts "#{@is_master}|#{@ticks_last_robot_scanned}|#{@gun_turn_max_left_stop}|#{@gun_turn_left_stop}|#{@gun_heading_fired}|#{@gun_turn_right_stop}|#{@gun_turn_max_right_stop}"
      end
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
      set_sidewalker_gun_max_turn_stops
      accelerate 1
    end
  end

  def go_to_location arg_x, arg_y
    #puts "#{@is_master}|speed #{speed}"
    if(x == arg_x) && (y == arg_y)
      #puts "speed #{speed}"
      unless speed == 0
        #@dont_shoot_distance = get_corner_to_corner_distance
        stop
        say "Stopped"
        #puts "Current Location #{x}, #{y}"
      end
    else
      #puts "Current Location #{x}, #{y}"
      #puts "Trying to go to #{arg_x}, #{arg_y}"
      unless get_angle_to_location(arg_x,arg_y) == heading
        turn (get_angle_to_location arg_x, arg_y) - heading
      end
      accelerate 1
    end
  end

  def get_angle_to_location arg_x, arg_y
    #puts "arg_x->#{arg_x}|arg_y->#{arg_y}|x->#{x}|y->#{y}"
    angle = Math.atan2(y - arg_y, arg_x - x) / Math::PI * 180 % 360
    #puts "Angle to location #{arg_x},#{arg_y} == #{angle}"
    return angle
  end

  def fire_last_found
    turn_amount = 1
    max_ticks_before_fast_turn = 51
    fast_turn_amount = 4
    target_lock_patterns_to_match = 4
    fire_power = 0.1

    if @has_fired == 1
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
          #puts "#{@is_master}|(#{@history_ticks_last_robot_scanned[time-(i*3)-3]} == 0) && (#{@history_ticks_last_robot_scanned[time-(i*3)-2]} == 0) && (#{@history_ticks_last_robot_scanned[time-(i*3)-1]} == 1) && (#{@history_ticks_last_robot_scanned[time-(i*3)]} == 2)"
          if (@history_ticks_last_robot_scanned[time-(i*3)-3] == 0) && (@history_ticks_last_robot_scanned[time-(i*3)-2] == 0) && (@history_ticks_last_robot_scanned[time-(i*3)-1] == 1) && (@history_ticks_last_robot_scanned[time-(i*3)] == 2)
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
          for i in (1..target_lock_patterns_to_match)
            if (@history_ticks_last_robot_scanned[time-(i*3)-3] == 0) && (@history_ticks_last_robot_scanned[time-(i*3)-2] == 1) && (@history_ticks_last_robot_scanned[time-(i*3)-1] == 2) && (@history_ticks_last_robot_scanned[time-(i*3)] == 0)
              found = 1
              #puts "#{@is_master}|found second pattern"
            else
              found = 0
              break
            end
          end
          if found == 1
            fire_power = 3.0
          else
            for i in (1..target_lock_patterns_to_match)
              if (@history_ticks_last_robot_scanned[time-(i*3)-3] == 1) && (@history_ticks_last_robot_scanned[time-(i*3)-2] == 2) && (@history_ticks_last_robot_scanned[time-(i*3)-1] == 0) && (@history_ticks_last_robot_scanned[time-(i*3)] == 0)
                found = 1
                #puts "#{@is_master}|found third pattern"
              else
                found = 0
                break
              end
            end
            if found == 1
              fire_power = 3.0
            else
              for i in (1..target_lock_patterns_to_match)
                if (@history_ticks_last_robot_scanned[time-(i*3)-3] == 2) && (@history_ticks_last_robot_scanned[time-(i*3)-2] == 0) && (@history_ticks_last_robot_scanned[time-(i*3)-1] == 0) && (@history_ticks_last_robot_scanned[time-(i*3)] == 1)
                  found = 1
                  #puts "#{@is_master}|found fourth pattern"
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
            end
          end
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
        fire_power = 0
      end
    end

    fire fire_power
    unless events['robot_scanned'].empty?
      #puts "#{@is_master}|#{events['robot_scanned'][0][0].to_i} < #{@dont_shoot_distance.to_i}"
      #if events['robot_scanned'][0][0].to_i < @dont_shoot_distance.to_i
      dsd_ff = 120
      #puts "#{@is_master}|(#{@dont_shoot_distance.to_i + dsd_ff} < #{events['robot_scanned'][0][0].to_i}) || (#{events['robot_scanned'][0][0].to_i} < #{@dont_shoot_distance.to_i - dsd_ff})"
      if ((@dont_shoot_distance.to_i + dsd_ff) < events['robot_scanned'][0][0].to_i) || (events['robot_scanned'][0][0].to_i < (@dont_shoot_distance.to_i - dsd_ff))
        #fire 2.5
        turn_gun (-1 * turn_amount * @gun_turn_direction)
        found_enemy_robot
        @has_fired = 1
        @gun_heading_fired = gun_heading.to_i
        @distance_lasted_locked = events['robot_scanned'][0][0].to_i
      else
        if (@has_fired == 1) && (@ticks_last_robot_scanned < max_ticks_before_fast_turn)
          turn_gun (1 * turn_amount * @gun_turn_direction)
        else
          turn_gun fast_turn_amount
        end
        no_enemy_robot_found
      end
    else
      if (@has_fired == 1) && (@ticks_last_robot_scanned < max_ticks_before_fast_turn)
        turn_gun (1 * turn_amount * @gun_turn_direction)
      else
        turn_gun fast_turn_amount
      end
      no_enemy_robot_found
    end
  end

  def found_enemy_robot
    @ticks_last_robot_scanned = 0
    @history_ticks_last_robot_scanned[time] = 0
  end

  def no_enemy_robot_found
    @ticks_last_robot_scanned = @ticks_last_robot_scanned + 1
    @history_ticks_last_robot_scanned[time] = @ticks_last_robot_scanned
    #puts "#{@is_master}|#{@history_ticks_last_robot_scanned.inspect}"
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

  def got_to_destination
    #puts "Current Location #{x}, #{y}"
    #puts "Destination      #{@x_destination}, #{@y_destination}"
    go_to_location @x_destination, @y_destination
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

  def aggressive_mode
    initialize_aggressive_mode
    fire_last_found
    got_to_destination
  end

  def initialize_aggressive_mode
    unless @initialize_aggressive_mode
      puts "initialize_aggressive_mode"
      go_to_nearest_corner
      @initialize_aggressive_mode = true
    end
  end
end