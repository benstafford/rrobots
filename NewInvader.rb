require 'robot'

class NewInvader
   include Robot

  attr_accessor :mode
  attr_accessor :heading_of_edge
  attr_accessor :move_engine
  attr_accessor :fire_engine
  attr_accessor :radar_engine
  attr_accessor :math
  attr_accessor :friend
  attr_accessor :friend_edge
  attr_accessor :broadcast_enemy
  attr_accessor :found_enemy
  attr_accessor :last_target_time
  attr_accessor :current_direction

  def initialize
    @mode = InvaderMode::HEAD_TO_EDGE
    @move_engine = []
    @move_engine[InvaderMode::HEAD_TO_EDGE] = InvaderDriverHeadToEdge.new(self)
    @move_engine[InvaderMode::PROVIDED_TARGET] = InvaderDriverProvidedTarget.new(self)
    @move_engine[InvaderMode::FOUND_TARGET] = InvaderDriverPursueTarget.new(self)
    @move_engine[InvaderMode::SEARCHING] = InvaderDriverSearching.new(self)
    @move_engine[InvaderMode::SEARCH_OPPOSITE_CORNER] = InvaderDriverSearchCorner.new(self)
    @fire_engine = []
    @fire_engine[InvaderMode::HEAD_TO_EDGE] = InvaderGunnerHeadToEdge.new(self)
    @fire_engine[InvaderMode::PROVIDED_TARGET] = InvaderGunnerProvidedTarget.new(self)
    @fire_engine[InvaderMode::FOUND_TARGET] = InvaderGunnerFoundTarget.new(self)
    @fire_engine[InvaderMode::SEARCHING] = InvaderGunnerSearching.new(self)
    @fire_engine[InvaderMode::SEARCH_OPPOSITE_CORNER] = InvaderGunnerShootOppositeCorner.new(self)
    @radar_engine = []
    @radar_engine[InvaderMode::HEAD_TO_EDGE] = InvaderRadarEngineHeadToEdge.new(self)
    @radar_engine[InvaderMode::PROVIDED_TARGET] = InvaderRadarEngineProvidedTarget.new(self)
    @radar_engine[InvaderMode::FOUND_TARGET] = InvaderRadarEngine.new(self)
    @radar_engine[InvaderMode::SEARCHING] =  InvaderRadarEngineSearching.new(self) #@radar_engine[InvaderMode::FOUND_TARGET]
    @radar_engine[InvaderMode::SEARCH_OPPOSITE_CORNER] = InvaderRadarEngineSearchOppositeCorner.new(self)
    @math = InvaderMath.new
  end

  def tick events
    react_to_events
    move
    fire_gun
    radar_sweep
    send_broadcast
  end

  def change_mode desired_mode
    @mode = desired_mode
    radar_engine.ready_for_metronome = false
  end

  def opposite_edge
    @math.rotated heading_of_edge, 180
  end

  def location
    InvaderPoint.new(x,y)
  end

  def location_next_tick
    new_x = x + Math::cos(heading.to_rad) * speed
    new_y = y - Math::sin(heading.to_rad) * speed
    InvaderPoint.new(new_x, new_y)
  end

  def distance_to_edge edge
    case edge.to_i
      when 0
        return battlefield_width - x
      when 90
        return y
      when 180
        return x
      when 270
        return battlefield_height - y
    end
  end

  private
  def fire_engine
    @fire_engine[@mode]
  end

  def radar_engine
    @radar_engine[@mode]
  end

  def move_engine
    @move_engine[@mode]
  end

  def send_broadcast
    message = x.to_i.to_s(16).rjust(3,' ')
    message += y.to_i.to_s(16).rjust(3,' ')
    message += @heading_of_edge.to_i.to_s.rjust(3,' ')
    if !@found_enemy.nil?
      message += @found_enemy.x.to_i.to_s(16).rjust(3,' ')
      message += @found_enemy.y.to_i.to_s(16).rjust(3,' ')
    end
    broadcast message
  end

  def react_to_events
    record_friend
    record_friend_edge
    record_broadcast_enemy
    record_radar_detected
  end

  def move
    move_engine.move
    accelerate move_engine.accelerate
    if move_engine.turn != 0
      turn move_engine.turn
    end
  end

  def fire_gun
    fire_engine.fire
    turn_gun (0 - move_engine.turn) + fire_engine.turn_gun
    fire fire_engine.firepower unless fire_engine.firepower == 0
  end

  def radar_sweep
    radar_engine.radar_sweep
    turn_radar (0 - move_engine.turn) + (0 - fire_engine.turn_gun) + radar_engine.turn_radar
  end

  def get_broadcast
    broadcasts = events['broadcasts']
    if (broadcasts.count > 0)
      return broadcasts[0][0]
    end
    nil
  end

  def record_friend
    @friend = nil
    message = get_broadcast()
    if !message.nil?
      @friend = InvaderPoint.new(message[0..2].to_i(16), message[3..5].to_i(16))
    end
  end

  def record_friend_edge
    @friend_edge = nil
    message = get_broadcast()
    if !message.nil?
      @friend_edge = message[6..8].to_i
    end
  end

  def record_broadcast_enemy
    message = get_broadcast()
    @broadcast_enemy = nil
    if !message.nil? and message.length > 9
      enemy = InvaderPoint.new(message[9..11].to_i(16), message[12..14].to_i(16))
      @broadcast_enemy = enemy
      if @mode == InvaderMode::SEARCHING and not @broadcast_enemy.nil?
        change_mode InvaderMode::PROVIDED_TARGET
        @last_target_time = time
      end
    end
  end

  def record_radar_detected
    @found_enemy = radar_engine.scan_radar(events['robot_scanned'])
    if not @found_enemy.nil? and @mode == InvaderMode::SEARCHING
      say "Found!"
      change_mode InvaderMode::FOUND_TARGET
    end
    if not @found_enemy.nil? and @mode == InvaderMode::SEARCH_OPPOSITE_CORNER
      say "Sneaking up on me, eh?!"
    end
  end
