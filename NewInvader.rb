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


  def initialize
    @mode = InvaderMode::HEAD_TO_EDGE
    @move_engine = InvaderMovementEngine.new(self)
    @fire_engine = InvaderFiringEngine.new(self)
    @radar_engine = []
    @radar_engine[InvaderMode::HEAD_TO_EDGE] = InvaderRadarEngineHeadToEdge.new(self)
    @radar_engine[InvaderMode::PROVIDED_TARGET] = InvaderRadarEngineProvidedTarget.new(self)
    @radar_engine[InvaderMode::FOUND_TARGET] = InvaderRadarEngine.new(self)
    @radar_engine[InvaderMode::SEARCHING] = InvaderRadarEngine.new(self)
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
    @radar_engine[desired_mode].ready_for_metronome = false
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
    @move_engine.move
    accelerate @move_engine.accelerate
    turn @move_engine.turn
  end

  def fire_gun
    @fire_engine.fire
    turn_gun (0 - @move_engine.turn) + @fire_engine.turn_gun
    fire @fire_engine.firepower unless @fire_engine.firepower == 0
  end

  def radar_sweep
    @radar_engine[@mode].radar_sweep
    turn_radar (0 - @move_engine.turn) + (0 - @fire_engine.turn_gun) + @radar_engine[@mode].turn_radar
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
    @found_enemy = @radar_engine[@mode].scan_radar(events['robot_scanned'])
    if not @found_enemy.nil? and @mode == InvaderMode::SEARCHING
      say "Found!"
      change_mode InvaderMode::FOUND_TARGET
    end
    if not @found_enemy.nil? and @mode == InvaderMode::SEARCH_OPPOSITE_CORNER
      say "Sneaking up on me, eh?!"
    end

  end


  class InvaderMovementEngine
    attr_accessor :accelerate
    attr_accessor :turn
    attr_accessor :robot
    attr_accessor :current_direction
    attr_accessor :pursuit_time
    attr_accessor :target_enemy
    attr_accessor :math

    DISTANCE_PAST_SCAN = 5
    PURSUE_FRIEND_TARGET_TIME = 20

    def initialize invader
      @robot = invader
      @current_direction = 1
      @math = InvaderMath.new
    end

    def move
      @accelerate = 0
      @turn = 0
      case @robot.mode
        when InvaderMode::HEAD_TO_EDGE
          head_to_edge
        when InvaderMode::PROVIDED_TARGET
          provided_target_mode
        when InvaderMode::FOUND_TARGET
          pursue_found_target
        when InvaderMode::SEARCHING
          search_my_row
        when InvaderMode::SEARCH_OPPOSITE_CORNER
          @accelerate = 0 - @robot.speed
      end
    end

    private
    def search_my_row
      turn_around if need_to_turn?
      if @current_direction > 0 and @robot.distance_to_edge(right_of_edge) <= @robot.size + 1
        @current_direction = -1
        @robot.change_mode InvaderMode::SEARCH_OPPOSITE_CORNER
      end
      if @current_direction < 0 and @robot.distance_to_edge(left_of_edge) <= @robot.size + 1
        @current_direction = 1
        @robot.change_mode InvaderMode::SEARCH_OPPOSITE_CORNER
      end
      @accelerate = @current_direction
    end

    def pursue_found_target
      turn_around if need_to_turn?
      @target_enemy = @robot.found_enemy unless @robot.found_enemy.nil?
      enemy_direction = @robot.math.degree_from_point_to_point(@robot.location, @target_enemy)
      radar_heading = @robot.opposite_edge
      if @math.radar_heading_between?(radar_heading, @math.rotated(enemy_direction, 5), @math.rotated(enemy_direction, -5)) == false
          @robot.say "pursuing"
          #puts "pursuing #{radar_heading} is not between #{@math.rotated(enemy_direction, -5)} and #{@math.rotated(enemy_direction, 5)}"
          @current_direction = 0 - @current_direction
          @robot.change_mode InvaderMode::SEARCHING
      end
      if @current_direction > 0 and @robot.distance_to_edge(right_of_edge) <= @robot.size + 1
        @robot.change_mode InvaderMode::SEARCHING
      end
      if @current_direction < 0 and @robot.distance_to_edge(left_of_edge) <= @robot.size + 1
        @robot.change_mode InvaderMode::SEARCHING
      end

      @accelerate = @current_direction
    end

    def provided_target_mode
      turn_around if need_to_turn?
      if not @robot.broadcast_enemy.nil?
        @target_enemy = @robot.broadcast_enemy
        direction = @robot.math.turn_toward(@robot.opposite_edge, @robot.math.degree_from_point_to_point(@robot.location_next_tick, @robot.broadcast_enemy))
        if direction > 0
          @robot.say "Coming, Buddy!"
          @current_direction = 1
        else
          @robot.say "I'll Get Him!'"
          @current_direction = -1
        end
        @pursuit_time = @robot.time + PURSUE_FRIEND_TARGET_TIME
      end
      if @robot.time > @pursuit_time
        @robot.change_mode InvaderMode::SEARCHING
      end
      @accelerate = @current_direction
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

    def distance_to_initial_edge edge_heading, distance
      if not @robot.friend_edge.nil?
        return @robot.battlefield_width + 1 if @robot.friend_edge == edge_heading
        return @robot.battlefield_width + 1 if @robot.math.rotated(@robot.friend_edge, 180) == edge_heading
      end
      distance
    end

    def head_to_edge
      select_closest_edge
      if at_edge?
        @robot.change_mode InvaderMode::SEARCHING
      else
        @accelerate = 1
        @turn = @robot.math.turn_toward(@robot.heading, @robot.heading_of_edge)
      end
    end

    def need_to_turn?
      @robot.heading!=right_of_edge
    end

    def turn_around
      @turn = @robot.math.turn_toward(@robot.heading, right_of_edge)
    end

    def at_edge?
      @robot.distance_to_edge(@robot.heading_of_edge) <= (@robot.size + 1)
    end

    def left_of_edge
      return @robot.math.rotated(@robot.heading_of_edge, 90)
    end

    def right_of_edge
      return @robot.math.rotated(@robot.heading_of_edge, -90)
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
    end

    def fire
      @turn_gun = 0
      @firepower = 0
      case @robot.mode
        when InvaderMode::HEAD_TO_EDGE
          @turn_gun = 10
          @firepower = 3 unless @robot.events['robot_scanned'].empty?
        when InvaderMode::PROVIDED_TARGET
          @target_enemy = @robot.broadcast_enemy unless @robot.broadcast_enemy.nil?
          point_gun @math.degree_from_point_to_point(@robot.location_next_tick, @target_enemy) + + Math.sin(@robot.time)
          @firepower = power_based_on_distance
        when InvaderMode::FOUND_TARGET
          @target_enemy = @robot.found_enemy unless @robot.found_enemy.nil?
          point_gun @math.degree_from_point_to_point(@robot.location_next_tick, @target_enemy) + + Math.sin(@robot.time)
          #point_gun @robot.opposite_edge + Math.sin(@robot.time)
          @firepower = power_based_on_distance
        when InvaderMode::SEARCHING
          point_gun @robot.opposite_edge + Math.sin(@robot.time)
          @firepower = 0.1
        when InvaderMode::SEARCH_OPPOSITE_CORNER
          desired_gun_heading = @math.rotated(@robot.heading_of_edge, @robot.move_engine.current_direction * -90)
          point_gun desired_gun_heading # + Math.sin(@robot.time)
          if @robot.gun_heading == desired_gun_heading
            @firepower = 3.0
          end
      end
      dont_fire_at_friend
    end

    private

    def power_based_on_distance
      this = InvaderPoint.new(@robot.x, @robot.y)
      distance = @robot.math.distance_between_objects(this, @target_enemy)
      firepower = 3.0 - (distance/780)
      return firepower
    end

    def dont_fire_at_friend
      return if @robot.friend.nil?
      friend_direction = @robot.math.degree_from_point_to_point @robot.location, @robot.friend
      @firepower = 0 if friend_direction == @robot.gun_heading
      return if @robot.friend_edge.nil?
      @firepower = 0 if @robot.gun_heading == @robot.opposite_edge and @robot.distance_to_edge(@robot.friend_edge.to_i) < (2 * @robot.size + 1)
    end

    def point_gun direction
      if (@robot.gun_heading != direction)
        @turn_gun = @robot.math.turn_toward(@robot.gun_heading, direction)
        @turn_gun = 30 if @turn_gun > 30
        @turn_gun = -30 if @turn_gun < -30
      end
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
        if enemy?(enemy, @robot.friend)
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
      desired_direction = lead_search_movement(@robot.radar_heading, @robot.move_engine.current_direction)
    end
    @turn_radar = @robot.math.turn_toward(@robot.radar_heading, desired_direction)
  end

  def locate_enemy scan
    get_scan_loc(scan, @robot.move_engine.current_direction, @robot.opposite_edge, @robot.location)
  end

  def lead_search_movement(current_heading, direction)
    current_heading + (direction * RADAR_LEAD)
  end

  def get_corner_scan_location radar_heading, distance, location
    return @math.get_radar_point(radar_heading, distance, location)
  end

 def get_scan_loc distance, direction, edge, location
   direction = @robot.move_engine.current_direction
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

