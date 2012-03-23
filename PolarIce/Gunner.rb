#The Gunner is responsible for turning the Gun.
class Gunner
  include Rotator

  T = 0
  R = 1

  MAXIMUM_ROTATION = 30
  INITIAL_ROTATION = 0
  INITIAL_DESIRED_HEADING = nil
  INITIAL_DESIRED_TARGET = nil

  BULLET_SPEED = 30

  def tick
    rotator_tick
  end

  def clear_target
    @current_target = nil
  end
  
  def target(sighting)
    if @current_target == nil
      @current_target = Target.new(sighting.midpoint, sighting.time)
    else
      @current_target.update(sighting.midpoint, sighting.time)
    end
    @desired_target = @current_target.projected_target_position(@current_position, BULLET_SPEED)
    @desired_target = sighting.midpoint
    log "gunner.sighting #{sighting} #{@desired_target}\n"
  end

  def initialize(polarIce)
    @polarIce = polarIce
    @max_rotation = MAXIMUM_ROTATION
    @rotation = INITIAL_ROTATION
    @desired_heading = INITIAL_DESIRED_HEADING
    @desired_target = Target.new(INITIAL_DESIRED_TARGET, 0) if INITIAL_DESIRED_TARGET != nil
    @current_target = nil
  end

  def update_state(position, heading)
    @current_position = position
    @current_heading = heading
  end

  attr_accessor(:polarIce)
end
