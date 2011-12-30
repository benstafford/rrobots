
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
  attr_accessor :heading_of_edge
  attr_accessor :friend
  attr_accessor :friend_edge
  attr_accessor :current_direction
  attr_accessor :at_edge
  attr_accessor :target
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
    @target = @broadcast_enemy unless @broadcast_enemy.nil?
    @last_target_time = time unless @broadcast_enemy.nil?
    @target = @found_enemy unless @found_enemy.nil?
    @last_target_time = time unless @found_enemy.nil?
    #@last_target_time = @robot.time unless @robot.broadcast_enemy.nil?
    #@target_enemy = @robot.broadcast_enemy unless @robot.broadcast_enemy.nil?
    #@last_target_time = @robot.time unless @robot.found_enemy.nil?
    #@target_enemy = @robot.found_enemy unless @robot.found_enemy.nil?
    #@target_enemy = nil unless @robot.time - 15 < @last_target_time
  end

end

