require 'robot'
require 'Matrix'
require 'Numeric'

class PolarIce
  include Robot

  X = 0
  Y = 1

  MAXIMUM_HULL_TURN = 10
  MAXIMUM_GUN_TURN = 30
  MAXIMUM_RADAR_TURN = 60

  INITIAL_DESIRED_HEADING = nil
  INITIAL_DESIRED_GUN_HEADING = nil
  INITIAL_DESIRED_RADAR_HEADING = nil

  INITIAL_DESIRED_POSITION = nil
  INITIAL_DESIRED_GUN_TARGET = nil
  INITIAL_DESIRED_RADAR_TARGET = nil

  INITIAL_DESIRED_SPEED = nil

  def tick events
    initialize_tick
    determine_desired_headings_from_positions
    turn_toward_desired_headings
    accerate_to_desired_speed
    perform_actions
    store_previous_status
  end

  def initialize_tick
    @currentPosition = Vector[x,y]
  end

  def turn_toward_desired_headings
    turn_toward desiredHeading if desiredHeading != nil && heading != nil
    turn_gun_toward desiredGunHeading if desiredGunHeading != nil && gun_heading != nil
    turn_radar_toward desiredRadarHeading if desiredRadarHeading != nil && radar_heading != nil
  end

  def turn_toward desiredHeading
    @hullRotation = calculate_turn(desiredHeading, heading, MAXIMUM_HULL_TURN, 0)
  end

  def turn_gun_toward desiredGunHeading
    @gunRotation = calculate_turn(desiredGunHeading, gun_heading, MAXIMUM_GUN_TURN, @hullRotation)
  end

  def turn_radar_toward desiredRadarHeading
    @radarRotation = calculate_turn(desiredRadarHeading, radar_heading, MAXIMUM_RADAR_TURN, @hullRotation + @gunRotation)
  end

  def calculate_turn(desiredHeading, currentHeading, maximumTurn, offset)
    desiredTurn = desiredHeading - currentHeading - offset
    if desiredTurn > 180
      -maximumTurn
    elsif desiredTurn < -180
      maximumTurn
    else
      [[-maximumTurn, desiredTurn].max, maximumTurn].min
    end
  end

  def determine_desired_headings_from_positions
    @desiredHeading = angle_to(desiredPosition) if desiredPosition != nil && desiredPosition != currentPosition
    @desiredGunHeading = angle_to(desiredGunTarget) if desiredGunTarget != nil && desiredGunTarget != currentPosition
    @desiredRadarHeading = angle_to(desiredRadarTarget) if desiredRadarTarget != nil && desiredRadarTarget != currentPosition
  end

  def angle_to(position)
    Math.atan2(currentPosition[Y] - position[Y], position[X] - currentPosition[X]).to_deg % 360
  end

  def perform_actions
    turn @hullRotation
    turn_gun @gunRotation
    turn_radar @radarRotation
    accelerate @accelerationRate
    fire @firePower
    broadcast @broadcastMessage
    say @quote
  end

  def store_previous_status
    @previousPosition = currentPosition
    @previousHeading = heading
    @previousGunHeading = gun_heading
    @previousRadarHeading = radar_heading
    @previousSpeed = speed
  end

  def initialize
    @accelerationRate = 0
    @hullRotation = 0
    @gunRotation = 0
    @radarRotation = 0
    @firePower = 0.1
    @broadcastMessage = ""
    @quote = ""

    @desiredHeading = INITIAL_DESIRED_HEADING
    @desiredGunHeading = INITIAL_DESIRED_GUN_HEADING
    @desiredRadarHeading = INITIAL_DESIRED_RADAR_HEADING

    @desiredPosition = INITIAL_DESIRED_POSITION
    @desiredGunTarget = INITIAL_DESIRED_GUN_TARGET
    @desiredRadarTarget = INITIAL_DESIRED_RADAR_TARGET

    @desiredSpeed = INITIAL_DESIRED_SPEED
  end

  attr_reader(:currentPosition)

  attr_accessor(:accelerationRate)
  attr_accessor(:hullRotation)
  attr_accessor(:gunRotation)
  attr_accessor(:radarRotation)
  attr_accessor(:firePower)
  attr_accessor(:broadcastMessage)
  attr_accessor(:quote)

  attr_accessor(:desiredHeading)
  attr_accessor(:desiredGunHeading)
  attr_accessor(:desiredRadarHeading)

  attr_accessor(:desiredPosition)
  attr_accessor(:desiredGunTarget)
  attr_accessor(:desiredRadarTarget)

  attr_accessor(:desiredSpeed)

  attr_reader(:previousPosition)
  attr_reader(:previousHeading)
  attr_reader(:previousGunHeading)
  attr_reader(:previousRadarHeading)
  attr_reader(:previousSpeed)

end
