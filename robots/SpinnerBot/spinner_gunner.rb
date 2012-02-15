class SpinnerGunner
  def aim desired_turn, gun_heading, my_location, target, target_range, time
    desired_gun_turn = SpinnerMath.turn_toward gun_heading, SpinnerMath.degree_from_point_to_point(my_location, target)
    desired_gun_turn += Math.sin(time) * target_range
    desired_gun_turn = [[(0 - desired_turn) + desired_gun_turn,30].min, -30].max
    return desired_gun_turn, 0.1
    #turn_gun @desired_gun_turn
    #fire 3.0 if !@bot_detected.nil? && (gun_heat == 0) && @radar_size == RADAR_SCAN_SIZE.min
    #fire 3.0
  end
end