#A Sighting provides information about a sighting on radar
class Sighting
  T = 0
  R = 1

  def initialize(start_angle, end_angle, distance, direction, origin, time)
    @start_angle = start_angle.normalize_angle
    @end_angle = end_angle.normalize_angle
    @distance = distance
    @direction = direction
    @origin = origin
    @time = time
  end

  def to_s
    "Sighting[start=#{@start_angle},end=#{@end_angle},distance=#{@distance},direction=#{@direction.round},origin=#{@origin},time=#{@time}]"
  end

  def central_angle
    arc = (360 + @start_angle - @end_angle).normalize_angle
    arc_remainder = 360 - arc
    [arc, arc_remainder].min
  end

  def arc_length
    @distance * central_angle.to_rad
  end

  def ==(other)
    (other != nil) &&
        (other.start_angle == start_angle) &&
        (other.end_angle == end_angle) &&
        (other.distance == distance) &&
        (other.direction == direction) &&
        (other.origin == origin) &&
        (other.time == time)
  end

  def bisector
    half_angle = central_angle / 2
    if (highest_angle - lowest_angle) > 180
      (lowest_angle - half_angle).normalize_angle
    else
      (lowest_angle + half_angle).normalize_angle
    end
  end

  def highest_angle
    [@start_angle, @end_angle].max
  end

  def lowest_angle
    [@start_angle, @end_angle].min
  end

  def broaden(amount)
    @start_angle = (@start_angle - @direction * amount).normalize_angle
  end

  def contains(position, margin=6)
    vector = origin.polar_vector_to(position)
    radius, angle = vector[R], vector[T]
    if (radius == distance)
      contains_angle(angle)
    elsif (radius < distance)
      central_angle < margin && contains_angle(angle)
    else
      false
    end
  end

  def contains_angle(angle)
    case direction
      when 1 then contains_angle_left(angle)
      when -1 then contains_angle_right(angle)
    end
  end

  def contains_angle_left(angle)
    start = start_angle
    start -= 360 if start_angle > end_angle
    start <= angle  && angle <= end_angle
  end

  def contains_angle_right(angle)
    start = start_angle
    start += 360 if start_angle < end_angle
    start >= angle && angle >= end_angle
  end

  def midpoint
    point_on_arc(bisector)
  end

  def start_point
    point_on_arc(start_angle)
  end

  def end_point
    point_on_arc(end_angle)
  end

  def point_on_arc(angle)
    @origin + Vector[angle, @distance].to_cartesian
  end

  attr_accessor(:start_angle)
  attr_accessor(:end_angle)
  attr_accessor(:distance)
  attr_accessor(:direction)
  attr_accessor(:origin)
  attr_accessor(:time)
end
