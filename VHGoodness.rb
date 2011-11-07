require 'robot'
require 'numeric'

class VHGoodness
   include Robot
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
  def tick events
    if events['robot_scanned'].empty?
      turn_gun(10)
    else
      navigate
      if !dont_shoot?(gun_heading)
        fire(3)
      end
    end
    broadcast_location
  end

  def broadcast_location
    puts "SENDING LCOATION AS: #{x.to_i}|#{y.to_i}"
    broadcast "#{x.to_i}|#{y.to_i}"
  end

  def navigate
    distance_from_edge = 250
    if speed < 4
      accelerate(1)
    end
    if x >= (battlefield_width - distance_from_edge) or x <= distance_from_edge or y >= (battlefield_height - distance_from_edge) or y <= distance_from_edge
      turn 10
    end
  end

  def dont_shoot? my_gun_angle
    p_x, p_y = 0.0,0.0
    if !events['broadcasts'].nil?
      #puts "RECEIVED BROADCASTS: #{events['broadcasts']}"
      p_vars = events['broadcasts'][0][0].split('|')
      p_x = p_vars[0].to_f
      p_y = p_vars[1].to_f
      #puts "RECIEVED LCOATION AS #{p_x},#{p_y}"
    end
    
    p_angle = angle_give_two_points x, y, p_x, p_y
    should_not_fire = is_within_fifteen_degree_range? p_angle, my_gun_angle
    puts "(#{x}, #{y} should fire = #{should_not_fire}; on #{p_x}, #{p_y} (p_angle: #{p_angle}, my_gun_angle: #{my_gun_angle})"
    should_not_fire
  end

  def angle_give_two_points x_1, y_1, x_2, y_2
    d_x = (x_2-x_1)
    d_y = (y_2-y_1)
    angle = Math.atan2(d_y, d_x).to_deg
    angle += 360 if angle < 0
    angle
  end

  def is_within_fifteen_degree_range? p_angle, my_gun_angle
    (p_angle - my_gun_angle).abs < 15
  end

  def heading_up_down?
    heading == 90 or heading == 270
  end

  def heading_left_right?
    heading == 0 or heading == 180
  end
end