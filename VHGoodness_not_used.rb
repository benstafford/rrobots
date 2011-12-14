require 'robot'
require 'numeric'

class VHGoodness
  include Robot

  def initialize
    @my_heading = nil
    @id = rand(100)
    @partner = nil
    @mode = :search
    @last_e_scan_time = 0
    @last_radar_turn = 0
  end

  def tick events
    @bot_turn = 0
    @gun_turn = 0
    @radar_turn = 0
    @events = events
    if @mode == :search
      @e_x, @e_y = 0, 0
      if @events['robot_scanned'].empty?
        @mode = :search
        @radar_turn = 10
        @last_radar_turn = 10
      else
        @mode = :assault
        @e_x, @e_y = get_robot_location_from_events
        @e_heading = heading_to_point @e_x, @e_y
        @last_e_scan_time = time
        @radar_turn = -1 * @last_radar_turn
        @last_radar_turn = @radar_turn
      end
    elsif @mode == :assault
      if @events['robot_scanned'].empty?
        @mode = :search
        @radar_turn = 10
        @last_radar_turn = 10
      else
        @e_x, @e_y = get_robot_location_from_events
        @e_heading = heading_to_point @e_x, @e_y
        @last_e_scan_time = time
        @radar_turn = -1 * @last_radar_turn
        @last_radar_turn = @radar_turn
        if heading.to_i != @e_heading.to_i
          if (@e_heading - heading).abs > 10
            @bot_turn = 10
          else
            @bot_turn = @e_heading - heading
          end
          @radar_turn = @radar_turn - @bot_turn
        end
      end
    end
    accelerate 1
    fire 0.1
    turn @bot_turn
    turn_gun @gun_turn
    turn_radar @radar_turn
  end

  def get_robot_location_from_events
    position_from_distance_and_angle(@events['robot_scanned'][0][0], radar_heading-5)
  end

  def position_from_distance_and_angle(distance, angle)
    d_x = distance * Math.cos(angle * Math::PI/180)
    d_y = -distance * Math.sin(angle * Math::PI/180)
    output "Delta X: #{d_x} + my x: #{x} = E Loc: #{x+d_x}"
    output "Delta Y: #{d_y} + my y: #{y} = E Loc: #{y+d_y}"
    return x + d_x, y + d_y
  end

  def heading_to_point x_1, y_1
    offset_for_y_axis = -1
    d_x = (x_1-x)
    d_y = ((offset_for_y_axis*y_1)-(offset_for_y_axis*y))
    angle = Math.atan2(d_y, d_x).to_deg
    angle += 360 if angle < 0
    angle
  end

  def converge
    
  end

  def output string
    puts "#{@id}|#{time}|#{string}"
  end
end