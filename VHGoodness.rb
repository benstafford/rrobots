require 'robot'
require 'numeric'
require 'Matrix'

class VHGoodness
  include Robot

  def initialize
    @speed_modifier = 1
    @gun_turn = -10
    @fire_power = 0.1
    @turn_bot = 0
    @my_heading = nil
    @id = rand(100)
    @p_x, @p_y = 0, 0
  end

  def tick events
    @last_robot_turn = 0
    @p_x, @p_y = location_from_broadcasts events
    @e_x, @e_y = enemy_location


    move_around

    turn_gun(@gun_turn)
    accelerate(@speed_modifier)
    fire(@fire_power)
    broadcast_location
  end

  def broadcast_location
    broadcast "loc|#{x.to_i}|#{y.to_i}"
  end

  def location_from_broadcasts events
    if !events['broadcasts'].empty?
      p_vars = events['broadcasts'][0][0].split('|')
      return p_vars[1].to_i, p_vars[2].to_i
    end
    return 0, 0
  end

  def enemy_location
    if !events['robot_scanned'].empty? and !pointed_at_partner? @p_x, @p_y
      @gun_turn = -@gun_turn
      return position_from_distance_and_angle events['robot_scanned'][0][0]
    end
    return nil, nil
  end

  def pointed_at_partner? p_x, p_y
    offset_for_y_axis = -1
    d_x = (p_x-x)
    d_y = ((offset_for_y_axis*p_y)-(offset_for_y_axis*y))
    angle = Math.atan2(d_y, d_x).to_deg
    angle += 360 if angle < 0
    (radar_heading - angle).abs < 15
  end

  def position_from_distance_and_angle(distance, angle = radar_heading-5)
    d_x = distance * Math.cos(angle * Math::PI/180)
    d_y = -distance * Math.sin(angle * Math::PI/180)
    return x + d_x, y + d_y
  end

  def move_around
    if (speed == 4 or speed == -4)
      @speed_modifier = -@speed_modifier
    end
  end

  def output string
    puts "#{@id}|#{time}|#{string}"
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