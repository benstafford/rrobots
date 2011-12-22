class InvaderMovementEngine
  include InvaderMath

  attr_accessor :accelerate
  attr_accessor :turn

  DISTANCE_PAST_SCAN = 5
  PURSUE_FRIEND_TARGET_TIME = 20
  HOVER_DISTANCE = 200

  def initialize invader
    @robot = invader
    @robot.current_direction = 1
    @turn = 0
    @accelerate = 0
  end

  def move
    @accelerate = 0
    @turn = 0
  end

  private
  def distance_to_initial_edge edge_heading, distance
    if not @robot.friend_edge.nil?
      return @robot.battlefield_width + 1 if @robot.friend_edge == edge_heading
      return @robot.battlefield_width + 1 if rotated(@robot.friend_edge, 180) == edge_heading
    end
    distance
  end

  def need_to_turn?
    bearing = right_of_edge
    @robot.heading!=bearing
  end

  def turn_around
    @turn = turn_toward(@robot.heading, right_of_edge)
    @turn = [[@turn, 10].min, -10].max
  end

  def left_of_edge
    return rotated(@robot.heading_of_edge, 90)
  end

  def right_of_edge
    return rotated(@robot.heading_of_edge, -90)
  end

end

class InvaderDriverHeadToEdge < InvaderMovementEngine

  def move
    @accelerate = 0
    @turn = 0
    head_to_edge
  end

  def head_to_edge
    @accelerate = 0
    @turn = 0
    select_closest_edge
    if at_edge?
      @robot.change_mode InvaderMode::SEARCHING
    else
      @accelerate = 1
      @turn = turn_toward(@robot.heading, @robot.heading_of_edge)
      @turn = [[@turn, 10].min, -10].max
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

  def at_edge?
    @robot.distance_to_edge(@robot.heading_of_edge) <= (@robot.size + 1)
  end
end

class InvaderDriverPursueTarget < InvaderMovementEngine

  def initialize invader
    super invader
    @target_enemy = nil
  end

  def move
    @accelerate = 0
    @turn = 0
    pursue_found_target
  end

  def pursue_found_target
    turn_around if need_to_turn?
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
    @accelerate = @robot.current_direction
  end
end

class InvaderDriverSearching < InvaderMovementEngine
  def move
    @accelerate = 0
    @turn = 0
    turn_around if need_to_turn?
    if @robot.current_direction > 0 and @robot.distance_to_edge(right_of_edge) <= @robot.size + 1
      @robot.current_direction = -1
    end
    if @robot.current_direction < 0 and @robot.distance_to_edge(left_of_edge) <= @robot.size + 1
      @robot.current_direction = 1
    end
    @accelerate = @robot.current_direction
  end
end

class InvaderDriverProvidedTarget < InvaderDriverSearching
  def initialize invader
    @pursuit_time = nil
    @target_enemy = nil
    super invader
  end

  def move
    @accelerate = 0
    @turn = 0
    #provided_target_mode
    if not @robot.broadcast_enemy.nil?
      @target_enemy = @robot.broadcast_enemy
      @pursuit_time = @robot.time + PURSUE_FRIEND_TARGET_TIME
    end
    super
    if @robot.time > @pursuit_time
      @robot.change_mode InvaderMode::SEARCHING
    end
  end

  def provided_target_mode
    turn_around if need_to_turn?
    if not @robot.broadcast_enemy.nil?
      @target_enemy = @robot.broadcast_enemy
      direction = turn_toward(@robot.opposite_edge, degree_from_point_to_point(@robot.location_next_tick, @robot.broadcast_enemy))
      if direction > 0
        @robot.say "Coming, Buddy!"
        @robot.current_direction = 1
      else
        @robot.say "I'll Get Him!'"
        @robot.current_direction = -1
      end
      @pursuit_time = @robot.time + PURSUE_FRIEND_TARGET_TIME
    end
    if @robot.time > @pursuit_time
      @robot.change_mode InvaderMode::SEARCHING
    end
    @accelerate = @robot.current_direction
  end

end
