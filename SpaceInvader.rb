require 'robot'

class SpaceInvader
   include Robot

  def initialize
    @reached_north = false
    @intent_heading = 180

  end

  def tick events
    turn_radar 1 if time == 0

    if @reached_north == false
      accelerate 1
      if heading != 90
        turn 10 - heading%10
      end
    end

    if y <= 100 and heading!=@intent_heading
      @reached_north = true
      stop
      turn 10 - heading%10
    end

    if heading == 0
        if radar_heading < 300
            turn_radar 30
        end
        if radar_heading > 300
            turn_radar -30
        end
    else
        if radar_heading < 240
            turn_radar 30
        end
       if radar_heading > 240
            turn_radar -30
        end
    end
    if gun_heading < 270
        turn_gun 30
    end
    if gun_heading > 270
        turn_gun -30
    end

    broadcast "SpaceInvader"
    if (events['broadcasts'].count > 0)
      if (x > 300)
        #if (!events['robot_scanned'].empty?)
          fire 0.1
        #end
      end
    else
      fire 0.1
    end

    if @reached_north and heading==@intent_heading
        accelerate 1
    end

    if @reached_north and heading==@intent_heading and heading == 180 and x <= 100
        @intent_heading = 0
    end
    if @reached_north and heading==@intent_heading and heading == 0 and x >= battlefield_width - 100
        @intent_heading = 180
    end
  end

end