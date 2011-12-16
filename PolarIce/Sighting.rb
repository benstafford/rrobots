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
    "Sighting[start=#{@start_angle},end=#{@end_angle},distance=#{@distance},direction=#{@direction.trim(2)},origin=#{@origin},time=#{@time},central=#{central_angle.trim(2)},arc_length=#{arc_length.trim(2)},bisector=#{bisector}]"
  end

  def central_angle
    arc1 = (360 + @start_angle - @end_angle).normalize_angle
    arc2 = 360 - arc1
    [arc1, arc2].min
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
    if (highest_angle - lowest_angle) > 180
      (lowest_angle - central_angle / 2).normalize_angle
    else
      (lowest_angle + central_angle / 2).normalize_angle
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

  def contains(position)
    log "contains #{self} #{position}\n"
    vector = origin.polar_vector_to(position)
    if (vector[R] == distance)
      contains_angle(vector[T])
    elsif (vector[R] < distance)
      central_angle < 6 && contains_angle(vector[T])
    else
      false
    end
  end

  def contains_angle(angle)
    log "contains_angle #{angle}\n"
    case direction
      when 1 then contains_angle_left(angle)
      when -1 then contains_angle_right(angle)
    end
  end

  def contains_angle_left(angle)
    log "contains_angle_left #{angle}\n"
    start = start_angle
    start -= 360 if start_angle > end_angle
    start <= angle  && angle <= end_angle
  end

  def contains_angle_right(angle)
    log "contains_angle_right #{angle}\n"
    start = start_angle
    start += 360 if start_angle < end_angle
    start >= angle && angle >= end_angle
  end

  attr_accessor(:start_angle)
  attr_accessor(:end_angle)
  attr_accessor(:distance)
  attr_accessor(:direction)
  attr_accessor(:origin)
  attr_accessor(:time)
end
