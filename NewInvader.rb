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
  attr_accessor :broadcast_enemy
  attr_accessor :found_enemy
  attr_accessor :last_target_time

  def initialize
    @mode = InvaderMode::HEAD_TO_EDGE
    @move_engine = InvaderMovementEngine.new(self)
    @fire_engine = InvaderFiringEngine.new(self)
    @radar_engine = InvaderRadarEngine.new(self)
    @math = InvaderMath.new(self)
  end

  def tick events
    broadcast_location
    react_to_events
    move
    fire_gun
    radar_sweep
  end

  private

  def broadcast_location
    broadcast "me=#{@x.to_i},#{@y.to_i}"
  end

  def react_to_events
    record_friend
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
    @radar_engine.radar_sweep
    turn_radar (0 - @move_engine.turn) + (0 - @fire_engine.turn_gun) + @radar_engine.turn_radar
  end

  def record_friend
    @friend = get_location_from_broadcast("me=")
  end

  def record_broadcast_enemy
    @broadcast_enemy = get_location_from_broadcast("Enemy=")
    if @mode == InvaderMode::SEARCHING and not @broadcast_enemy.nil?
      @mode = InvaderMode::PROVIDED_TARGET
      @last_target_time = time
    end
  end

  def get_location_from_broadcast string_identifier
    broadcasts = events['broadcasts']
    if (broadcasts.count > 0)
      broadcasts.each do |broadcast_message|
        message = broadcast_message[0]
        if message[0..(string_identifier.length-1)]==string_identifier
          location = message[string_identifier.length..100].split(",")
          return InvaderPoint.new(location[0].to_i, location[1].to_i)
        end
      end
    end
    nil
  end

  def record_radar_detected
    @found_enemy = nil
    robots_scanned = events['robot_scanned']
    if robots_scanned.count > 0 and radar_heading == @math.opposite_edge
      scan = robots_scanned.pop.first
      enemy = get_scan_loc(scan)
      if isEnemy?(enemy)
        broadcast "Enemy=#{enemy.x.to_i},#{enemy.y.to_i}"
        if @mode == InvaderMode::SEARCHING
          say "Found!"
          @mode = InvaderMode::FOUND_TARGET
        end
        @found_enemy = enemy
      end
    end
  end

  def get_scan_loc distance
    leading_distance = (Math.sin(5 * Math::PI/180) * distance.to_f)
    distance = (Math.cos(5 * Math::PI/180) * distance.to_f)
    direction = @move_engine.current_direction
    leading_distance *= direction
    case @math.opposite_edge
      when 0
        InvaderPoint.new(@x + distance, @y - leading_distance)
      when 90
        InvaderPoint.new(@x - leading_distance, @y - distance)
      when 180
        InvaderPoint.new(@x - distance, @y + leading_distance)
      when 270
        InvaderPoint.new(@x + leading_distance, @y + distance)
    end
  end

  SAFE_DISTANCE = 125

  def isEnemy? object
    return true if @friend.nil?
    friend = @friend
    distance = @math.distance_between_objects(object, friend)
    if distance < SAFE_DISTANCE
      false
    else
      true
    end
  end



  class InvaderMovementEngine
    attr_accessor :accelerate
    attr_accessor :turn
    attr_accessor :robot
    attr_accessor :current_direction
    attr_accessor :pursuit_time
    attr_accessor :target_enemy

    DISTANCE_PAST_SCAN = 5
    PURSUE_FRIEND_TARGET_TIME = 10

    def initialize invader
      @robot = invader
      @current_direction = 1
    end

    def move
      @accelerate = 0
      @turn = 0
      case @robot.mode
        when InvaderMode::HEAD_TO_EDGE
          if @robot.time == 0
            select_closest_edge
          end
          if at_edge?
            @robot.mode = InvaderMode::SEARCHING
          else
            head_to_edge
          end
        when InvaderMode::PROVIDED_TARGET
          if not @robot.broadcast_enemy.nil?
            direction = @robot.math.turn_toward(@robot.math.opposite_edge, @robot.math.degree_from_point(@robot.broadcast_enemy))
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
            @robot.mode = InvaderMode::SEARCHING
          end
          @accelerate = @current_direction
        when InvaderMode::FOUND_TARGET
          @target_enemy = @robot.found_enemy unless @robot.found_enemy.nil?
          enemy_direction = @robot.math.degree_from_point(@target_enemy)
          radar_heading = @robot.math.opposite_edge
          if @current_direction > 0
            radar_heading = 360 if radar_heading == 0
            if enemy_direction < radar_heading - 5
              @robot.say "pursuing"
              @current_direction = 0 - @current_direction
              @robot.mode = InvaderMode::SEARCHING
            end
          else
            if enemy_direction > radar_heading + 5
              @robot.say "pursuing"
              @current_direction = 0 - @current_direction
              @robot.mode = InvaderMode::SEARCHING
            end
          end
          @accelerate = @current_direction
        when InvaderMode::SEARCHING
          if need_to_turn?
            turn_around
          end
          if @current_direction > 0 and distance_to_edge(right_of_edge) <= @robot.size + 1
            @current_direction = -1
          end
          if @current_direction < 0 and distance_to_edge(left_of_edge) <= @robot.size + 1
            @current_direction = 1
          end
          @accelerate = @current_direction
      end
    end

    private
    def select_closest_edge
      edge_distance = []
      edge_distance[0] = [0, @robot.battlefield_width - @robot.x]
      edge_distance[1] = [90, @robot.y]
      edge_distance[2] = [180, @robot.x]
      edge_distance[3] = [270, @robot.battlefield_height - @robot.y]
      min_distance = @robot.battlefield_width
      min_index = 0
      for index in 0..3
        if edge_distance[index][1] < min_distance
          min_index = index
          min_distance = edge_distance[index][1]
        end
      end
      @robot.heading_of_edge = edge_distance[min_index][0]
    end

    def head_to_edge
      @accelerate = 1
      if @robot.heading != @robot.heading_of_edge
        @turn = [-10, @robot.heading_of_edge - @robot.heading].max
      end
    end

    def need_to_turn?
      @robot.heading!=right_of_edge
    end

    def distance_to_edge edge
      case edge
        when 0
          return @robot.battlefield_width - @robot.x
        when 90
          return @robot.y
        when 180
          return @robot.x
        when 270
          return @robot.battlefield_height - @robot.y
      end
    end

    def turn_around
      @accelerate = 0 - @robot.speed
      if @robot.heading%10 == 0
        @turn = -10
      else
        @turn = 0 - @robot.heading%10
      end
    end

    def at_edge?
      distance_to_edge(@robot.heading_of_edge) <= (@robot.size + 1)
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

    def initialize invader
      @robot = invader
    end

    def fire
      @turn_gun = 0
      @firepower = 0
      case @robot.mode
        when InvaderMode::HEAD_TO_EDGE
          @turn_gun = 10
          @firepower = 3 #unless @robots.events['robot_scanned'].empty?
        when InvaderMode::PROVIDED_TARGET
          @firepower = 0.1
        when InvaderMode::FOUND_TARGET
          @firepower = 0.1
        when InvaderMode::SEARCHING
          point_gun @robot.math.opposite_edge
          fire_stream
      end
    end

    private

    def fire_stream
      @firepower = 0.1
    end

    def point_gun direction
      if (@robot.gun_heading != direction)
        @turn_gun = @robot.math.turn_toward(@robot.gun_heading, direction)
        @turn_gun = 30 if @turn_gun > 30
        @turn_gun = -30 if @turn_gun < -30
      end
    end
  end

  class InvaderRadarEngine
    attr_accessor :turn_radar
    attr_accessor :robot

    RADAR_LEAD = 5

    def initialize invader
      @robot = invader
    end

    def radar_sweep
      @turn_radar = 0
      case @robot.mode
        when InvaderMode::HEAD_TO_EDGE
          @turn_radar = 1 if @robot.time == 0
        else
          desired_direction = @robot.math.opposite_edge
          if (@robot.radar_heading == desired_direction)
            desired_direction = lead_search_movement(@robot.radar_heading, @robot.move_engine.current_direction)
          end
          @turn_radar = @robot.math.turn_toward(@robot.radar_heading, desired_direction)
      end
    end

    def lead_search_movement(current_heading, direction)
      current_heading + (direction * RADAR_LEAD)
    end

  end

  class InvaderMath
    attr_accessor :robot

    def initialize invader
      @robot = invader
    end

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

    def opposite_edge
      rotated @robot.heading_of_edge, 180
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

    def degree_from_point point
      a = Math.atan2(@robot.y - point.y, point.x - @robot.x) / Math::PI * 180 % 360
    end

    def distance_between_objects object1, object2
      Math.hypot(object1.y - object2.y, object2.x - object1.x)
    end
  end

  class InvaderMode
    HEAD_TO_EDGE = 1
    PROVIDED_TARGET = 2
    FOUND_TARGET = 3
    SEARCHING = 4
  end

  class InvaderPoint
    attr_accessor :x,:y
    def initialize(x,y)
      @x,@y = x,y
    end
  end
end
