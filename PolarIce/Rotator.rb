module Rotator
  def rotator_tick
    calculate_desired_heading if @desiredTarget != nil && @desiredTarget != @currentPosition
    turn if @currentHeading != nil && @desiredHeading != nil
  end

  def calculate_desired_heading
    @desiredHeading = @currentPosition.angle_to(@desiredTarget)
  end

  def turn
    @rotation = calculate_turn
  end

  def calculate_turn
    desiredTurn = @desiredHeading - @currentHeading
    if desiredTurn > 180
      -@maximumRotation
    elsif desiredTurn < -180
      @maximumRotation
    else
      desiredTurn.clamp(@maximumRotation)
    end
  end

  attr_accessor(:maximumRotation)

  attr_accessor(:currentPosition)
  attr_accessor(:currentHeading)

  attr_accessor(:desiredTarget)
  attr_accessor(:desiredHeading)

  attr_accessor(:rotation)
end
