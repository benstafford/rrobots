require 'robot'
class SpinnerBot
  include Robot
  attr_accessor :target

  def tick events
    driver_turn_toward_target Point.new(@target[0], @target[1])
  end

  def my_location
    Point.new(x,y)
  end

  def driver_turn_toward_target target
    desired_heading = degree_from_point_to_point(my_location, target)
    desired_turn = turn_toward heading, desired_heading
    desired_turn = [[desired_turn,-10].max,10].min
    turn desired_turn
  end

  def turn_toward current_heading, desired_heading
    difference_between = desired_heading - current_heading
    if difference_between > 0
      if difference_between < 180
        desired_turn = difference_between
      else #difference_between > 180
        desired_turn = -1 * (360 - difference_between.abs)
      end
    else #difference_between < 0
      if difference_between > -180
        desired_turn = difference_between
      else #difference_between < -180
        desired_turn = (360 - difference_between.abs)
      end
    end
    desired_turn
  end

  def degree_from_point_to_point point1, point2
    if (point1.y - point2.y) == 0 and (point2.x - point1.x) == 0
      return -1
    end
    return Math.atan2(point1.y - point2.y, point2.x - point1.x) / Math::PI * 180 % 360
  end

  class Point
    attr_accessor :x
    attr_accessor :y
    def initialize x,y
      @x = x
      @y = y
    end
  end

end