class SpinnerGunner
  def initialize spinnerBot
    @robot = spinnerBot
  end

  def aim
    desired_gun_turn = SpinnerMath.turn_toward @robot.gun_heading, SpinnerMath.degree_from_point_to_point(@robot.my_location_next_turn, lead_the_shot)
    desired_gun_turn += Math.sin(@robot.time) * @robot.target_range
    desired_gun_turn = [[(0 - @robot.desired_turn) + desired_gun_turn,30].min, -30].max
    fire_strength = 0
    fire_strength = 0.1 #if !partner_in_line_of_fire?(desired_gun_turn)
    return desired_gun_turn, fire_strength
  end

  def partner_in_line_of_fire? desired_gun_turn
    return false if @robot.partner_location.nil?
    direction_to_partner = SpinnerMath::degree_from_point_to_point(@robot.my_location_next_turn, @robot.partner_location)
    direction_of_fire = SpinnerMath::rotate(@robot.gun_heading, desired_gun_turn)
    distance_between = SpinnerMath::turn_toward(direction_of_fire, direction_to_partner)
    return true if distance_between.abs <= 45
    false
  end

  def lead_the_shot
    current_location = @robot.target
    previous_location, previous_time = @robot.get_previous_bot_location 1
    return current_location if previous_time == 0
    current_location = get_average_location(current_location, previous_location)
    second_previous_location, previous_time = @robot.get_previous_bot_location 2
    return current_location if previous_time == 0
    previous_location = get_average_location(previous_location, second_previous_location)
    
    distance = SpinnerMath::distance_between_objects(previous_location, current_location)
    direction_of_travel = SpinnerMath::degree_from_point_to_point(previous_location, current_location)
    speed = distance/(@robot.time - previous_time)
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

  def get_average_location location1, location2
    average_x = (location1.x + location2.x)/2
    average_y = (location1.y + location2.y)/2
    SpinnerBot::Point.new(average_x.to_i, average_y.to_i)
  end

end