class InvaderRadarEngineHeadToEdge < InvaderRadarEngine
  def point_radar
    @ready_for_metronome = true
    @turn_radar = 1 if @robot.time == 0
  end
end

class InvaderRadarEngineSearchOppositeCorner < InvaderRadarEngine
  def locate_enemy scan
    desired_direction = @math.rotated(@robot.heading_of_edge, @robot.move_engine.current_direction * -90)
    get_corner_scan_location(desired_direction, scan.to_f, @robot.location)
  end

  def point_radar
    desired_direction = @math.rotated(@robot.heading_of_edge, @robot.move_engine.current_direction * -90)
    check_direction = @math.rotated(@robot.heading_of_edge, @robot.move_engine.current_direction * -91)
    if (@robot.radar_heading == desired_direction)
      @ready_for_metronome = true
      desired_direction = check_direction
    end
    if (@robot.radar_heading == check_direction) and @robot.found_enemy.nil?
      @robot.change_mode InvaderMode::SEARCHING
    end
    @turn_radar = @robot.math.turn_toward(@robot.radar_heading, desired_direction)
  end
end

class InvaderRadarEngineProvidedTarget < InvaderRadarEngine
  def point_radar
    last_known_location = @robot.move_engine.target_enemy
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
    desired_direction = @math.degree_from_point_to_point(@robot.location, @robot.move_engine.target_enemy)
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
