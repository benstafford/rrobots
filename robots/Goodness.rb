require 'robot'

class Goodness
  include Robot

  attr_reader :id
  attr_reader :partner
  @@team = nil

  def initialize(id = rand(100))
    @id = id
    me_hash = {@id => self}
    if @@team.nil?
      @@team = me_hash
    else
      @@team.merge! me_hash
    end
  end

  def tick events
    turn_radar 1 if time == 0
    turn_gun 30 if time < 3
    accelerate 1
    turn 2
    fire 3 unless events['robot_scanned'].empty?
  end

  def get_partner
    @@team.each do |id, p|
      if p != self
        @partner = p
      end
    end
  end

  def reset_team
    @@team = nil
  end

  def change_id id
    @id = id
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