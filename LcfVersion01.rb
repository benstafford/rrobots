require 'robot'

class LcfVersion01
   include Robot

   def initialize
     @x_destination = x
     @y_destination = y
     @clipping_offset = 60
     @is_master = 0
   end

  def tick events
    @sent_message = false
    #puts time

    if time == 0
      send_message_to_pair "Master|?"
    end

    #slowmotion
    #sleep(0.02)

    unless events.empty?
      #puts "#{events.inspect}"
      say "Inconceivable!" if got_hit(events)

      unless events['broadcasts'].empty?
        read_pairs_message events['broadcasts'][0][0]
      end
    end

    def read_pairs_message raw_message
      raw_message_ray = raw_message.split("|")
      if raw_message_ray[0] == "@"
        set_dont_shoot raw_message_ray[1].split(",")[0], raw_message_ray[1].split(",")[1]
      elsif raw_message_ray[0] == "^"
        find_catty_corner raw_message_ray[1].split(",")[0], raw_message_ray[1].split(",")[1]
      elsif raw_message_ray[0] == "Master"
        @is_master = time % 2
        if @is_master == 1
          puts "I'm Master'"
        end
        if @is_master == 0
          puts "Yes Master..."
        end
        send_message_to_pair "^|#{@x_destination},#{@y_destination}"
      else
        puts "Unhandled broadcast Message->#{raw_message}<-"
      end
    end

    def set_dont_shoot pair_x, pair_y
      #puts "set_dont_shoot #{pair_x}, #{pair_y}"
    end

    def find_catty_corner pair_dest_x, pair_dest_y
      puts "find_catty_corner #{pair_dest_x}, #{pair_dest_y}"
      if (@is_master == 0) && ("#{pair_dest_x},#{pair_dest_y}" == "#{@x_destination},#{@y_destination}")
        puts "crap same corner"
        if(@x_destination == @clipping_offset) && (@y_destination == @clipping_offset)#upper_left
          @x_destination = @battlefield_width - @clipping_offset
          @y_destination = @battlefield_height - @clipping_offset
        elsif(@x_destination == @battlefield_width - @clipping_offset) && (@y_destination == @clipping_offset)#upper_right
          @x_destination = @clipping_offset
          @y_destination = @battlefield_height - @clipping_offset
        elsif(@x_destination == @battlefield_width - @clipping_offset) && (@y_destination == @battlefield_height - @clipping_offset)#lower_right
          @x_destination = @clipping_offset
          @y_destination = @clipping_offset
        elsif(@x_destination == @clipping_offset) && (@y_destination == @battlefield_height - @clipping_offset)#lower_left
          @x_destination = @battlefield_width - @clipping_offset
          @y_destination = @clipping_offset
        end
        send_message_to_pair "^|#{@x_destination},#{@y_destination}"
      end
    end

    if energy > 90
      sniper_mode
    #elsif energy > 80
    #  aggressive_mode
    else
      turn_radar 1 if time == 0
      turn_gun 30 if time < 3
      accelerate 1
      turn 2
      fire 3 unless events['robot_scanned'].empty?
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
      puts "initialize_sniper_mode"
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
    set_gun_turn_stops
  end

  def set_gun_turn_stops
    if(@x_destination == @clipping_offset) && (@y_destination == @clipping_offset)
      @gun_turn_left_stop=0
      @gun_turn_right_stop=270
    elsif(@x_destination == @battlefield_width - @clipping_offset) && (@y_destination == @clipping_offset)
      @gun_turn_left_stop=270
      @gun_turn_right_stop=180
    elsif(@x_destination == @battlefield_width - @clipping_offset) && (@y_destination == @battlefield_height - @clipping_offset)
      @gun_turn_left_stop=180
      @gun_turn_right_stop=90
    elsif(@x_destination == @clipping_offset) && (@y_destination == @battlefield_height - @clipping_offset)
      @gun_turn_left_stop=90
      @gun_turn_right_stop=0
    end
  end

  def go_to_next_corner
    #upper_left = @clipping_offset, @clipping_offset
    #upper_right = @battlefield_width - @clipping_offset, @clipping_offset
    #lower_right = @battlefield_width - @clipping_offset, @battlefield_height - @clipping_offset
    #lower_left = @clipping_offset, @battlefield_height - @clipping_offset
    puts "got to next corner"

    if(x == @clipping_offset) && (y == @clipping_offset)
      @x_destination = @battlefield_width - @clipping_offset
      @y_destination = @clipping_offset
    elsif(x == @battlefield_width - @clipping_offset) && (y == @clipping_offset)
      @x_destination = @battlefield_width - @clipping_offset
      @y_destination = @battlefield_height - @clipping_offset
    elsif(x == @battlefield_width - @clipping_offset) && (y == @battlefield_height - @clipping_offset)
      @x_destination = @clipping_offset
      @y_destination = @battlefield_height - @clipping_offset
    elsif(x == @clipping_offset) && (y == @battlefield_height - @clipping_offset)
      @x_destination = @clipping_offset
      @y_destination = @clipping_offset
    else
      #do some default
    end

    send_message_to_pair "^|#{@x_destination},#{@y_destination}"
    set_gun_turn_stops
  end

  def go_to_location arg_x, arg_y
    if(x == arg_x) && (y == arg_y)
      #puts "speed #{speed}"
      unless speed == 0
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
    #puts "radar, gun heading #{radar_heading}, #{gun_heading}"
    #puts "gun_heading->#{gun_heading.to_i}|@gun_turn_left_stop->#{@gun_turn_left_stop}|@gun_turn_right_stop->#{@gun_turn_right_stop}|@gun_turn_direction->#{@gun_turn_direction}"

    if @gun_turn_direction > 0
      if gun_heading.to_i == @gun_turn_left_stop
        @gun_turn_direction = (-1 * @gun_turn_direction)
        #puts "Change direction #{gun_heading}"
      end
    else
      if gun_heading.to_i == @gun_turn_right_stop
        @gun_turn_direction = (-1 * @gun_turn_direction)
        #puts "Change direction #{gun_heading}"
      end
    end

    unless events['robot_scanned'].empty?
      fire 3
      turn_gun (-1 * turn_amount * @gun_turn_direction)
    else
      turn_gun (1 * turn_amount * @gun_turn_direction)
    end

    #turn_gun (1 * @gun_turn_direction)

    #turn_radar 5 if time == 0
    #fire 3 unless events['robot_scanned'].empty?
    #turn_gun 10
  end

  def got_to_destination
    #puts "Current Location #{x}, #{y}"
    #puts "Destination      #{@x_destination}, #{@y_destination}"
    go_to_location @x_destination, @y_destination
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