end

class InvaderMovementEngine
  attr_accessor :accelerate
  attr_accessor :turn
  attr_accessor :robot
  attr_accessor :math

  DISTANCE_PAST_SCAN = 5
  PURSUE_FRIEND_TARGET_TIME = 20
  HOVER_DISTANCE = 200

  def initialize invader
    @robot = invader
    @robot.current_direction = 1
    @math = InvaderMath.new
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
      return @robot.battlefield_width + 1 if @math.rotated(@robot.friend_edge, 180) == edge_heading
    end
    distance
  end

  def need_to_turn?
    bearing = right_of_edge
    @robot.heading!=bearing
  end

  def turn_around
    @turn = @math.turn_toward(@robot.heading, right_of_edge)
    @turn = [[@turn, 10].min, -10].max
  end

  def left_of_edge
    return @math.rotated(@robot.heading_of_edge, 90)
  end

  def right_of_edge
    return @math.rotated(@robot.heading_of_edge, -90)
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
      @turn = @robot.math.turn_toward(@robot.heading, @robot.heading_of_edge)
      @turn = [[@turn, 10].min, -10].max
    end
  end

  def select_closest_edge
    if !@robot.heading_of_edge.nil? and !@robot.friend_edge.nil?
      if @robot.heading_of_edge != @robot.friend_edge and @robot.heading_of_edge!= @robot.math.rotated(@robot.friend_edge, 180)
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
  attr_accessor :target_enemy

  def move
    @accelerate = 0
    @turn = 0
    pursue_found_target
  end

  def pursue_found_target
    turn_around if need_to_turn?
    @target_enemy = @robot.found_enemy unless @robot.found_enemy.nil?
    enemy_direction = @math.degree_from_point_to_point(@robot.location_next_tick, @target_enemy)
    turn_direction = @math.turn_toward(@robot.opposite_edge, enemy_direction)
    if turn_direction > 0
      @robot.current_direction = 1
    else
      @robot.current_direction = -1
    end

    distance = @math.distance_between_objects(@robot.location_next_tick, @target_enemy)
    if distance < HOVER_DISTANCE
      @robot.current_direction = 0 - @robot.current_direction
    end

    @robot.change_mode InvaderMode::SEARCHING
    @accelerate = @robot.current_direction
  end
