require 'robot'
require 'robots/NewInvader/InvaderFiringEngine'
require 'robots/NewInvader/InvaderMath'
require 'robots/NewInvader/InvaderMovementEngine'
require 'robots/NewInvader/InvaderRadarEngine'
require 'LcfVersion02'

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
  attr_accessor :loren_shield

  @@private_battlefield =  Battlefield.new 1600, 1600, 50001, Time.now.to_i

  def initialize
    @mode = InvaderMode::HEAD_TO_EDGE
    @move_engine = []
    @move_engine[InvaderMode::HEAD_TO_EDGE] = InvaderDriverHeadToEdge.new(self)
    @move_engine[InvaderMode::PROVIDED_TARGET] = InvaderDriverProvidedTarget.new(self)
    @move_engine[InvaderMode::FOUND_TARGET] = InvaderDriverPursueTarget.new(self)
    @move_engine[InvaderMode::SEARCHING] = InvaderDriverSearching.new(self)
    @fire_engine = []
    @fire_engine[InvaderMode::HEAD_TO_EDGE] = InvaderGunnerHeadToEdge.new(self)
    @fire_engine[InvaderMode::PROVIDED_TARGET] = InvaderFiringEngine.new(self)
    @fire_engine[InvaderMode::FOUND_TARGET] = @fire_engine[InvaderMode::PROVIDED_TARGET]
    @fire_engine[InvaderMode::SEARCHING] = @fire_engine[InvaderMode::PROVIDED_TARGET]
    @radar_engine = []
    @radar_engine[InvaderMode::HEAD_TO_EDGE] = InvaderRadarEngineHeadToEdge.new(self)
    @radar_engine[InvaderMode::PROVIDED_TARGET] = InvaderRadarEngineProvidedTarget.new(self)
    @radar_engine[InvaderMode::FOUND_TARGET] = InvaderRadarEngine.new(self)
    @radar_engine[InvaderMode::SEARCHING] =  InvaderRadarEngineSearching.new(self) #@radar_engine[InvaderMode::FOUND_TARGET]
    @math = InvaderMath.new

    @loren_shield = Object.const_get("LcfVersion02").new
    @loren_shield = RobotRunner.new(@loren_shield, @@private_battlefield, 1)
    @@private_battlefield << @loren_shield
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
  end
end

