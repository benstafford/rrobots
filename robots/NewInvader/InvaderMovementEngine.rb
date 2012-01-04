class InvaderMovementEngine
  include InvaderMath

  attr_accessor :accelerate
  attr_accessor :turn
  attr_accessor :last_hit

  def initialize invader
    @robot = invader
    @robot.current_direction = 1
    @turn = 0
    @accelerate = 0
    @head_to_edge = InvaderDriverHeadToEdge.new(invader, self)
    @patrol = InvaderDriverPatroller.new(invader, self)
    @evade = InvaderDriverEvader.new(invader, self)
    @last_hit = 0
  end

  def move
    @accelerate = 0
    @turn = 0
    @robot.at_edge = at_edge?
    @last_hit = @robot.time if @robot.got_hit?
    #if @last_hit > 0 and @robot.time - @last_hit < 36
    #  @evade.move
    #else
      if @robot.at_edge and !edge_conflict?
        @patrol.move
      else
        @head_to_edge.move
      end
    #end
  end

  def at_edge?
    return false if @robot.heading_of_edge.nil?
    @robot.my_distance_to_edge(@robot.heading_of_edge) <= (@robot.size + 1)
  end

  def edge_conflict?
    @head_to_edge.edge_conflict?
  end
end

class DrivingMode
  include InvaderMath

  HOVER_DISTANCE = 200

  def initialize invader, driver
    @robot = invader
    @driver = driver
  end

  def accelerate acceleration
    @driver.accelerate = acceleration
  end

  def turn turn_angle
    @driver.turn = turn_angle
  end

  private
  def right_of_edge
    rotated(@robot.heading_of_edge, -90)
  end

  def left_of_edge
    rotated(@robot.heading_of_edge, 90)
  end

  def at_edge?
    @driver.at_edge?
  end

  def target
    @robot.target
  end
end

class InvaderDriverHeadToEdge < DrivingMode
  def move
    select_closest_edge
    if at_edge?
      @robot.at_edge = true
    else
      accelerate 1
      turn_angle = turn_toward(@robot.heading, @robot.heading_of_edge)
      turn [[turn_angle, 10].min, -10].max
    end
  end

  def edge_conflict?
    return true if @robot.heading_of_edge.nil?
    return false if @robot.is_master
    return false if @robot.friend_edge.nil?
    return true if @robot.heading_of_edge == @robot.friend_edge
    return true if @robot.heading_of_edge == rotated(@robot.friend_edge, 180)
    return false
  end

  def select_closest_edge
    return if !edge_conflict?
    min_distance = @robot.battlefield_width
    closest_edge = 0
    for index in 0..3
      angle = index * 90
      edge_distance = distance_to_initial_edge(angle,@robot.my_distance_to_edge(angle))
      if edge_distance < min_distance
        closest_edge = angle
        min_distance = edge_distance
      end
    end
    @robot.heading_of_edge = closest_edge
  end

  def distance_to_initial_edge edge_heading, distance
    if not @robot.friend_edge.nil?
      return @robot.battlefield_width + 1 if @robot.friend_edge == edge_heading
      return @robot.battlefield_width + 1 if rotated(@robot.friend_edge, 180) == edge_heading
    end
    distance
  end

end

class InvaderDriverPatroller < DrivingMode
  def initialize invader, driver
    super invader, driver
  end

  def move
    turn_around if need_to_turn?
    if target.nil?
      patrol
    else
      head_toward_target
      not_too_close
    end
    accelerate @robot.current_direction
  end

  def need_to_turn?
    bearing = right_of_edge
    @robot.heading!=bearing
  end

  def turn_around
    @turn = turn_toward(@robot.heading, right_of_edge)
    turn [[@turn, 10].min, -10].max
  end

  def patrol
    if @robot.current_direction > 0 and @robot.my_distance_to_edge(right_of_edge) <= @robot.size + 1
      @robot.current_direction = -1
    end
    if @robot.current_direction < 0 and @robot.my_distance_to_edge(left_of_edge) <= @robot.size + 1
      @robot.current_direction = 1
    end
  end

  def head_toward_target
    target_location = target
    target_location = use_alternate_location_if_target_on_partner_edge target_location
    enemy_direction = degree_from_point_to_point(@robot.location_next_tick, target_location)
    turn_direction = turn_toward(@robot.opposite_edge, enemy_direction)
    if turn_direction > 0
      @robot.current_direction = 1
    else
      @robot.current_direction = -1
    end
  end


  def use_alternate_location_if_target_on_partner_edge target_location
    return target_location if @robot.friend_edge.nil?
    return target_location if distance_to_edge(@robot.friend_edge, target_location, @robot.battlefield_width, @robot.battlefield_height) > 120
    case @robot.heading_of_edge
        when 0
          return InvaderPoint.new(1540,800)
        when 90
          return InvaderPoint.new(800,60)
        when 180
          return InvaderPoint.new(60,800)
        when 270
          return InvaderPoint.new(800,1540)
      end
  end

  def not_too_close
    distance = distance_between_objects(@robot.location_next_tick, target)
    if distance < HOVER_DISTANCE
      @robot.current_direction = 0 - @robot.current_direction
    end
  end
end

class InvaderDriverEvader < DrivingMode
  def initialize invader, driver
    super invader, driver
    @turn_direction = -1
    @intended_edge = nil
    @start_evade = 0
  end

  def need_to_turn?
    @start_evade = @robot.time if @start_evade == 0
    @start_evade = @robot.time if @robot.time - @start_evade > 18 and @driver.last_hit == @robot.time
    @turn_direction = 0 - @turn_direction if @robot.time - @start_evade == 18
    @turn_direction = -1 if @robot.time - @start_evade == 35
    @robot.time - @start_evade < 18
  end

  def turn_around
    @turn = 10 * @turn_direction * @robot.current_direction
    turn [[@turn, 10].min, -10].max
  end

  def move
    @intended_edge = right_of_edge if @intended_edge.nil?
    turn_around if need_to_turn?
    accelerate @robot.current_direction
  end
end
