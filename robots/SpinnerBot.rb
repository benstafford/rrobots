require 'robot'
class SpinnerBot
  include Robot
  attr_accessor :target
  attr_reader :partner_location

  MAINTAIN_DISTANCE = 100..150

  def initialize
    @target = Point.new(800,800)
  end

  def tick events
    process_broadcast events['broadcasts'] unless events.nil?

    drive

    location_next_turn = my_location_next_turn
    message = "#{location_next_turn.x},#{location_next_turn.y},#{my_heading_next_turn},#{my_speed_next_turn}"
    broadcast message
  end

  def process_broadcast broadcast_event
    if broadcast_event.count > 0
      message = broadcast_event[0][0]
      message_parcels = message.split(",")
      @partner_location = Point.new(message_parcels[0].to_f, message_parcels[1].to_f)
    end
  end

  def my_location
    Point.new(x,y)
  end

  def my_location_next_turn
    new_x = x + Math.cos(my_heading_next_turn.to_rad) * my_speed_next_turn
    new_y = y - Math.sin(my_heading_next_turn.to_rad) * my_speed_next_turn
    Point.new(new_x, new_y)
  end

  def my_speed_next_turn
    speed < 8 ? speed + 1 : speed
  end

  def my_heading_next_turn
    heading + @desired_turn
  end

  def drive
    @desired_turn = 0
    accelerate 1 if speed < 8
    distance_to_target = distance_between_objects(my_location, target)
    case
      when distance_to_target > MAINTAIN_DISTANCE.max then driver_turn_toward_target
      when distance_to_target < MAINTAIN_DISTANCE.min then driver_turn_away_from_target
      else circle_target
    end
  end

  def driver_turn_toward_target
    turn_toward_heading degree_from_point_to_point(my_location, target)
  end

  def driver_turn_away_from_target
    turn_toward_heading rotate(degree_from_point_to_point(my_location, target),180)
  end

  def circle_target
    turn_toward_heading rotate(degree_from_point_to_point(my_location, target),90)
  end

  def turn_toward_heading desired_heading
    desired_turn = turn_toward heading, desired_heading
    @desired_turn = [[desired_turn,-10].max,10].min
    turn @desired_turn if @desired_turn != 0
  end

  SHORTEST_POSSIBLE_TURNS = -180..180
  WHOLE_TURN = 360

  def turn_toward current_heading, desired_heading
    proposed_turn = desired_heading - current_heading
    case
      when SHORTEST_POSSIBLE_TURNS.include?(proposed_turn) then proposed_turn
      when proposed_turn < SHORTEST_POSSIBLE_TURNS.min     then proposed_turn + WHOLE_TURN
      when proposed_turn > SHORTEST_POSSIBLE_TURNS.max     then proposed_turn - WHOLE_TURN
    end
  end

  def distance_between_objects object1, object2
    Math.hypot(object1.y - object2.y, object2.x - object1.x)
  end

  def degree_from_point_to_point point1, point2
    if (point1.y - point2.y) == 0 and (point2.x - point1.x) == 0
      return -1
    end
    return Math.atan2(point1.y - point2.y, point2.x - point1.x) / Math::PI * 180 % 360
  end

  def rotate direction, degrees
    direction += degrees
    direction +=360 if direction < 0
    direction -= 360 if direction >= 360
    direction
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