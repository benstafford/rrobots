require 'robot'
require 'numeric'
require 'Matrix'

class VHGoodness
  include Robot

  def initialize
    @my_heading = nil
    @id = rand(100)
  end

  def tick events
    @last_robot_turn = 0
    @p_x, @p_y = location_from_broadcasts events
    navigate
    if events['robot_scanned'].empty?
      turn_gun(10)
    else
      @e_x, @e_y = get_robot_scanned_location events['robot_scanned'][0][0]
      if is_partner_scanned? @e_x, @e_y
        converge_on @e_x, @e_y
        output "I'm at: #{x}, #{y}'"
        output "Partner is at: #{@p_x}, #{@p_y}"
        output "Scanned Robot at: #{@e_x}, #{@e_y}"
        output "Angle to Robot Scanned is: #{angle_between_two_points x, y, @e_x, @e_y}"
        output "My heading is #{@my_heading}; Moving #{heading}"
      end
    end
    broadcast_location

    #converge_on (battlefield_width/2), (battlefield_height/2)
  end

  def output string
    puts "#{@id}|#{time}|#{string}"
  end

  def broadcast_location
    broadcast "loc|#{x.to_i}|#{y.to_i}"
  end

  def location_from_broadcasts events
    if !events['broadcasts'].empty?
      p_vars = events['broadcasts'][0][0].split('|')
      p_x = p_vars[1].to_i
      p_y = p_vars[2].to_i
    else
      p_x, p_y = 0, 0
    end
    return p_x, p_y
  end

  def navigate
  end

  def converge_on c_x, c_y
    @my_heading = angle_between_two_points x, y, c_x, c_y
    if !on_heading?
      get_on_heading
      accelerate(-1)
    else
      accelerate 1
    end
  end

  def on_heading?
    (@my_heading - heading).abs < 2
  end

  def get_on_heading
    amount_to_turn = (@my_heading - heading)
    turn amount_to_turn
    if amount_to_turn > 10
      return 10
    end
    amount_to_turn
  end

  def get_robot_scanned_location distance
    e_vector = position_from_distance_and_angle(distance, radar_heading-5)
    return e_vector[0].to_i, e_vector[1].to_i
  end

  def position_from_distance_and_angle(distance, angle)
    angle = 1 if angle <= 0
    # * Math::PI/180
    d_x = trim(distance * Math.cos(angle * Math::PI/180))
    d_y = trim(-distance * Math.sin(angle * Math::PI/180))
    puts "Delta X: #{d_x} + my x: #{x} = E Loc: #{x+d_x}"
    puts "Delta Y: #{d_y} + my y: #{y} = E Loc: #{y+d_y}"

    target_vector = Vector[d_x,
                           d_y]
    target_vector + Vector[x,(y)]
    #Vector[trim(distance * Math.cos(angle * Math::PI/180)) + x,
    #       trim(-distance * Math.sin(angle * Math::PI/180)) - (y)]
  end

  def is_partner_scanned? scanned_x, scanned_y
    scanned_angle = angle_between_two_points x, y, scanned_x, scanned_y
    is_within_fifteen_degree_range? scanned_angle, radar_heading
  end

  def dont_shoot? my_gun_angle
    p_angle = angle_between_two_points x, y, @p_x, @p_y
    should_not_fire = is_within_fifteen_degree_range? p_angle, my_gun_angle
    should_not_fire
  end

  def angle_between_two_points x_1, y_1, x_2, y_2
    offset_for_y_axis = -1
    d_x = (x_2-x_1)
    d_y = ((offset_for_y_axis*y_2)-(offset_for_y_axis*y_1))
    angle = Math.atan2(d_y, d_x).to_deg
    angle += 360 if angle < 0
    angle
  end

  def is_within_fifteen_degree_range? p_angle, my_gun_angle
    (p_angle - my_gun_angle).abs < 15
  end

  def trim number
    (number * 1000).round.to_f / 1000
  end
end

#battlefield_height  #the height of the battlefield
#  battlefield_width   #the width of the battlefield
#  energy              #your remaining energy (if this drops below 0 you are dead)
#  gun_heading         #the heading of your gun, 0 pointing east, 90 pointing
#                      #north, 180 pointing west, 270 pointing south
#  gun_heat            #your gun heat, if this is above 0 you can't shoot
#  heading             #your robots heading, 0 pointing east, 90 pointing north,
#                      #180 pointing west, 270 pointing south
#  size                #your robots radius, if x <= size you hit the left wall
#  radar_heading       #the heading of your radar, 0 pointing east,
#                      #90 pointing north, 180 pointing west, 270 pointing south
#  time                #ticks since match start
#  speed               #your speed (-8/8)
#  x                   #your x coordinate, 0...battlefield_width
#  y                   #your y coordinate, 0...battlefield_height
#  accelerate(param)   #accelerate (max speed is 8, max accelerate is 1/-1,
#                      #negativ speed means moving backwards)
#  stop                #accelerates negativ if moving forward (and vice versa),
#                      #may take 8 ticks to stop (and you have to call it every tick)
#  fire(power)         #fires a bullet in the direction of your gun,
#                      #power is 0.1 - 3, this power will heat your gun
#  turn(degrees)       #turns the robot (and the gun and the radar),
#                      #max 10 degrees per tick
#  turn_gun(degrees)   #turns the gun (and the radar), max 30 degrees per tick
#  turn_radar(degrees) #turns the radar, max 60 degrees per tick
#  dead                #true if you are dead
#  say(msg)            #shows msg above the robot on screen
#  broadcast(msg)      #broadcasts msg to all bots (they recieve 'broadcasts'
#                      #events with the msg and rough direction)