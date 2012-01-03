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
    @desiredTarget = target.origin + Vector[target.bisector,target.distance].to_cartesian
    log "gunner.target #{target} #{@desiredTarget}\n"
  end

  def aim_at_position position
    @desiredTarget = position
  end

  def initialize(polarIce)
    @polarIce = polarIce
    @maximumRotation = MAXIMUM_ROTATION
    @rotation = INITIAL_ROTATION
    @desiredHeading = INITIAL_DESIRED_HEADING
    @desiredTarget = INITIAL_DESIRED_TARGET
  end
  attr_accessor(:polarIce)
end
module GunnerAccessor
  def gunnerRotation
    gunner.rotation
  end

  def desiredGunnerTarget= target
    gunner.desiredTarget = target
  end

  def desiredGunnerHeading
    gunner.desiredHeading
  end

  def desiredGunnerHeading= heading
    gunner.desiredHeading = heading
  end
  attr_accessor(:gunner)
end
