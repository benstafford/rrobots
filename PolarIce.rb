require 'robot'
require 'Matrix'
require 'Numeric'
require 'statemachine'
# NOTE: If you fail to load due to state machine, execute the following line in the ruby command prompt:
#
#                   gem install Statemachine

class Numeric
  def clamp(maximum)
    [[-maximum, self].max, maximum].min
  end

  def trim(decimal_places)
    if decimal_places > 0
      (self * 10**decimal_places).round.to_f / 10**decimal_places
    else
      self.round.to_f
    end
  end
end

class Vector
  X = 0
  Y = 1

  T = 0
  R = 1

  def angle_to(position)
    (Math.atan2(self[Y] - position[Y], position[X] - self[X]).to_deg % 360).trim(3)
  end

  def distance_to(desiredTarget)
    Math.hypot(desiredTarget[X] - self[X], desiredTarget[Y] - self[Y])
  end

  def to_cartesian
    Vector[(self[R] * Math.cos(self[T] * Math::PI/180)).trim(3), (-self[R] * Math.sin(self[T] * Math::PI/180)).trim(3)]
  end
end

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

class Driver
  include Rotator

  MAXIMUM_ROTATION = 10

  INITIAL_ROTATION = 0
  INITIAL_DESIRED_HEADING = nil
  INITIAL_DESIRED_POSITION = nil

  MAXIMUM_SPEED = 8
  MAXIMUM_ACCELERATION = 1

  INITIAL_ACCELERATION_RATE = 0
  INITIAL_DESIRED_SPEED = nil
  INITIAL_DESIRED_MAXIMUM_SPEED = 8

  def tick
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

  def initialize
    @maximumRotation = MAXIMUM_ROTATION
    @acceleration = INITIAL_ACCELERATION_RATE
    @rotation = INITIAL_ROTATION
    @desiredHeading = INITIAL_DESIRED_HEADING
    @desiredTarget = INITIAL_DESIRED_POSITION
    @desiredSpeed = INITIAL_DESIRED_SPEED
    @desiredMaximumSpeed = INITIAL_DESIRED_MAXIMUM_SPEED
  end

  attr_accessor(:currentSpeed)
  attr_accessor(:desiredSpeed)
  attr_accessor(:desiredMaximumSpeed)
  attr_accessor(:acceleration)
  attr_accessor(:newPosition)
end
module DriverAccessor
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

class Gunner
  include Rotator

  MAXIMUM_ROTATION = 30
  INITIAL_ROTATION = 0
  INITIAL_DESIRED_HEADING = nil
  INITIAL_DESIRED_TARGET = nil

  def tick
    rotator_tick
  end

  def initialize
    @maximumRotation = MAXIMUM_ROTATION
    @rotation = INITIAL_ROTATION
    @desiredHeading = INITIAL_DESIRED_HEADING
    @desiredTarget = INITIAL_DESIRED_TARGET
  end
end
module GunnerAccessor
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

class Radar
  include Rotator

  MAXIMUM_ROTATION = 60
  INITIAL_ROTATION = 0
  INITIAL_DESIRED_HEADING = nil
  INITIAL_DESIRED_TARGET = nil

  def tick
    rotator_tick
  end

  def initialize_state_machine
    radar = self
    @stateMachine = Statemachine.build do
      state :awaiting_orders do
        event :scan, :quick_scan, :start_quick_scan
        event :scanned, :awaiting_orders
      end
      state :quick_scan do
        event :scanned, :sector_scanned, :add_targets
      end
      state :sector_scanned do
        on_entry :count_sectors_scanned
        event :scan_incomplete, :quick_scan
        event :found_targets, :awaiting_orders, :quick_scan_successful
        event :no_targets, :awaiting_orders, :quick_scan_failed
        event :scan, :quick_scan, :start_quick_scan
      end
      context radar
    end
  end

  def scan
    @stateMachine.scan
  end

  def start_quick_scan
    @originalHeading = polarIce.radar_heading
    @sectorsScanned = 0
    setup_scan
  end

  def setup_scan
    @rotation = 60
  end

  def add_targets targets_scanned
    @targets += targets_scanned
  end

  def count_sectors_scanned
    @sectorsScanned += 1
    if @sectorsScanned < 6
      @stateMachine.scan_incomplete
    elsif @targets.empty?
      @stateMachine.no_targets
    else
      @stateMachine.found_targets(@targets)
    end
  end

  def restore_original_heading
    @desiredHeading = @originalHeading
  end

  def scanned(targets_scanned)
    @stateMachine.scanned(targets_scanned)
  end

  def quick_scan_failed
    polarIce.quick_scan_failed
  end

  def quick_scan_successful(targets)
    polarIce.quick_scan_successful(targets)
  end
  
  def initialize(polarIce)
    @maximumRotation = MAXIMUM_ROTATION
    @rotation = INITIAL_ROTATION
    @desiredHeading = INITIAL_DESIRED_HEADING
    @desiredTarget = INITIAL_DESIRED_TARGET
    @polarIce = polarIce
    @targets = Array.new
    initialize_state_machine
  end
  attr_accessor(:polarIce)
  attr_accessor(:targets)
end
module RadarAccessor
  def desiredRadarTarget= target
    radar.desiredTarget = target
  end

  def desiredRadarHeading
    radar.desiredHeading
  end
  def desiredRadarHeading= heading
    radar.desiredHeading = heading
  end
  attr_accessor(:radar)
end

class Loader
  def tick
  end

  MINIMUM_FIRE_POWER = 0.0
  MAXIMUM_FIRE_POWER = 3.0

  INITIAL_FIRE_POWER = 0.1

  def initialize
    @power = INITIAL_FIRE_POWER
  end

  attr_accessor(:power)
