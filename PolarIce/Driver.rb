#The Driver is responsible for turning and moving the tank.
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
    @state_machine.tick
  end

  def update_state(position, heading, speed)
    @current_position = position
    @current_heading = heading
    @current_speed = speed
  end

  def initialize_state_machine
    driver = self
    @state_machine = Statemachine.build do
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
    @desired_speed = 8
    @rotation = 10
  end

  def stop
    log "driver.stop\n"
    @state_machine.stop
  end

  def do_stop
    log "driver.do_stop\n"
    @desired_speed = 0
    @desired_target = nil
#    @state_machine.tick
  end

  def wait_for_stop
    log "driver.wait_for_stop\n"
    if (@current_speed == 0)
      stopped
    else
      stopping
    end
  end

  def stopped
    log "driver.stopped\n"
    @state_machine.stopped
    polarIce.stopped
  end

  def stopping
    log "driver.stopping\n"
    @state_machine.stopping
  end

  def lock
    log "driver.lock\n"
    @state_machine.lock
    @desired_speed = 0
  end

  def locked
    log "driver.locked\n"
  end

  def locked_tick
    rotator_tick
    accelerate if @current_speed != nil && @desired_speed != nil
    calculate_new_position
  end

  def unlock
    log "driver.unlock\n"
    @state_machine.unlock
  end

  def default_tick
    rotator_tick
    move if @current_position != nil && @desired_target != nil
    accelerate if @current_speed != nil && @desired_speed != nil
    calculate_new_position
  end

  def move
    @desired_speed = calculate_desired_speed
  end

  def calculate_desired_speed
    Math.sqrt(current_position.distance_to(@desired_target)).floor.clamp(MAXIMUM_SPEED).clamp(@desired_max_speed)
  end

  def accelerate
    @acceleration = calculate_acceleration
  end

  def calculate_acceleration
    (@desired_speed - @current_speed).clamp(MAXIMUM_ACCELERATION)
  end

  def calculate_new_position
    new_speed = @current_speed + @acceleration
    new_heading = @current_heading + @rotation
    @new_position = @current_position + Vector[new_heading, new_speed].to_cartesian
  end

  def initialize polarIce
    @polarIce = polarIce
    @max_rotation = MAXIMUM_ROTATION
    @acceleration = INITIAL_ACCELERATION_RATE
    @rotation = INITIAL_ROTATION
    @desired_heading = INITIAL_DESIRED_HEADING
    @desired_target = INITIAL_DESIRED_POSITION
    @desired_speed = INITIAL_DESIRED_SPEED
    @desired_max_speed = INITIAL_DESIRED_MAXIMUM_SPEED
    initialize_state_machine
  end

  attr_accessor(:current_speed)
  attr_accessor(:desired_speed)
  attr_accessor(:desired_max_speed)
  attr_accessor(:acceleration)
  attr_accessor(:new_position)
  attr_accessor(:polarIce)
end
