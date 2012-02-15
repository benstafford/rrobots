class SpinnerRadar
  RADAR_SCAN_SIZE = 3..48
  attr_reader :radar_direction
  attr_accessor :radar_size
  
  def initialize spinnerBot
    @robot = spinnerBot
    @turning_to_partner_target = false
    @radar_direction = 1
    @radar_size = 60
  end

  def sweep_radar
    case
      when partner_has_provided_close_target? then scan_over_partner_target
      when partner_has_provided_a_distant_target? then return point_radar_to_partner_target
      when @turning_to_partner_target then return point_radar_to_partner_target
      when !@robot.bot_detected.nil? then reverse_and_narrow_radar_direction
      when lost_target? then reverse_and_expand_direction
    end
    @radar_size = [[@radar_size, RADAR_SCAN_SIZE.min ].max, RADAR_SCAN_SIZE.max].min
    radar_turn = (@radar_direction * @radar_size)
    radar_turn = drag_right(radar_turn)
    radar_turn = [[(0 - (@robot.desired_gun_turn + @robot.desired_turn)) + radar_turn, 60].min, -60].max
    radar_turn
  end

  def scan_over_partner_target
    @radar_size = RADAR_SCAN_SIZE.min
    desired_radar_degree = SpinnerMath.degree_from_point_to_point(@robot.my_location_next_turn, @robot.target)
    radar_turn = SpinnerMath.turn_toward(@robot.radar_heading, desired_radar_degree)
    @radar_direction = [[radar_turn,1].min,-1].max
  end

  def partner_has_provided_close_target?
    return false if @robot.dominant
    return false if @robot.partner_target.nil?
    desired_radar_degree = SpinnerMath.degree_from_point_to_point(@robot.my_location_next_turn, @robot.target)
    radar_turn = SpinnerMath.turn_toward(@robot.radar_heading, desired_radar_degree)
    return true if radar_turn.abs < 5
    false
  end

  def partner_has_provided_a_distant_target?
    return false if @robot.dominant
    return false if @robot.partner_target.nil?
    desired_radar_degree = SpinnerMath.degree_from_point_to_point(@robot.my_location_next_turn, @robot.target)
    radar_turn = SpinnerMath.turn_toward(@robot.radar_heading, desired_radar_degree)
    return false if radar_turn.abs < 3
    true
  end

  def point_radar_to_partner_target
    @radar_size = RADAR_SCAN_SIZE.min
    @robot.time_bot_detected = @robot.time
    @robot.suppress_radar = true
    desired_radar_degree = SpinnerMath.degree_from_point_to_point(@robot.my_location_next_turn, @robot.target)
    radar_turn = SpinnerMath.turn_toward(@robot.radar_heading, desired_radar_degree)
    if radar_turn > 0
      @radar_direction = 1
      desired_radar_degree = SpinnerMath.rotate(desired_radar_degree, -2)
    else
      @radar_direction = -1
      desired_radar_degree = SpinnerMath.rotate(desired_radar_degree, 2)
    end
    radar_turn = SpinnerMath.turn_toward(@robot.radar_heading, desired_radar_degree)
    radar_turn = [[(0 - (@robot.desired_gun_turn + @robot.desired_turn)) + radar_turn, 60].min, -60].max
    @turning_to_partner_target = !(SpinnerMath.rotate(@robot.radar_heading, radar_turn) == desired_radar_degree)
    radar_turn
  end

  def reverse_and_expand_direction
    @radar_size = @radar_size * 2  if @radar_size < RADAR_SCAN_SIZE.max
    reverse_radar_direction
  end

  def lost_target?
    return false if @robot.time_bot_detected.nil?
    time_since_detect = @robot.time - @robot.time_bot_detected
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
    return false if @robot.partner_location.nil?
    current_radar = @robot.radar_heading
    new_radar = SpinnerMath.rotate(current_radar, @radar_direction * @radar_size)
    friend_direction = SpinnerMath.degree_from_point_to_point(@robot.my_location, @partner_location)
    radar_heading_between?(friend_direction, current_radar, new_radar, @radar_direction)
  end

  def drag_right radar_turn
    radar_turn - 1
  end
end