end
module LoaderAccessor
  def desiredLoaderPower
    loader.power
  end

  def desiredLoaderPower= power
    loader.power = power
  end
  attr_accessor(:loader)
end

class Commander
  X = 0
  Y = 1

  T = 0
  R = 1

  def initialize_state_machine
    commander = self
    @stateMachine = Statemachine.build do
      state :initializing do
        event :scan, :quick_scan, :start_quick_scan
      end
      state :quick_scan do
        event :quick_scan_successful, :seek, :add_targets
        event :quick_scan_failed, :quick_scan, :start_quick_scan
      end
      state :seek do
        on_entry :start_seeking
      end
      context commander
    end
  end

  def scan
    @stateMachine.scan
  end
  
  def start_quick_scan
    @originalHeading = polarIce.heading
    @sectorsScanned = 0
    polarIce.start_quick_scan
  end

  def quick_scan_failed
    @stateMachine.quick_scan_failed
  end

  def quick_scan_successful(targets)
    @stateMachine.quick_scan_successful(targets)
  end

  def add_targets targets_scanned
    @targets += targets_scanned
  end

  def start_seeking
    polarIce.radar.desiredHeading = closest_target[0][T]
    polarIce.gunner.desiredHeading = polarIce.radar.desiredHeading

    @quote = "#{closest_target}"
  end

  def closest_target
    closest = @targets[0]
    @targets.each {|target| closest = target if target[0][R] < closest[0][R] }
    closest
  end

  def initialize(polarIce)
    @targets = Array.new
    @polarIce = polarIce
    initialize_state_machine
  end

  attr_accessor(:polarIce)
end

class PolarIce
  include Robot
  include DriverAccessor
  include GunnerAccessor
  include RadarAccessor
  include LoaderAccessor
  
  CENTER_POSITION = Vector[800,800]

  INITIAL_BROADCAST_MESSAGE = ""
  INITIAL_QUOTE = ""

  def tick events
    update_state
    if events != nil
      process_damage(events['got_hit']) if !events['got_hit'].empty?
      process_intel
      process_radar(events['robot_scanned'])
    end
    fire_the_gun
    move_the_bot
    turn_the_gun
    turn_the_radar
    perform_actions
    store_previous_status
  end

  def update_state
    if !@initialized
      initialize_first_tick
    end

    @currentPosition = Vector[x,y]
    update_driver_state
    update_gunner_state
    update_radar_state
  end

  def initialize_first_tick
    @initialized = true
    initialize_state_machine
  end

  def update_driver_state
    driver.currentPosition = currentPosition
    driver.currentHeading = heading
    driver.currentSpeed = speed
  end

  def update_gunner_state
    gunner.currentPosition = currentPosition
    gunner.currentHeading = gun_heading
  end

  def update_radar_state
    radar.currentPosition = currentPosition
    radar.currentHeading = radar_heading
  end

  def process_damage(hits)
    @lastHitTime = time
  end

  def initialize_state_machine
    @commander.scan
  end

  def fire_the_gun
    loader.tick
  end

  def process_intel
  end

  def process_radar(robots_scanned)
    targets_scanned = Array.new
    robots_scanned.each do |target|
      targets_scanned << [Vector[scan_midpoint, target[0]], scan_angle, time]
    end
    radar.scanned targets_scanned
  end

  def scan_angle
    (radar.currentHeading - @previousRadarHeading + 360) % 360
  end

  def scan_midpoint
    (@previousRadarHeading + scan_angle / 2) % 360
  end

  def move_the_bot
    driver.tick
    update_states_for_hull_movement
  end

  def update_states_for_hull_movement
    @previousPosition = currentPosition
    @currentPosition = driver.newPosition
    gunner.currentPosition = @currentPosition
    gunner.currentHeading = (gunner.currentHeading + driver.rotation) % 360
    radar.currentPosition = @currentPosition
    radar.currentHeading = (radar.currentHeading + driver.rotation) % 360
  end

  def turn_the_gun
    gunner.tick
    update_states_for_gun_movement
  end

  def update_states_for_gun_movement
    radar.currentHeading = (radar.currentHeading + gunner.rotation) % 360
  end

  def turn_the_radar
    radar.tick
  end

  def perform_actions
    turn driver.rotation
    accelerate driver.acceleration
    turn_gun gunner.rotation
    fire loader.power
    turn_radar radar.rotation
    broadcast @broadcastMessage
    say @quote
  end

  def store_previous_status
    @previousHeading = heading
    @previousGunHeading = gun_heading
    @previousRadarHeading = radar_heading
    @previousSpeed = speed
  end

  def start_quick_scan
    radar.scan
  end

  def quick_scan_failed
    commander.quick_scan_failed
  end

  def quick_scan_successful(targets)
    commander.quick_scan_successful(targets)
  end

  def initialize
    initialize_crew
    initialize_basic_operations
  end

  def initialize_crew
    @driver = Driver.new
    @loader = Loader.new
    @gunner = Gunner.new
    @radar = Radar.new(self)
    @commander = Commander.new(self)
  end

  def initialize_basic_operations
    @broadcastMessage = INITIAL_BROADCAST_MESSAGE
    @quote = INITIAL_QUOTE
  end

  attr_reader(:currentPosition)

  attr_accessor(:commander)
  
  attr_accessor(:broadcastMessage)

  attr_accessor(:quote)
  attr_accessor(:lastHitTime)

  attr_accessor(:previousRadarHeading)
end
