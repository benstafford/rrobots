class SpinnerTargeting
  SERVANT_SCAN_TOLERANCE = 120
  def initialize spinner_bot
    @robot = spinner_bot
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
        bot = locate_target(distance)
        if @robot.dominant
          @robot.bot_detected = bot
          @robot.time_bot_detected = @robot.time
          @robot.log_detected_bot @robot.bot_detected, @robot.time if @robot.target_range <= 3
          @robot.target = lead_the_shot
        else
          distance_from_bot_to_target = 0
          distance_from_bot_to_target = SpinnerMath.distance_between_objects(bot, @robot.partner_target) unless @robot.partner_target.nil?
          if distance_from_bot_to_target < SERVANT_SCAN_TOLERANCE
            @robot.bot_detected = bot
            @robot.time_bot_detected = @robot.time
            @robot.log_detected_bot @robot.bot_detected, @robot.time if @robot.target_range <= 3
            @robot.target = lead_the_shot
          end
        end
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

  def get_enemy_location_and_speed
    current_location = @robot.bot_detected
    previous_location, previous_time = @robot.get_previous_bot_location 1
    return current_location, 90, 0 if previous_time == 0
    current_location = get_average_location(current_location, previous_location)
    second_previous_location, previous_time = @robot.get_previous_bot_location 2
    return current_location, 90, 0 if previous_time == 0
    previous_location = get_average_location(previous_location, second_previous_location)

    distance = SpinnerMath::distance_between_objects(previous_location, current_location)
    direction_of_travel = SpinnerMath::degree_from_point_to_point(previous_location, current_location)
    speed = distance/(@robot.time - previous_time)
    return current_location, direction_of_travel, speed
  end

  def get_average_location location1, location2
    average_x = (location1.x + location2.x)/2
    average_y = (location1.y + location2.y)/2
    SpinnerBot::Point.new(average_x.to_i, average_y.to_i)
  end

  def lead_the_shot
    current_location, direction_of_travel, speed = get_enemy_location_and_speed
    return current_location if speed == 0

    enemy_x_velocity = speed * Math.cos(direction_of_travel.to_rad)
    enemy_y_velocity = speed * Math.sin(direction_of_travel.to_rad)
    x_distance = (current_location.x - @robot.my_location_next_turn.x)
    y_distance = (current_location.y - @robot.my_location_next_turn.y)
    new_x = current_location.x
    new_y = current_location.y
    time = 1
    while ((x_distance/time + enemy_x_velocity).abs > 30 or (y_distance/time - enemy_y_velocity).abs > 30) and (time<100)
      time = time + 1
      new_x = new_x + enemy_x_velocity
      new_y = new_y - enemy_y_velocity
    end
    SpinnerBot::Point.new(new_x, new_y)
  end

end