$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'NewInvader')
require 'robot'
require 'InvaderFiringEngine'
require 'InvaderMath'
require 'InvaderMovementEngine'
require 'InvaderRadarEngine'
require 'InvaderLogger'

class NewInvader
   include Robot
   include InvaderMath
  @@number_classes_initialized = 0
  @@logger = InvaderLogger.new
  attr_accessor :is_master
  attr_accessor :heading_of_edge
  attr_accessor :friend
  attr_accessor :friend_edge
  attr_accessor :current_direction
  attr_accessor :at_edge
  attr_accessor :target
  attr_accessor :enemy_direction
  attr_accessor :enemy_speed
  attr_accessor :last_target_time
  attr_accessor :my_id
  attr_accessor :move_engine
  attr_accessor :fire_engine
  attr_accessor :radar_engine

  PERSISTENT_TARGET_TIME = 15
  def initialize
    @is_master = false
    if @@number_classes_initialized % 2 == 1
      @is_master = true
    end

    @@number_classes_initialized = @@number_classes_initialized + 1
    @my_id = @@number_classes_initialized
    @@logger.register @my_id

    @move_engine = InvaderMovementEngine.new(self)
    @fire_engine =  InvaderFiringEngine.new(self)
    @radar_engine = InvaderRadarEngine.new(self)

    @heading_of_edge = nil
    @friend = nil
    @friend_id = nil
    @friend_edge = nil
    @broadcast_enemy = nil
    @found_enemy = nil
    @target = nil
    @enemy_direction = nil
    @enemy_speed = nil
    @current_direction = 1
    @at_edge = false
    @energy_last_turn = 100
  end

  def tick events
    react_to_events
    move
    fire_gun
    radar_sweep
    make_turns
    send_broadcast
    @@logger.LogStatusToFile self
    @energy_last_turn = energy
  end

  def got_hit?
    strength = 0
    strength = (@energy_last_turn - energy)/3 if !events['got_hit'].empty?
    #strength = events['got_hit'].first.first/3 if !events['got_hit'].empty?
    return !events['got_hit'].empty?, strength
  end

  def opposite_edge
    rotated heading_of_edge, 180
  end

  def location
    InvaderPoint.new(x,y)
  end

  def location_next_tick
    new_x = x + Math.cos(heading.to_rad) * speed
    new_y = y - Math.sin(heading.to_rad) * speed
    InvaderPoint.new(new_x, new_y)
  end

  def my_distance_to_edge edge
    distance_to_edge edge, location, battlefield_width, battlefield_height
  end

  def fire_engine
    @fire_engine
  end

  def radar_engine
    @radar_engine
  end

  private

  def send_broadcast
    broadcast "#{@my_id}"
    @@logger.log @my_id, time, location, @heading_of_edge, @found_enemy
  end

  def react_to_events
    expire_lost_target
    record_friend
    record_broadcast_enemy
    record_radar_detected
    determine_target
  end

  def expire_lost_target
    if !@last_target_time.nil?
      if time - @last_target_time == PERSISTENT_TARGET_TIME
        @last_target_time = nil
        @target = nil
      end
    end
  end

  def move
    @move_engine.move
  end

  def fire_gun
    fire_engine.fire
  end

  def radar_sweep
    radar_engine.radar_sweep
  end

  def make_turns
    accelerate @move_engine.accelerate
    move_turn = [[@move_engine.turn, 10].min, -10].max
    turn move_turn if move_turn != 0

    gun_turn = [[(0 - move_turn) + fire_engine.turn_gun,30].min, -30].max
    turn_gun gun_turn if gun_turn !=0
    fire fire_engine.firepower unless fire_engine.firepower == 0

    radar_turn = [[(0 - (gun_turn + move_turn)) + radar_engine.turn_radar, 60].min, -60].max
    turn_radar radar_turn if radar_turn != 0
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
    @friend_edge = nil
    @friend_id = nil
    message = get_broadcast()
    if !message.nil?
      @friend_id = message.to_i
      @friend = @@logger.getFriendLocation(@friend_id)
      @friend_edge = @@logger.getFriendEdge(@friend_id)
    end
  end

  def record_broadcast_enemy
    @broadcast_enemy = nil
    if !@friend_id.nil?
      @broadcast_enemy = @@logger.getFoundEnemy(@friend_id, time)
    end
  end

  def record_radar_detected
    @found_enemy = radar_engine.scan_radar(events['robot_scanned'])
  end

  def determine_target
    prev_target = target
    @enemy_direction = nil
    @enemy_speed = nil
    @target = @broadcast_enemy unless @broadcast_enemy.nil?
    @last_target_time = time unless @broadcast_enemy.nil?
    @target = @found_enemy unless @found_enemy.nil?
    @last_target_time = time unless @found_enemy.nil?
    if @is_master == false
      @target = @broadcast_enemy unless @broadcast_enemy.nil?
      @last_target_time = time unless @broadcast_enemy.nil?
    end

    return if prev_target.nil? or @target.nil?
    @enemy_direction = degree_from_point_to_point(prev_target, target)
    @enemy_speed = distance_between_objects(prev_target, target)
    @enemy_speed = nil if @enemy_speed > 8
    @enemy_direction = nil if @enemy_speed.nil?
  end
end
