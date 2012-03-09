class SpinnerGunner
  def initialize spinner_bot
    @robot = spinner_bot
  end

  def aim
    desired_gun_turn = SpinnerMath.turn_toward @robot.gun_heading, SpinnerMath.degree_from_point_to_point(@robot.my_location_next_turn, @robot.target)
    desired_gun_turn += Math.sin(@robot.time) * @robot.target_range
    desired_gun_turn = [[(0 - @robot.desired_turn) + desired_gun_turn,30].min, -30].max
    fire_strength = 2.8
    return desired_gun_turn, fire_strength
  end
end