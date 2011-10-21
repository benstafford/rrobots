require 'robot'

class VerticalInvader
   include Robot

  def initialize
    @reached_west = false
    @intent_heading = 90

  end

  def tick events
    if @reached_west == false
      accelerate 1
      if heading != 180
        turn 10 - heading%10
      end
    end

    if x <= 100 and heading!=@intent_heading
      @reached_west = true
      stop
      turn 10 - heading%10
    end

    if gun_heading < 0
        turn_gun 30
    end
    if gun_heading > 0
        turn_gun -30
    end

    broadcast "VerticalInvader"
    if (events['broadcasts'].count > 0)
      if (y > 300)
        fire 0.1
      end
    else
      fire 0.1
    end




    if @reached_west and heading==@intent_heading
        accelerate 1
    end

    if @reached_west and heading==@intent_heading and heading == 90 and y <= 200
        @intent_heading = 270
    end
    if @reached_west and heading==@intent_heading and heading == 270 and y >= battlefield_height - 100
        @intent_heading = 90
    end
  end

end