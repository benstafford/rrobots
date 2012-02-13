$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'SpinnerBot')
require 'robot'
require 'spinner_logger'
require 'spinner_math'
require 'spinner_driver'
require 'spinner_gunner'

class SpinnerBot
  include Robot
  attr_accessor :target
  attr_accessor :radar_size
  attr_accessor :old_radar_heading
  attr_reader :partner_location
  attr_reader :dominant
  attr_reader :bot_detected
  attr_reader :broadcast_sent
  attr_reader :desired_radar_turn
  attr_reader :desired_gun_turn
  attr_reader :desired_turn

  RADAR_SCAN_SIZE = 3..48
  #@@logger = SpinnerLogger.new

  def initialize
    @target = Point.new(800,800)
    @dominant = false
    @radar_direction = 1
    @radar_size = 60
    @suppress_radar = false
    @time_bot_detected = nil
    @turning_to_partner_target = false
  end

  def tick events
    say "Master #{time}" if (@dominant || @partner_location.nil?)
    say "Servant #{time}" if !(@dominant || @partner_location.nil?)
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
      message += ",#{@bot_detected.x.to_i},#{@bot_detected.y.to_i}"
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
    @desired_gun_turn = SpinnerMath.turn_toward gun_heading, SpinnerMath.degree_from_point_to_point(my_location_next_turn, target)
    @desired_gun_turn = [[(0 - @desired_turn) + @desired_gun_turn,30].min, -30].max
    turn_gun @desired_gun_turn
    #fire 3.0 if !@bot_detected.nil? && (gun_heat == 0) && @radar_size == RADAR_SCAN_SIZE.min
    fire 3.0
  end

  def sweep_radar
    case
      when partner_has_provided_close_target? then scan_over_partner_target
      when partner_has_provided_a_distant_target? then point_radar_to_partner_target
      when @turning_to_partner_target then point_radar_to_partner_target
      when !@bot_detected.nil? then reverse_and_narrow_radar_direction
      when lost_target? then reverse_and_expand_direction
    end
    return if @suppress_radar
    @radar_size = [[@radar_size, RADAR_SCAN_SIZE.min ].max, RADAR_SCAN_SIZE.max].min
    radar_turn = (@radar_direction * @radar_size)
    radar_turn = drag_right(radar_turn)
    radar_turn = [[(0 - (@desired_gun_turn + @desired_turn)) + radar_turn, 60].min, -60].max
    @desired_radar_turn = radar_turn
    turn_radar radar_turn
  end

  def drag_right radar_turn
    radar_turn - 1
  end

  def scan_over_partner_target
    @radar_size = RADAR_SCAN_SIZE.min
    desired_radar_degree = SpinnerMath.degree_from_point_to_point(my_location_next_turn, @target)
    radar_turn = SpinnerMath.turn_toward(radar_heading, desired_radar_degree)
    @radar_direction = [[radar_turn,1].min,-1].max
  end

  def partner_has_provided_close_target?
    return false if @dominant
    return false if @partner_target.nil?
    desired_radar_degree = SpinnerMath.degree_from_point_to_point(my_location_next_turn, @target)
    radar_turn = SpinnerMath.turn_toward(radar_heading, desired_radar_degree)
    return true if radar_turn.abs < 5
    false
  end

  def partner_has_provided_a_distant_target?
    return false if @dominant
    return false if @partner_target.nil?
    desired_radar_degree = SpinnerMath.degree_from_point_to_point(my_location_next_turn, @target)
    radar_turn = SpinnerMath.turn_toward(radar_heading, desired_radar_degree)
    return false if radar_turn.abs < 3
    true
  end

  def point_radar_to_partner_target
    @radar_size = RADAR_SCAN_SIZE.min
    @time_bot_detected = time
    @suppress_radar = true
    desired_radar_degree = SpinnerMath.degree_from_point_to_point(my_location_next_turn, @target)
    radar_turn = SpinnerMath.turn_toward(radar_heading, desired_radar_degree)
    if radar_turn > 0
      @radar_direction = 1
      desired_radar_degree = SpinnerMath.rotate(desired_radar_degree, -2)
    else
      @radar_direction = -1
      desired_radar_degree = SpinnerMath.rotate(desired_radar_degree, 2)
    end
    radar_turn = SpinnerMath.turn_toward(radar_heading, desired_radar_degree)
    radar_turn = [[(0 - (@desired_gun_turn + @desired_turn)) + radar_turn, 60].min, -60].max
    @turning_to_partner_target = !(SpinnerMath.rotate(radar_heading, radar_turn) == desired_radar_degree)
    @desired_radar_turn = radar_turn
    turn_radar radar_turn
  end

  def reverse_and_expand_direction
    @radar_size = @radar_size * 2  if @radar_size < RADAR_SCAN_SIZE.max
    reverse_radar_direction
  end

  def lost_target?
    return false if @time_bot_detected.nil?
    time_since_detect = time - @time_bot_detected
    [3,5,7,9].include?(time_since_detect) && @radar_size < RADAR_SCAN_SIZE.max
  end

  def reverse_and_narrow_radar_direction
    @radar_size = @radar_size /2  if @radar_size > RADAR_SCAN_SIZE.min
    reverse_radar_direction
  end

  def reverse_radar_direction
    @radar_direction = 0 - @radar_direction
  end

  def friend_in_new_section?
    return false if @partner_location.nil?
    current_radar = radar_heading
    new_radar = SpinnerMath.rotate(current_radar, @radar_direction * @radar_size)
    friend_direction = SpinnerMath.degree_from_point_to_point(my_location, @partner_location)
    radar_heading_between?(friend_direction, current_radar, new_radar, @radar_direction)
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
        friend = radar_heading_between?(friend_direction, @old_radar_heading, radar_heading, @radar_direction) && (friend_distance - distance).abs < 32
      end
      if !friend
        @bot_detected = locate_target(distance)
        @time_bot_detected = time
        @target = @bot_detected
      end
    end
  end

  def locate_target distance
    @old_radar_heading ||= radar_heading - @radar_direction * @radar_size
    angle = radar_heading - @old_radar_heading
    angle = 360 - angle if angle > 100
    angle = -360 - angle if angle < (-100)
    angle = SpinnerMath.rotate(@old_radar_heading, @radar_direction * (angle/2))
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

  class Point
    attr_accessor :x
    attr_accessor :y
    def initialize x,y
      @x = x
      @y = y
    end
  end
end