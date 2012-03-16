require 'spinner_math'

class SpinnerDriver
  DISTANCE_BETWEEN_PARTNERS = 180
  MAINTAIN_DISTANCE = 300..400
  EVASION_TIME = 8
  
  def initialize spinner_bot
    @robot = spinner_bot
  end

  def drive 
    @desired_turn = 0
    accelerate = 0
    accelerate = 1 if @robot.speed < 8
    distance_to_target = SpinnerMath.distance_between_objects(@robot.my_location, @robot.target)
    direction_to_target = SpinnerMath.degree_from_point_to_point(@robot.my_location, @robot.target)
    case
      when in_partners_path then drive_out_of_partner_path
      when distance_to_target > MAINTAIN_DISTANCE.max then driver_turn_toward_target(direction_to_target)
      when distance_to_target < MAINTAIN_DISTANCE.min then driver_turn_away_from_target(direction_to_target)
      when recently_hit? then evade
      else circle_target(direction_to_target)
    end
    return @desired_turn, accelerate
  end

  def in_partners_path
    return false if @robot.dominant
    return false if @robot.partner_location.nil?
    return false if @robot.partner_target.nil?
    distance_to_partner_path = SpinnerMath.distance_from_point_to_line(@robot.my_location, @robot.partner_location, @robot.partner_target)
    return distance_to_partner_path < DISTANCE_BETWEEN_PARTNERS
  end

  def recently_hit?
    @robot.time - @robot.last_hit < EVASION_TIME
  end

  def evade
    direction_to_target = SpinnerMath.degree_from_point_to_point(@robot.my_location, @robot.target)
    driver_turn_toward_target(direction_to_target)
  end

  def drive_out_of_partner_path
    direction_of_line = SpinnerMath.degree_from_point_to_point(@robot.partner_location, @robot.partner_target)
    direction_from_point1_to_point_off_line = SpinnerMath.degree_from_point_to_point(@robot.partner_location, @robot.my_location)
    theta = SpinnerMath.turn_toward(direction_of_line, direction_from_point1_to_point_off_line)
    rotation = theta > 0 ? 90 : -90
    desired_direction = SpinnerMath.rotate(direction_of_line, rotation)
    turn_toward_heading desired_direction
  end

  def driver_turn_toward_target direction_to_target
    turn_toward_heading dodge(direction_to_target)
  end

  def driver_turn_away_from_target direction_to_target
    turn_toward_heading dodge(SpinnerMath.rotate(direction_to_target,180))
  end

  def circle_target direction_to_target
    turn_toward_heading SpinnerMath.rotate(direction_to_target,90)
  end

  def dodge degree
    #degree
    return degree + 40 if @robot.dominant
    degree - 40
  end

  def turn_toward_heading desired_heading
    desired_turn = SpinnerMath.turn_toward @robot.heading, desired_heading
    @desired_turn = [[desired_turn,-10].max,10].min
  end
end