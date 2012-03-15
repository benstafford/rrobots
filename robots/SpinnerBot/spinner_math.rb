class SpinnerMath
  SHORTEST_POSSIBLE_TURNS = -180..180
  WHOLE_TURN = 360

  def self.distance_between_objects object1, object2
    Math.hypot(object1.y - object2.y, object2.x - object1.x)
  end

  def self.turn_toward current_heading, desired_heading
    proposed_turn = desired_heading - current_heading
    case
      when SHORTEST_POSSIBLE_TURNS.include?(proposed_turn) then proposed_turn
      when proposed_turn < SHORTEST_POSSIBLE_TURNS.min     then proposed_turn + WHOLE_TURN
      when proposed_turn > SHORTEST_POSSIBLE_TURNS.max     then proposed_turn - WHOLE_TURN
    end
  end

  def self.rotate direction, degrees
    direction += degrees
    direction +=360 if direction < 0
    direction -= 360 if direction >= 360
    direction
  end

  def self.degree_from_point_to_point point1, point2
    begin
      if (point1.y - point2.y) == 0 and (point2.x - point1.x) == 0
        return -1
      end
      Math.atan2(point1.y - point2.y, point2.x - point1.x) / Math::PI * 180 % 360
    rescue
      return -1
    end
  end

  def self.distance_from_point_to_line point_off_the_line, point1_on_line, point2_on_line
    direction_of_line = degree_from_point_to_point(point1_on_line, point2_on_line)
    direction_from_point1_to_point_off_line = degree_from_point_to_point(point1_on_line, point_off_the_line)
    theta = turn_toward(direction_of_line, direction_from_point1_to_point_off_line)
    distance_from_point1_to_point_off_line = distance_between_objects(point1_on_line, point_off_the_line)
    return (Math.sin(theta.to_rad) * distance_from_point1_to_point_off_line).abs
  end
end