end

class InvaderDriverSearchCorner < InvaderMovementEngine
  def move
    @accelerate = 0
    @turn = 0
    @accelerate = 0 - @robot.speed
  end
end

class InvaderDriverSearching < InvaderMovementEngine
  def move
    @accelerate = 0
    @turn = 0
    turn_around if need_to_turn?
    if @robot.current_direction > 0 and @robot.distance_to_edge(right_of_edge) <= @robot.size + 1
      @robot.current_direction = -1
      @robot.change_mode InvaderMode::SEARCH_OPPOSITE_CORNER
    end
    if @robot.current_direction < 0 and @robot.distance_to_edge(left_of_edge) <= @robot.size + 1
      @robot.current_direction = 1
      @robot.change_mode InvaderMode::SEARCH_OPPOSITE_CORNER
    end
    @accelerate = @robot.current_direction
  end
end

class InvaderDriverProvidedTarget < InvaderDriverSearching
  attr_accessor :pursuit_time
  attr_accessor :target_enemy

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
      direction = @robot.math.turn_toward(@robot.opposite_edge, @robot.math.degree_from_point_to_point(@robot.location_next_tick, @robot.broadcast_enemy))
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

class InvaderFiringEngine
  attr_accessor :turn_gun
  attr_accessor :firepower
  attr_accessor :robot
  attr_accessor :target_enemy
  attr_accessor :math

  def initialize invader
    @robot = invader
    @math = InvaderMath.new
    @turn_gun = 0
    @firepower = 0
  end

  def fire
    @turn_gun = 0
    @firepower = 0
    aim
    shoot
    dont_fire_at_friend
  end

  private

  def power_based_on_distance
    this = InvaderPoint.new(@robot.x, @robot.y)
    distance = @math.distance_between_objects(this, @target_enemy)
    firepower = 3.0 - (distance/780)
    return firepower
  end

  def dont_fire_at_friend
    return if @robot.friend.nil?
    friend_direction = @math.degree_from_point_to_point @robot.location, @robot.friend
    @firepower = 0 if @math.radar_heading_between?(friend_direction, @math.rotated(@robot.gun_heading,3), @math.rotated(@robot.gun_heading, -3))
    return if @robot.friend_edge.nil?
    @firepower = 0 if @robot.gun_heading == @robot.opposite_edge and @robot.distance_to_edge(@robot.friend_edge.to_i) < (2 * @robot.size + 1)
  end

  def point_gun direction
    if (@robot.gun_heading != direction)
      @turn_gun = @math.turn_toward(@robot.gun_heading, direction)
      @turn_gun = [[@turn_gun, 30].min,-30].max
    end
  end
end

class InvaderGunnerHeadToEdge <  InvaderFiringEngine
  def aim
    @turn_gun = 10
  end

  def shoot
    @firepower = 3 unless @robot.events['robot_scanned'].empty?
  end
end

class InvaderGunnerProvidedTarget < InvaderFiringEngine
  def aim
    @target_enemy = @robot.broadcast_enemy unless @robot.broadcast_enemy.nil?
    point_gun @math.degree_from_point_to_point(@robot.location_next_tick, @target_enemy) + Math.sin(@robot.time)
  end

  def shoot
    @firepower = power_based_on_distance
  end
end

class InvaderGunnerFoundTarget < InvaderFiringEngine
  def aim
    @target_enemy = @robot.found_enemy unless @robot.found_enemy.nil?
    point_gun @math.degree_from_point_to_point(@robot.location_next_tick, @target_enemy) + Math.sin(@robot.time)
  end

  def shoot
    @firepower = power_based_on_distance
  end
end

class InvaderGunnerSearching < InvaderFiringEngine
  def aim
    point_gun @robot.opposite_edge + Math.sin(@robot.time)
  end

  def shoot
    @firepower = 0.1
  end
end

