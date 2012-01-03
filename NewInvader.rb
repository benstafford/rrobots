
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'robots/NewInvader')
require 'robot'
require 'InvaderFiringEngine'
require 'InvaderMath'
require 'InvaderMovementEngine'
require 'InvaderRadarEngine'
require 'InvaderLogger'
require 'LcfVersion02'

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

  PERSISTENT_TARGET_TIME = 4
  @@private_battlefield =  Battlefield.new 1600, 1600, 50001, Time.now.to_i

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

    @loren_shield = Object.const_get("LcfVersion02").new
    @loren_shield = RobotRunner.new(@loren_shield, @@private_battlefield, 1)
    @@private_battlefield << @loren_shield
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
  end

  def tick events
    react_to_events
    move
    fire_gun
    radar_sweep
    send_broadcast
    deflect_loren
  end

  def deflect_loren
    @loren_shield.x = x
    @loren_shield.y = y
    begin
      @loren_shield.internal_tick
    rescue
      puts "loren bot error'd'"
    end
  end

  def change_mode desired_mode
    @mode = desired_mode
    radar_engine.ready_for_metronome = false
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

  private
  def fire_engine
    @fire_engine
  end

  def radar_engine
    @radar_engine
  end

  def move_engine
    @move_engine
  end

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
      @broadcast_enemy = @@logger.getFoundEnemy(@friend_id)
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
