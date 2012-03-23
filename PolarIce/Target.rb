# Target provides values for the movement of targets
class Target
  def initialize(position,time)
    log "target.initialize #{position} #{time}\n"
    @position = position
    initialize_velocity
    @heading = 0
    @time = time
  end

  def initialize_velocity
    log "target.initialize_velocity\n"
    @velocity = 0
    @velocity_vector = Vector[0, 0]
  end

  def update(position, time)
    elapsed_time = time - @time
    update_velocity(elapsed_time, position)
    @heading = @position.angle_to(position) if position != @position
    @position = position
    @time = time
    log "target.update #{position} #{time} ==> #{@position} #{@time} #{@heading} #{velocity} #{velocity_vector}\n"
  end

  def update_velocity(elapsed_time, position)
    @velocity = @position.distance_to(position) / elapsed_time
    if @velocity > 8
      initialize_velocity
    else
      @velocity_vector = @position.velocity_to(position, elapsed_time)
    end
  end

  def firing_angle(firing_position, muzzle_velocity)
    firing_position.angle_to(projected_target_position(firing_position, muzzle_velocity))
  end

  def projected_target_position(firing_position, muzzle_velocity)
    log "projected_target_position #{firing_position} #{muzzle_velocity} #{@position}\n"
    projected_position(impact_time(firing_position, muzzle_velocity))
  end

  def projected_position(time)
    log "projected_position #{time}\n"
    @position + @velocity_vector * time
  end

  def impact_time(firing_position, muzzle_velocity)
    log "impact_time #{firing_position} #{muzzle_velocity}\n"
    d = firing_position.vector_to(@position)
    (Math.sqrt(muzzle_velocity**2 * d.inner_product(d) - d.cross_product(@velocity_vector)**2) + d.inner_product(@velocity_vector)) /
        (muzzle_velocity**2 - @velocity_vector.inner_product(@velocity_vector))
  end

  attr_reader(:velocity_vector)
  attr_reader(:position)
  attr_reader(:velocity)
  attr_reader(:heading)
  attr_reader(:time)
end