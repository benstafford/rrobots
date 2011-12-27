
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'robots/NewInvader')
require 'robot'
require 'InvaderFiringEngine'
require 'InvaderMath'
require 'InvaderMovementEngine'
require 'InvaderRadarEngine'
require 'LcfVersion02'

class NewInvader
   include Robot
   include InvaderMath

  attr_accessor :mode
  attr_accessor :heading_of_edge
  attr_accessor :friend
  attr_accessor :friend_edge
  attr_accessor :broadcast_enemy
  attr_accessor :found_enemy
  attr_accessor :current_direction
  attr_accessor :at_edge

  @@private_battlefield =  Battlefield.new 1600, 1600, 50001, Time.now.to_i

  def initialize
    @mode = InvaderMode::HEAD_TO_EDGE
    @move_engine = InvaderMovementEngine.new(self)
    @fire_engine =  InvaderFiringEngine.new(self)
    @radar_engine = InvaderRadarEngine.new(self)

    @loren_shield = Object.const_get("LcfVersion02").new
    @loren_shield = RobotRunner.new(@loren_shield, @@private_battlefield, 1)
    @@private_battlefield << @loren_shield
    @heading_of_edge = nil
    @friend = nil
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
  end
end

