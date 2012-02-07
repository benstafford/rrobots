require 'robot'
class SpinnerBot
  include Robot
  attr_accessor :target
  attr_reader :partner_location
  attr_reader :dominant
  attr_accessor :radar_size

  MAINTAIN_DISTANCE = 300..400
  DISTANCE_BETWEEN_PARTNERS = 120
  RADAR_SCAN_SIZE = 3..48

  def puts message
  end

  def initialize
    @target = Point.new(800,800)
    @dominant = false
    @radar_direction = 1
    @radar_size = 60
    @suppress_radar = false
    @time_bot_detected = nil
    @turning_to_partner_target = false
  end

  def set_old_radar_heading  heading
    @old_radar_heading = heading
  end

  def tick events
    puts "tick"
    say "Master" if (@dominant || @partner_location.nil?)
    say "Servant" if !(@dominant || @partner_location.nil?)
    process_broadcast events['broadcasts'] unless events.nil?
    process_radar_results events['robot_scanned'] unless events.nil?
    @old_radar_heading = radar_heading
    drive
    aim
    sweep_radar
    send_broadcast
  end

  def send_broadcast
    location_next_turn = my_location_next_turn
    message = "#{location_next_turn.x},#{location_next_turn.y},#{my_heading_next_turn},#{my_speed_next_turn}"
    if !@bot_detected.nil?
      message += ",#{@bot_detected.x},#{@bot_detected.y}"
    end
    broadcast message
  end

  def process_broadcast broadcast_event
    @partner_location = nil
    @partner_target = nil
    if broadcast_event.count > 0
      message = broadcast_event[0][0]
      message_parcels = message.split(",")
      @partner_location = Point.new(message_parcels[0].to_f, message_parcels[1].to_f)
      @partner_target = Point.new(message_parcels[4].to_f, message_parcels[5].to_f) if message_parcels.count > 4
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
    @desired_turn = 0
    accelerate 1 if speed < 8
    distance_to_target = distance_between_objects(my_location, target)
    distance_to_partner =  @partner_location.nil? ? 3200 : distance_between_objects(my_location, @partner_location)
    case
      when distance_to_partner < DISTANCE_BETWEEN_PARTNERS && !@dominant then stop
      when distance_to_target > MAINTAIN_DISTANCE.max then driver_turn_toward_target
      when distance_to_target < MAINTAIN_DISTANCE.min then driver_turn_away_from_target
      else circle_target
    end
    turn @desired_turn
  end

  def aim
    @desired_gun_turn = turn_toward gun_heading, degree_from_point_to_point(my_location, target)
    @desired_gun_turn = [[(0 - @desired_turn) + @desired_gun_turn,30].min, -30].max
    turn_gun @desired_gun_turn
    #fire 3.0 if !@bot_detected.nil? && (gun_heat == 0) && @radar_size == RADAR_SCAN_SIZE.min
    fire 0.1
  end

  def sweep_radar
    puts "starting: #{@radar_size}, #{@radar_direction}"
    case
      when partner_has_provided_close_target? then scan_over_partner_target
      when partner_has_provided_a_distant_target? then point_radar_to_partner_target
      when @turning_to_partner_target then point_radar_to_partner_target
      when !@bot_detected.nil? then reverse_and_narrow_radar_direction
      when lost_target? then reverse_and_expand_direction
    end
    return if @suppress_radar
    puts "after decision, before clamping: #{@radar_size}, #{@radar_direction}"
    @radar_size = [[@radar_size, RADAR_SCAN_SIZE.min ].max, RADAR_SCAN_SIZE.max].min
    radar_turn = (@radar_direction * @radar_size)
    puts "after scan clamp, before adjusting for move: #{@radar_size}, #{@radar_direction}.  Robot turn=#{@desired_turn}, gun turn = #{@desired_gun_turn}"
    radar_turn = [[(0 - (@desired_gun_turn + @desired_turn)) + radar_turn, 60].min, -60].max
    turn_radar radar_turn
  end

  def scan_over_partner_target
    @radar_size = RADAR_SCAN_SIZE.min
    desired_radar_degree = degree_from_point_to_point(my_location_next_turn, @target)
    radar_turn = turn_toward(radar_heading, desired_radar_degree)
    @radar_direction = [[radar_turn,1].min,-1].max
  end

  def partner_has_provided_close_target?
    return false if @dominant
    return false if @partner_target.nil?
    desired_radar_degree = degree_from_point_to_point(my_location_next_turn, @target)
    radar_turn = turn_toward(radar_heading, desired_radar_degree)
    return true if radar_turn.abs < 3
    false
  end

  def partner_has_provided_a_distant_target?
    return false if @dominant
    return false if @partner_target.nil?
    desired_radar_degree = degree_from_point_to_point(my_location_next_turn, @target)
    radar_turn = turn_toward(radar_heading, desired_radar_degree)
    return false if radar_turn.abs < 3
    true
  end

  def point_radar_to_partner_target
    puts "turning radar to partners target"
    @radar_size = RADAR_SCAN_SIZE.min
    @time_bot_detected = time
    @suppress_radar = true
    desired_radar_degree = degree_from_point_to_point(my_location_next_turn, @target)
    radar_turn = turn_toward(radar_heading, desired_radar_degree)
    if radar_turn > 0
      @radar_direction = 1
      desired_radar_degree = rotate(desired_radar_degree, -2)
    else
      @radar_direction = -1
      desired_radar_degree = rotate(desired_radar_degree, 2)
    end
    radar_turn = turn_toward(radar_heading, desired_radar_degree)
    puts "current radar = #{radar_heading}, target radar = #{@target.inspect}, needed turn = #{radar_turn}"
    radar_turn = [[(0 - (@desired_gun_turn + @desired_turn)) + radar_turn, 60].min, -60].max
    puts "clamped radar turn = #{radar_turn}"
    @turning_to_partner_target = !(rotate(radar_heading, radar_turn) == desired_radar_degree)
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
    new_radar = rotate(current_radar, @radar_direction * @radar_size)
    friend_direction = degree_from_point_to_point(my_location, @partner_location)
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
        friend_direction = degree_from_point_to_point(my_location, @partner_location)
        friend_distance = distance_between_objects(my_location, @partner_location)
        friend = radar_heading_between?(friend_direction, @old_radar_heading, radar_heading, @radar_direction) && (friend_distance - distance).abs < 32
      end
      puts "friend? #{friend}: #{@partner_location.inspect}"
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
    angle = rotate(@old_radar_heading, @radar_direction * (angle/2))
    a = (Math.sin(angle * Math::PI/180) * distance.to_f)
    b = (Math.cos(angle * Math::PI/180) * distance.to_f)
    Point.new(x + b, y - a)
  end

  def dodge(degree)
    return degree + 40 if @dominant
    return degree - 40
  end

  def driver_turn_toward_target
    turn_toward_heading dodge(degree_from_point_to_point(my_location, target))
  end

  def driver_turn_away_from_target
    turn_toward_heading dodge(rotate(degree_from_point_to_point(my_location, target),180))
  end

  def circle_target
    turn_toward_heading rotate(degree_from_point_to_point(my_location, target),90)
  end

  def turn_toward_heading desired_heading
    desired_turn = turn_toward heading, desired_heading
    @desired_turn = [[desired_turn,-10].max,10].min
  end

  SHORTEST_POSSIBLE_TURNS = -180..180
  WHOLE_TURN = 360

  def turn_toward current_heading, desired_heading
    proposed_turn = desired_heading - current_heading
    case
      when SHORTEST_POSSIBLE_TURNS.include?(proposed_turn) then proposed_turn
      when proposed_turn < SHORTEST_POSSIBLE_TURNS.min     then proposed_turn + WHOLE_TURN
      when proposed_turn > SHORTEST_POSSIBLE_TURNS.max     then proposed_turn - WHOLE_TURN
    end
  end

  def distance_between_objects object1, object2
    Math.hypot(object1.y - object2.y, object2.x - object1.x)
  end

  def degree_from_point_to_point point1, point2
    if (point1.y - point2.y) == 0 and (point2.x - point1.x) == 0
      return -1
    end
    Math.atan2(point1.y - point2.y, point2.x - point1.x) / Math::PI * 180 % 360
  end

  def rotate direction, degrees
    direction += degrees
    direction +=360 if direction < 0
    direction -= 360 if direction >= 360
    direction
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