module Rotator
  def rotator_tick
    calculate_desired_heading if @desired_target != nil && @desired_target != @current_position
    turn if @current_heading != nil && @desired_heading != nil
  end

  def calculate_desired_heading
    @desired_heading = @current_position.angle_to(@desired_target)
  end

  def turn
    @rotation = calculate_turn
  end

  def calculate_turn
    desired_turn = @desired_heading - @current_heading
    if desired_turn > 180
      -@max_rotation
    elsif desired_turn < -180
      @max_rotation
    else
      desired_turn.clamp(@max_rotation)
    end
  end

  attr_accessor(:max_rotation)

  attr_accessor(:current_position)
  attr_accessor(:current_heading)

  attr_accessor(:desired_target)
  attr_accessor(:desired_heading)

  attr_accessor(:rotation)
end
