$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'SpinnerBot')
require 'robot'
require 'spinner_logger'
require 'spinner_math'
require 'spinner_driver'
require 'spinner_gunner'
require 'spinner_radar'

class SpinnerBot
  include Robot
  attr_accessor :target
  attr_accessor :old_radar_heading
  attr_accessor :suppress_radar
  attr_reader :partner_location
  attr_reader :partner_target
  attr_reader :dominant
  attr_reader :bot_detected
  attr_reader :broadcast_sent
  attr_reader :desired_radar_turn
  attr_reader :desired_gun_turn
  attr_reader :desired_turn
  attr_reader :target_range
  attr_accessor :time_bot_detected

  #@@logger = SpinnerLogger.new

  def initialize
    @target = Point.new(800,800)
    @dominant = false
    @suppress_radar = false
    @time_bot_detected = nil
    @target_range = 0
    @radar = SpinnerRadar.new(self)
  end

  def tick events
    say "Master #{@target_range}" if (@dominant || @partner_location.nil?)
    say "Servant #{@target_range}" if !(@dominant || @partner_location.nil?)
    process_broadcast events['broadcasts'] unless events.nil?
    process_radar_results events['robot_scanned'] unless events.nil?
    @old_radar_heading = radar_heading
    drive
    aim
    sweep_radar
    send_broadcast
    #@@logger.LogStatusToFile self
  end

  def send_broadcast
    location_next_turn = my_location_next_turn
    message = "#{location_next_turn.x.to_i},#{location_next_turn.y.to_i}"
    if !@bot_detected.nil?
      message += ",#{@bot_detected.x.to_i},#{@bot_detected.y.to_i}, #{@target_range}"
    end
    @broadcast_sent = message
    broadcast message
  end

  def process_broadcast broadcast_event
    @partner_location = nil
    @partner_target = nil
    if broadcast_event.count > 0
      message = broadcast_event[0][0]
      message_parcels = message.split(",")
      @partner_location = Point.new(message_parcels[0].to_f, message_parcels[1].to_f)
      @partner_target = Point.new(message_parcels[2].to_f, message_parcels[3].to_f) if message_parcels.count > 2
      @target = @partner_target if !@dominant && !@partner_target.nil?
      @target_range = message_parcels[4].to_f if !@dominant && !@partner_target.nil? && message_parcels.count > 4
    else
      @dominant = true if time == 1
    end
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
    @desired_turn, acceleration = SpinnerDriver.new.drive(speed, my_location, @target, @partner_location, @dominant, heading)
    accelerate acceleration
    stop if acceleration < 0
    turn @desired_turn
  end

  def aim
    @desired_gun_turn, fire_strength = SpinnerGunner.new.aim(@desired_turn, gun_heading, my_location_next_turn, @target, @target_range, time)
    turn_gun @desired_gun_turn
    fire fire_strength
  end

  def sweep_radar
    @desired_radar_turn = @radar.sweep_radar
    turn_radar @desired_radar_turn
  end

  def process_radar_results detected_bots
    @bot_detected = nil
    if @suppress_radar
      @suppress_radar = false
      return
    end
    return if detected_bots.nil?
    return if detected_bots.count == 0
    scan_list = []
    detected_bots.each do |element|
      scan_list << element.first
    end
    scan_list.sort!
    scan_list.each do |distance|
      friend = false
      if !@partner_location.nil?
        friend_direction = SpinnerMath.degree_from_point_to_point(my_location, @partner_location)
        friend_distance = SpinnerMath.distance_between_objects(my_location, @partner_location)
        friend = radar_heading_between?(friend_direction, @old_radar_heading, radar_heading, @radar.radar_direction) && (friend_distance - distance).abs < 32
      end
      if !friend
        @bot_detected = locate_target(distance)
        @time_bot_detected = time
        @target = @bot_detected
      end
    end
  end

  def locate_target distance
    @old_radar_heading ||= SpinnerMath.rotate(radar_heading, 0 - @radar.radar_direction * @radar.radar_size)
    angle = SpinnerMath.turn_toward(radar_heading, @old_radar_heading)
    @target_range = (angle/2).abs
    angle = SpinnerMath.rotate(@old_radar_heading, @radar.radar_direction * (angle/2))
    a = (Math.sin(angle * Math::PI/180) * distance.to_f)
    b = (Math.cos(angle * Math::PI/180) * distance.to_f)
    Point.new(x + b, y - a)
  end

  def radar_heading_between? heading, left_edge, right_edge, direction
    result = between_headings? heading, left_edge, right_edge
    return result if direction < 0
    return !result
  end

  def between_headings? heading, left_edge, right_edge
    if right_edge > left_edge
      return !between_headings?(heading, right_edge, left_edge)
    end
    if left_edge > heading and heading > right_edge
      return true
    end
    return false
  end

  def set_radar_size radar_size
    @radar.radar_size = radar_size
  end

  def get_radar_size
    @radar.radar_size
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