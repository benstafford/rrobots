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
  
  def target(target)
#    if @current_target == nil
#      @current_target = Target.new(target_position(target), target.time)
#    else
#      @current_target.update(target_position(target), target.time)
#    end
#    @desired_target = @current_target.projected_target_position(@current_position, BULLET_SPEED)
    @desired_target = target_position(target)
    log "gunner.target #{target} #{@desired_target}\n"
  end

  def target_position(target)
    log "gunner.target_position #{target} #{target.origin} #{target.bisector} #{target.distance}\n"
    (target.origin + Vector[target.bisector, target.distance].to_cartesian)
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
