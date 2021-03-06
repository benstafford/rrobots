class InvaderPoint
  attr_accessor :x,:y
  def initialize(x,y)
    @x,@y = x,y
  end
end

module InvaderMath

    CLOCKWISE = -1
    COUNTERCLOCKWISE = 1

    def distance_to_edge edge, location, battlefield_width, battlefield_height
      case edge.to_i
        when 0
          return battlefield_width - location.x
        when 90
          return location.y
        when 180
          return location.x
        when 270
          return battlefield_height - location.y
      end
    end

    def turn_toward current_heading, desired_heading
      difference_between = desired_heading - current_heading
      if difference_between > 0
        if difference_between < 180
          desired_turn = difference_between
        else #difference_between > 180
          desired_turn = CLOCKWISE * (360 - difference_between.abs)
        end
      else #difference_between < 0
        if difference_between > -180
          desired_turn = difference_between
        else #difference_between < -180
          desired_turn = COUNTERCLOCKWISE * (360 - difference_between.abs)
        end
      end
      desired_turn
    end

  def rotated direction, degrees
    direction += degrees
    if direction < 0
      direction +=360
    end
    if direction >= 360
      direction -= 360
    end
    direction
  end

  def degree_from_point_to_point point1, point2
    if (point1.y - point2.y) == 0 and (point2.x - point1.x) == 0
      return -1
    end
    return Math.atan2(point1.y - point2.y, point2.x - point1.x) / Math::PI * 180 % 360
  end

  def distance_between_objects object1, object2
    Math.hypot(object1.y - object2.y, object2.x - object1.x)
  end

  def get_radar_point angle, distance, base_location
    a = (Math.sin(angle * Math::PI/180) * distance.to_f)
    b = (Math.cos(angle * Math::PI/180) * distance.to_f)
    InvaderPoint.new(base_location.x + b, base_location.y - a)
  end

  def radar_heading_between? heading, left_edge, right_edge
    if right_edge > left_edge
      return !radar_heading_between?(heading, right_edge, left_edge)
    end
    if left_edge > heading and heading > right_edge
      return true
    end
    return false
  end
end