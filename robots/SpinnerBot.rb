$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'SpinnerBot')
require 'robot'
require 'spinner_logger'
require 'spinner_math'
require 'spinner_driver'
require 'spinner_gunner'
require 'spinner_radar'
require 'spinner_targeting'
require 'spinner_communicator'

class SpinnerBot
  include Robot
  attr_accessor :target
  attr_accessor :old_radar_heading
  attr_accessor :suppress_radar
  attr_accessor :bot_detected
  attr_accessor :time_bot_detected
  attr_accessor :target_range
  attr_accessor :partner_location
  attr_accessor :partner_target
  attr_accessor :dominant
  attr_reader :broadcast_sent
  attr_reader :desired_radar_turn
  attr_reader :desired_gun_turn
  attr_reader :desired_turn
  attr_reader :radar

  #@@logger = SpinnerLogger.new

  def initialize
    @target = Point.new(800,800)
    @dominant = false
    @suppress_radar = false
    @time_bot_detected = nil
    @target_range = 0
    @radar = SpinnerRadar.new(self)
    @detect_log = []
  end

  def tick events
    say "Master #{@target_range}" if (@dominant || @partner_location.nil?)
    say "Servant #{@target_range}" if !(@dominant || @partner_location.nil?)
    SpinnerCommunicator.new(self).process_broadcast events['broadcasts'] unless events.nil?
    process_radar_results events['robot_scanned'] unless events.nil?
    @old_radar_heading = radar_heading
    drive
    aim
    sweep_radar
    @broadcast_sent = SpinnerCommunicator.new(self).send_broadcast
    broadcast @broadcast_sent
    #@@logger.LogStatusToFile self
  end

  def my_location
    Point.new(x,y)
  end

  def my_location_next_turn
    new_x = x + Math.cos(my_heading_next_turn.to_rad) * my_speed_next_turn
    new_y = y - Math.sin(my_heading_next_turn.to_rad) * my_speed_next_turn
    Point.new(new_x.to_i, new_y.to_i)
  end

  def my_speed_next_turn
    speed < 8 ? speed + 1 : speed
  end

  def my_heading_next_turn
    heading + @desired_turn
  end

  def drive
    @desired_turn, acceleration = SpinnerDriver.new(self).drive
    accelerate acceleration
    stop if acceleration < 0
    turn @desired_turn
  end

  def aim
    @desired_gun_turn, fire_strength = SpinnerGunner.new(self).aim
    turn_gun @desired_gun_turn
    fire fire_strength
  end

  def sweep_radar
    @desired_radar_turn = @radar.sweep_radar
    turn_radar @desired_radar_turn
  end

  def process_radar_results detected_bots
    SpinnerTargeting.new(self).process_radar_results detected_bots
  end

  def set_radar_size radar_size
    @radar.radar_size = radar_size
  end

  def get_radar_size
    @radar.radar_size
  end

  def log_detected_bot bot_detected, time
    prev_log_hash = @detect_log[@detect_log.count - 1] unless @detect_log.count < 1
    direction = nil
    velocity = 0
    if !prev_log_hash.nil?
      prev_location = Point.new(prev_log_hash['x'], prev_log_hash['y'])
      prev_time = prev_log_hash['time']
      direction = SpinnerMath.degree_from_point_to_point(prev_location, bot_detected)
      velocity = SpinnerMath.distance_between_objects(prev_location, bot_detected)/(time - prev_time)
    end
    @detect_log << {"x"=>bot_detected.x, "y"=>bot_detected.y, "time"=>time, "direction"=>direction, "velocity"=>velocity }
  end

  def get_previous_bot_location index
    count = @detect_log.count
    return nil, 0 if count < (index + 1)
    log_hash = @detect_log[count - (index + 1)]
    return Point.new(log_hash['x'], log_hash['y']), log_hash['time']
  end

  class Point
    attr_accessor :x
    attr_accessor :y
    def initialize x,y
      @x = x
      @y = y
    end
  end
end