class InvaderGunnerShootOppositeCorner < InvaderFiringEngine
  def aim
    point_gun desired_gun_heading # + Math.sin(@robot.time)
  end

  def desired_gun_heading
    @math.rotated(@robot.heading_of_edge, @robot.current_direction * -90)
  end

  def shoot
    if @robot.gun_heading == desired_gun_heading
      @firepower = 3.0
    end
  end
end

class InvaderMode
  HEAD_TO_EDGE = 1
  PROVIDED_TARGET = 2
  FOUND_TARGET = 3
  SEARCHING = 4
  SEARCH_OPPOSITE_CORNER = 5
end

class InvaderRadarEngine
  attr_accessor :turn_radar
  attr_accessor :robot
  attr_accessor :ready_for_metronome
  attr_accessor :metronome_side
  attr_accessor :math

  RADAR_LEAD = 5

  def initialize invader
    @robot = invader
    @ready_for_metronome = true
    @math = InvaderMath.new
    @turn_radar = 0
  end

  def radar_sweep
    @turn_radar = 0
    point_radar
    @turn_radar = [[@turn_radar, 60].min,-60].max
  end

  def scan_radar robots_scanned
    return nil if @ready_for_metronome == false
    if robots_scanned.count > 0
      scan_list = []
      robots_scanned.each do |element|
        scan_list << element.first
      end
      scan_list.sort!
      scan_list.each do |scan|
        enemy = locate_enemy(scan)
        if !enemy.nil? and enemy?(enemy, @robot.friend)
          return enemy
        end
      end
    end
    nil
  end

  private

  def point_radar
    desired_direction = @robot.opposite_edge
    if (@robot.radar_heading == desired_direction)
      @ready_for_metronome = true
      desired_direction = lead_search_movement(@robot.radar_heading, @robot.current_direction)
    end
    @turn_radar = @robot.math.turn_toward(@robot.radar_heading, desired_direction)
  end

  def locate_enemy scan
    get_scan_loc(scan, @robot.current_direction, @robot.opposite_edge, @robot.location)
  end

  def lead_search_movement(current_heading, direction)
    current_heading + (direction * RADAR_LEAD)
  end

  def get_corner_scan_location radar_heading, distance, location
    return @math.get_radar_point(radar_heading, distance, location)
  end

 def get_scan_loc distance, direction, edge, location
   direction = @robot.current_direction
   return @math.get_radar_point(edge + 5*direction, distance, location)
 end

  SAFE_DISTANCE = 125

  def enemy? object, friend
    return true if friend.nil?
    distance = @math.distance_between_objects(object, friend)
    if distance < SAFE_DISTANCE
      false
    else
      true
    end
  end
end

class InvaderRadarEngineSearching < InvaderRadarEngine
  attr_accessor :radar_direction
  attr_accessor :radar_size

  def initialize invader
    @radar_direction = 1
    @radar_size = 60
    super(invader)
  end

  def corner
    @math.rotated(@robot.heading_of_edge, -90 * @radar_direction)
  end

  def point_radar
    if (@ready_for_metronome == false) && @robot.radar_heading != corner
      @turn_radar = @math.turn_toward(@robot.radar_heading, corner)
      return
    end
    #puts "current radar_direction = #{@radar_direction}, heading = #{@robot.radar_heading}, corner = #{corner}"
    if @robot.radar_heading == corner
      @ready_for_metronome = true
      back_to_gun = @math.turn_toward(@robot.radar_heading, @robot.opposite_edge)
      if (back_to_gun > 0)
        @radar_direction = 1
      else
        @radar_direction = -1
      end
    end

    @turn_radar = @radar_size * @radar_direction
    new_radar_direction = @math.rotated(@robot.radar_heading, @turn_radar)
    if @radar_direction < 0
      if @math.radar_heading_between?(new_radar_direction, corner, @math.rotated(corner, 180))
        @turn_radar = @math.turn_toward(@robot.radar_heading, corner)
      end
    else
      if @math.radar_heading_between?(new_radar_direction, @math.rotated(corner, 180), corner)
        @turn_radar = @math.turn_toward(@robot.radar_heading, corner)
      end
    end
    #puts "turning #{@turn_radar}, new radar_direction = #{@radar_direction}"
  end

  def locate_enemy scan
    if @ready_for_metronome == false
      return nil
    end
    if @radar_size < 4
      radar = @math.rotated(@robot.radar_heading, 0 - @radar_size/2)
      enemy = @math.get_radar_point(radar, scan, @robot.location )
      @ready_for_metronome = false
      @radar_size = 60
      return enemy
    end

    if enemy_not_in_section_at_distance? scan
      @radar_size = @radar_size/2
      @radar_direction = 0 - @radar_direction
    end
    return nil
  end

  def enemy_not_in_section_at_distance? distance
    if @robot.friend.nil?
      return true
    end
    friend_distance = @math.distance_between_objects(@robot.location, @robot.friend)
    if (friend_distance - distance).abs < SAFE_DISTANCE
      return false
    end
    end_radar = @robot.radar_heading
    begin_radar = @math.rotated(@robot.radar_heading, 0 - @radar_size)

    min_angle = [end_radar, begin_radar].min
    max_angle = [end_radar, begin_radar].max
    left_angle = max_angle
    right_angle = min_angle
    if max_angle > 270 and min_angle < 90
      left_angle = min_angle
      right_angle = max_angle
    end
    if @math.radar_heading_between? @math.degree_from_point_to_point(@robot.location, @robot.friend),left_angle, right_angle
      return false
    end
    return true
  end

