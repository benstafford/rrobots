require 'spinner_math'

class SpinnerDriver
  DISTANCE_BETWEEN_PARTNERS = 120
  MAINTAIN_DISTANCE = 300..400

  def drive speed, my_location, target, partner_location, dominant, heading
    @desired_turn = 0
    accelerate = 0
    accelerate = 1 if speed < 8
    distance_to_target = SpinnerMath.distance_between_objects(my_location, target)
    distance_to_partner =  partner_location.nil? ? 3200 : SpinnerMath.distance_between_objects(my_location, partner_location)
    direction_to_target = SpinnerMath.degree_from_point_to_point(my_location, target)
    case
      when distance_to_partner < DISTANCE_BETWEEN_PARTNERS && !dominant && speed > 0 then accelerate = -1
      when distance_to_target > MAINTAIN_DISTANCE.max then driver_turn_toward_target(direction_to_target, dominant, heading)
      when distance_to_target < MAINTAIN_DISTANCE.min then driver_turn_away_from_target(direction_to_target, dominant, heading)
      else circle_target(direction_to_target, heading)
    end
    return @desired_turn, accelerate
  end

 def driver_turn_toward_target direction_to_target, dominant, heading
    turn_toward_heading dodge(direction_to_target, dominant), heading
  end

  def driver_turn_away_from_target direction_to_target, dominant, heading
    turn_toward_heading dodge(SpinnerMath.rotate(direction_to_target,180), dominant), heading
  end

  def circle_target direction_to_target, heading
    turn_toward_heading SpinnerMath.rotate(direction_to_target,90), heading
  end

  def dodge degree, dominant
    return degree + 40 if dominant
    degree - 40
  end

  def turn_toward_heading desired_heading, heading
    desired_turn = SpinnerMath.turn_toward heading, desired_heading
    @desired_turn = [[desired_turn,-10].max,10].min
  end
end