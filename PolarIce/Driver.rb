class Driver
  include Rotator

  MAXIMUM_ROTATION = 10

  INITIAL_ROTATION = 0
  INITIAL_DESIRED_HEADING = nil
  INITIAL_DESIRED_POSITION = nil

  MAXIMUM_SPEED = 8
  MAXIMUM_ACCELERATION = 1

  INITIAL_ACCELERATION_RATE = 0
  INITIAL_DESIRED_SPEED = 0
  INITIAL_DESIRED_MAXIMUM_SPEED = 8

  def tick
    @stateMachine.tick
  end

  def update_state(position, heading, speed)
    @currentPosition = position
    @currentHeading = heading
    @currentSpeed = speed
  end

  def initialize_state_machine
    driver = self
    @stateMachine = Statemachine.build do
      context driver

      state :awaiting_orders do
        on_entry :awaiting_orders
        event :tick, :awaiting_orders, :default_tick
        event :lock, :locked
        event :stop, :stop
      end

      state :stop do
        on_entry :do_stop
        event :tick, :wait_for_stop, :default_tick
      end

      state :wait_for_stop do
        on_entry :wait_for_stop
        event :stopped, :awaiting_orders
        event :stopping, :stop
      end

      state :locked do
        on_entry :locked
        event :tick, :locked, :locked_tick
        event :lock, :locked
        event :unlock, :awaiting_orders
      end
      
    end
  end

  def awaiting_orders
    log "driver.awaiting_orders\n"
  end

  def stop
    log "driver.stop\n"
    @stateMachine.stop
  end

  def do_stop
    log "driver.do_stop\n"
    @desiredSpeed = 0
    @desiredTarget = nil
    @stateMachine.tick
  end

  def wait_for_stop
    log "driver.wait_for_stop\n"
    if (@currentSpeed == 0)
      stopped
    else
      stopping
    end
  end

  def stopped
    log "driver.stopped\n"
    @stateMachine.stopped
    polarIce.stopped
  end

  def stopping
    log "driver.stopping\n"
    @stateMachine.stopping
  end

  def lock
    log "driver.lock\n"
    @stateMachine.lock
    @desiredSpeed = 0
  end

  def locked
    log "driver.locked\n"
  end

  def locked_tick
    rotator_tick
    accelerate if @currentSpeed != nil && @desiredSpeed != nil
    calculate_new_position
  end

  def unlock
    log "driver.unlock\n"
    @stateMachine.unlock
  end

  def default_tick
    rotator_tick
    move if @currentPosition != nil && @desiredTarget != nil
    accelerate if @currentSpeed != nil && @desiredSpeed != nil
    calculate_new_position
  end

  def move
    @desiredSpeed = calculate_desired_speed
  end

  def calculate_desired_speed
    Math.sqrt(currentPosition.distance_to(@desiredTarget)).floor.clamp(MAXIMUM_SPEED).clamp(@desiredMaximumSpeed)
  end

  def accelerate
    @acceleration = calculate_acceleration
  end

  def calculate_acceleration
    (@desiredSpeed - @currentSpeed).clamp(MAXIMUM_ACCELERATION)
  end

  def calculate_new_position
    newSpeed = @currentSpeed + @acceleration
    newHeading = @currentHeading + @rotation
    @newPosition = @currentPosition + Vector[newHeading, newSpeed].to_cartesian
  end

  def initialize polarIce
    @polarIce = polarIce
    @maximumRotation = MAXIMUM_ROTATION
    @acceleration = INITIAL_ACCELERATION_RATE
    @rotation = INITIAL_ROTATION
    @desiredHeading = INITIAL_DESIRED_HEADING
    @desiredTarget = INITIAL_DESIRED_POSITION
    @desiredSpeed = INITIAL_DESIRED_SPEED
    @desiredMaximumSpeed = INITIAL_DESIRED_MAXIMUM_SPEED
    initialize_state_machine
  end

  attr_accessor(:currentSpeed)
  attr_accessor(:desiredSpeed)
  attr_accessor(:desiredMaximumSpeed)
  attr_accessor(:acceleration)
  attr_accessor(:newPosition)
  attr_accessor(:polarIce)
end
module DriverAccessor
  def driverRotation
    driver.rotation
  end

  def desiredDriverTarget
    driver.desiredTarget
  end

  def desiredDriverTarget= target
    driver.desiredTarget = target
  end

  def desiredDriverHeading
    driver.desiredHeading
  end

  def desiredDriverHeading= heading
    driver.desiredHeading = heading
  end

  def desiredDriverSpeed
    driver.desiredSpeed
  end

  def desiredDriverSpeed= speed
    driver.desiredSpeed = speed
  end

  def desiredDriverMaximumSpeed= speed
    driver.desiredMaximumSpeed = speed
  end
  attr_accessor(:driver)
end
