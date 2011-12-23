class InvaderMovementEngine
  include InvaderMath

  attr_accessor :accelerate
  attr_accessor :turn

  def initialize invader
    @robot = invader
    @robot.current_direction = 1
    @turn = 0
    @accelerate = 0
    @modes = []
    @modes[InvaderMode::HEAD_TO_EDGE] = InvaderDriverHeadToEdge.new(invader, self)
    @modes[InvaderMode::PROVIDED_TARGET] = InvaderDriverProvidedTarget.new(invader, self)
    @modes[InvaderMode::FOUND_TARGET] = InvaderDriverPursueTarget.new(invader, self)
    @modes[InvaderMode::SEARCHING] = InvaderDriverSearching.new(invader, self)
  end

  def move
    @accelerate = 0
    @turn = 0
    mode = @robot.mode
    if !at_edge?
      mode = InvaderMode::HEAD_TO_EDGE
    else
      turn_around if need_to_turn?
    end

    @modes[mode].move
  end

  def at_edge?
    return false unless !@robot.heading_of_edge.nil?
    @robot.distance_to_edge(@robot.heading_of_edge) <= (@robot.size + 1)
  end

  private

  def need_to_turn?
    bearing = right_of_edge
    @robot.heading!=bearing
  end

  def turn_around
    @turn = turn_toward(@robot.heading, right_of_edge)
    @turn = [[@turn, 10].min, -10].max
  end

  def right_of_edge
    rotated(@robot.heading_of_edge, -90)
  end

end

class DrivingMode
  include InvaderMath

  DISTANCE_PAST_SCAN = 5
  PURSUE_FRIEND_TARGET_TIME = 20
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
end

class InvaderDriverHeadToEdge < DrivingMode
  def move
    select_closest_edge
    if at_edge?
      @robot.change_mode InvaderMode::SEARCHING
    else
      accelerate 1
      turn_angle = turn_toward(@robot.heading, @robot.heading_of_edge)
      turn [[turn_angle, 10].min, -10].max
    end
  end

  def select_closest_edge
    if !@robot.heading_of_edge.nil? and !@robot.friend_edge.nil?
      if @robot.heading_of_edge != @robot.friend_edge and @robot.heading_of_edge!= rotated(@robot.friend_edge, 180)
        return
      end
      if @robot.heading_of_edge < @robot.friend_edge
        return
      end
      if !@robot.friend.nil?
        if @robot.x < @robot.friend.x
          return
        end
      end
    end

    min_distance = @robot.battlefield_width
    closest_edge = 0
    for index in 0..3
      angle = index * 90
      edge_distance = distance_to_initial_edge(angle,@robot.distance_to_edge(angle))
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

class InvaderDriverPursueTarget < DrivingMode
  def initialize invader, driver
    super invader, driver
    @target_enemy = nil
  end

  def move
    @target_enemy = @robot.found_enemy unless @robot.found_enemy.nil?
    enemy_direction = degree_from_point_to_point(@robot.location_next_tick, @target_enemy)
    turn_direction = turn_toward(@robot.opposite_edge, enemy_direction)
    if turn_direction > 0
      @robot.current_direction = 1
    else
      @robot.current_direction = -1
    end

    distance = distance_between_objects(@robot.location_next_tick, @target_enemy)
    if distance < HOVER_DISTANCE
      @robot.current_direction = 0 - @robot.current_direction
    end

    @robot.change_mode InvaderMode::SEARCHING
    accelerate @robot.current_direction
  end
end

class InvaderDriverSearching < DrivingMode
  def move
    if @robot.current_direction > 0 and @robot.distance_to_edge(right_of_edge) <= @robot.size + 1
      @robot.current_direction = -1
    end
    if @robot.current_direction < 0 and @robot.distance_to_edge(left_of_edge) <= @robot.size + 1
      @robot.current_direction = 1
    end
    accelerate @robot.current_direction
  end
end

class InvaderDriverProvidedTarget < InvaderDriverSearching
  def initialize invader, driver
    @pursuit_time = nil
    super invader, driver
  end

  def move
    if not @robot.broadcast_enemy.nil?
      @pursuit_time = @robot.time + PURSUE_FRIEND_TARGET_TIME
    end
    super
    if @robot.time > @pursuit_time
      @robot.change_mode InvaderMode::SEARCHING
    end
  end
end
