class SpinnerTargeting
  def initialize spinnerBot
    @robot = spinnerBot
  end

  def process_radar_results detected_bots
    @robot.bot_detected = nil
    if @robot.suppress_radar
      @robot.suppress_radar = false
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
      if !@robot.partner_location.nil?
        friend_direction = SpinnerMath.degree_from_point_to_point(@robot.my_location, @robot.partner_location)
        friend_distance = SpinnerMath.distance_between_objects(@robot.my_location, @robot.partner_location)
        friend = radar_heading_between?(friend_direction, @robot.old_radar_heading, @robot.radar_heading, @robot.radar.radar_direction) && (friend_distance - distance).abs < 32
      end
      if !friend
        @robot.bot_detected = locate_target(distance)
        @robot.time_bot_detected = @robot.time
        @robot.target = @robot.bot_detected
      end
    end
  end

  def locate_target distance
    @robot.old_radar_heading ||= SpinnerMath.rotate(@robot.radar_heading, 0 - @robot.radar.radar_direction * @robot.radar.radar_size)
    angle = SpinnerMath.turn_toward(@robot.radar_heading, @robot.old_radar_heading)
    @robot.target_range = (angle/2).abs
    angle = SpinnerMath.rotate(@robot.old_radar_heading, @robot.radar.radar_direction * (angle/2))
    a = (Math.sin(angle * Math::PI/180) * distance.to_f)
    b = (Math.cos(angle * Math::PI/180) * distance.to_f)
    SpinnerBot::Point.new(@robot.x + b, @robot.y - a)
  end

  def radar_heading_between? heading, left_edge, right_edge, direction
    result = between_headings? heading, left_edge, right_edge
    return result if direction < 0
    !result
  end

  def between_headings? heading, left_edge, right_edge
    if right_edge > left_edge
      return !between_headings?(heading, right_edge, left_edge)
    end
    if left_edge > heading and heading > right_edge
      return true
    end
    false
  end

end