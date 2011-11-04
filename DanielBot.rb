require 'robot'

class DanielBot
   include Robot
  @found_bot = false

   def bot_was_found_on_radar(events)
     !events['robot_scanned'].empty?
   end

   def tick events
    #turn_radar 1 if time == 0
    #turn_gun 30 if time < 3
    #accelerate 1
    #turn 2
    #fire 3 unless events['robot_scanned'].empty?
    #broadcast "DanielBot"
    #say "#{events['broadcasts'].inspect}"

    #fire 1
    #accelerate 1



    #if bot_was_found_on_radar(events)
    #  @found_bot = true
    #  accelerate 8
    #elsif !@found_bot
    #  turn 2
    #else
    #  accelerate 8
    #  fire 3
    #end


    #if (gun_heading != 90)
    # turn_gun 1
    #end
    #
    #if (heading != 0)
    # turn 1
    #else
    #  accelerate 8
    #end
    #
    #if ((heading == 0) && (gun_heading == 90))
    #  fire 3
    #end



    #move_defensively
    #find_other_robot
    #fire
    #follow robot
    #keep firing






    accelerate 1

    if bot_was_found_on_radar(events)
      fire 3
      @found_bot = true
    elsif !@found_bot
      turn 2
    else
      fire 0.1
    end

  end
end