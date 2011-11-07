require 'robot'

class ChuckBot
  include Robot
  attr_accessor :degrees
  attr_accessor :target_found
  attr_accessor :last_hit

  def initialize
    @degrees = 0
    @last_hit = 0
  end
=begin
  attr_accessor :pair_x_position
  attr_accessor :pair_y_position

  attr_accessor :target_x_position
  attr_accessor :target_y_position

  def initialize
    target_found = false;
    pair_x_position = 0;
    pair_y_position = 0;
    target_x_position = 0;
    target_y_position = 0;
  end

  def move_towards(target)

  end

  def check_broadcast (events)
     if events.has_tag? ('broadcast')
     end
   end
=end
=begin
  def check_got_hit (events)
    if events.has_tag? 'got_hit'
      say "It's just a flesh wound!!"
    end
  end
=end
=begin
  def check_radar(events)
    if events.has_tag? ('robot_scanned')
      say "Target Acquired!"
      engage_target()
    end
  end

  def engage_target()
    #calculate target position

#    broadcast("_pp:#{@x}|#{@y}|_tp")  #Send target to other bot
    say("Engaging Target!")
    move_towards(@target_found)
    fire_towards(@target_found)
  end
=end
  def process_scan(events)
    @target_found = events["robot_scanned"]
    if !@target_found.empty?
      @target_found = true
      say "Target Acquired!!"
      fire(2)
      @degrees = 0
      accelerate(1)
      @last_hit = 0
    else
      @last_hit += 1
      if @last_hit <= 10
        accelerate(1)
      else
        stop
      end

      if @degrees <= 10
        @degrees += 1
      end
    end
  end

  def process_hit(events)
    if !events["got_hit"].empty?
      say "It's only a flesh wound!!"
    end
  end

  def tick events
    process_hit(events)
    process_scan(events)
    turn(@degrees)
  end
end


#'got_hit'    say("It's just a flesh wound!")
#'robot_scanned'
#'broadcasts'


#API Calls
#
#battlefield_height  #the height of the battlefield
#battlefield_width   #the width of the battlefield
#energy              #your remaining energy (if this drops below 0 you are dead)
#gun_heading         #the heading of your gun, 0 pointing east, 90 pointing
#                    #north, 180 pointing west, 270 pointing south
#gun_heat            #your gun heat, if this is above 0 you can't shoot
#heading             #your robots heading, 0 pointing east, 90 pointing north,
#                    #180 pointing west, 270 pointing south
#size                #your robots radius, if x <= size you hit the left wall
#radar_heading       #the heading of your radar, 0 pointing east,
#                    #90 pointing north, 180 pointing west, 270 pointing south
#time                #ticks since match start
#speed               #your speed (-8/8)
#x                   #your x coordinate, 0...battlefield_width
#y                   #your y coordinate, 0...battlefield_height
#accelerate(param)   #accelerate (max speed is 8, max accelerate is 1/-1,
#                    #negativ speed means moving backwards)
#stop                #accelerates negative if moving forward (and vice versa),
#                    #may take 8 ticks to stop (and you have to call it every tick)
#fire(power)         #fires a bullet in the direction of your gun,
#                    #power is 0.1 - 3, this power will heat your gun
#turn(degrees)       #turns the robot (and the gun and the radar),
#                    #max 10 degrees per tick
#turn_gun(degrees)   #turns the gun (and the radar), max 30 degrees per tick
#turn_radar(degrees) #turns the radar, max 60 degrees per tick
#dead                #true if you are dead
#say(msg)            #shows msg above the robot on screen
#broadcast(msg)      #broadcasts msg to all bots (they receive 'broadcasts'
#                    #events with the msg and rough direction)
