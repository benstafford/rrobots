#The Gunner is responsible for turning the Gun.
class Gunner
  include Rotator

  T = 0
  R = 1

  MAXIMUM_ROTATION = 30
  INITIAL_ROTATION = 0
  INITIAL_DESIRED_HEADING = nil
  INITIAL_DESIRED_TARGET = nil

  def tick
    rotator_tick
  end

  def target(target)
    @desired_target = target.origin + Vector[target.bisector,target.distance].to_cartesian
    log "gunner.target #{target} #{@desired_target}\n"
  end

  def aim_at_position position
    @desired_target = position
  end

  def initialize(polarIce)
    @polarIce = polarIce
    @max_rotation = MAXIMUM_ROTATION
    @rotation = INITIAL_ROTATION
    @desired_heading = INITIAL_DESIRED_HEADING
    @desired_target = INITIAL_DESIRED_TARGET
  end

  def update_state(position, heading)
    @current_position = position
    @current_heading = heading
  end

  attr_accessor(:polarIce)
end
module GunnerAccessor
  def gunner_rotation
    gunner.rotation
  end

  def desired_gunner_target= target
    gunner.desired_target = target
  end

  def desired_gunner_heading
    gunner.desired_heading
  end

  def desired_gunner_heading= heading
    gunner.desired_heading = heading
  end
  attr_accessor(:gunner)
end