end

class InvaderRadarEngineHeadToEdge < InvaderRadarEngine
  def point_radar
    @ready_for_metronome = true
    @turn_radar = 1 if @robot.time == 0
  end
end

class InvaderRadarEngineSearchOppositeCorner < InvaderRadarEngine
  def locate_enemy scan
    desired_direction = @math.rotated(@robot.heading_of_edge, @robot.current_direction * -90)
    get_corner_scan_location(desired_direction, scan.to_f, @robot.location)
  end

  def point_radar
    desired_direction = @math.rotated(@robot.heading_of_edge, @robot.current_direction * -90)
    check_direction = @math.rotated(@robot.heading_of_edge, @robot.current_direction * -91)
    if (@robot.radar_heading == desired_direction)
      @ready_for_metronome = true
      desired_direction = check_direction
    end
    if (@robot.radar_heading == check_direction) and @robot.found_enemy.nil?
      @robot.change_mode InvaderMode::HEAD_TO_EDGE
    end
    @turn_radar = @robot.math.turn_toward(@robot.radar_heading, desired_direction)
  end
end

class InvaderRadarEngineProvidedTarget < InvaderRadarEngine
  attr_accessor :target_enemy

  def point_radar
    @target_enemy = @robot.broadcast_enemy unless @robot.broadcast_enemy.nil?
    last_known_location = @target_enemy
    enemy_direction = @math.degree_from_point_to_point(@robot.location, last_known_location)
    left_side = @math.rotated(enemy_direction,5)
    right_side = @math.rotated(enemy_direction, -5)
    if @ready_for_metronome == false
      if @robot.math.radar_heading_between?(enemy_direction, left_side, right_side)
        @ready_for_metronome = true
        @metronome_side = "left"
      else
        @turn_radar = @math.turn_toward(@robot.radar_heading, enemy_direction)
      end
    end
    if (@ready_for_metronome == true)
      if @metronome_side == "left"
        @turn_radar =@math.turn_toward(@robot.radar_heading, left_side)
        @metronome_side = "right"
      else
        @turn_radar =@math.turn_toward(@robot.radar_heading, right_side)
        @metronome_side = "left"
      end
    end
  end

  def locate_enemy scan
    @target_enemy = @robot.broadcast_enemy unless @robot.broadcast_enemy.nil?
    desired_direction = @math.degree_from_point_to_point(@robot.location, @target_enemy)
    enemy = @math.get_radar_point(desired_direction, scan.to_f, @robot.location)
    return enemy
  end
end

class InvaderPoint
  attr_accessor :x,:y
  def initialize(x,y)
    @x,@y = x,y
  end
end

class InvaderMath

    CLOCKWISE = -1
    COUNTERCLOCKWISE = 1

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
