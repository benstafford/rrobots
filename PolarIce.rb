require 'robot'
require 'Matrix'
require 'Numeric'
require 'statemachine'

# NOTE: If you fail to load due to state machine, execute the following line in the ruby command prompt:
#
#                   gem install Statemachine

require 'PolarIce/Logging'
require 'PolarIce/Numeric'
require 'PolarIce/Vector'
require 'PolarIce/Sighting'
require 'PolarIce/Rotator'
require 'PolarIce/Driver'
require 'PolarIce/Gunner'
require 'PolarIce/Radar'
require 'PolarIce/Loader'
require 'PolarIce/Commander'

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
    log ">>> ID = #{id} :TIME = #{time}\n"
    update_state
    if events != nil
      process_damage(events['got_hit']) if !events['got_hit'].empty?
      process_intel(events['broadcasts'])
      process_radar(events['robot_scanned'])
    end
    fire_the_gun
    commander.tick
    move_the_bot
    turn_the_gun
    turn_the_radar
    perform_actions
    store_previous_status
    log "<<< ID = #{id} : TIME = #{time}\n"
  end

  def update_state
    @currentPosition = Vector[x,y]

    log "time #{time}: pos=#{@currentPosition} h=#{heading} g=#{gun_heading} r=#{radar_heading} s=#{speed}\n"
    update_driver_state
    update_gunner_state
    update_radar_state

    if !@initialized
      initialize_first_tick
    end
  end

  def initialize_first_tick
    log "Position = #{@currentPosition}\n"
    log "Heading = #{radar_heading}\n"
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
    log "process_damage #{hits[0]}\n"
    @lastHitTime = time
  end

  def initialize_state_machine
    @commander.init
  end

  def fire_the_gun
    loader.tick
  end

  def process_intel(broadcasts)
    log "process_intel #{broadcasts}\n"
    process_partner_broadcasts(broadcasts)
    send_position_to_partner
  end

  def process_partner_broadcasts(broadcasts)
    log "process_partner_broadcasts #{broadcasts}\n"
    determine_role(broadcasts.count)
    broadcasts.each do |message|
      process_partner_message(message)
    end
  end

  def process_partner_message(message)
    log "process_partner_message #{message}\n"
    if message[0][0] == "P"
      @currentPartnerPosition[message[0][1].to_i] = decode_vector(message[0][2..-1])
      log "currentPartnerPosition = #{@currentPartnerPosition}\n"
    elsif message[0][0] == "T"
#      gunner.desiredTarget = decode_vector(message[0][2..-1])
    end
  end

  def decode_vector(message)
    message_x, message_y = message.split(',').map { |s| s.to_i(36).to_f/100 }
    Vector[message_x,message_y]
  end

  def determine_role(message_count)
    log "determine_role #{message_count}\n"
    if (message_count > 0)
      if ((@role == :unknown) || (@role == :alone))
        case time
          when 1 then become_slave(message_count)
          when 2 then become_master(message_count)
        end
      end
    else
      if (time >= 2)
        if (@role != :alone)
          become_alone
        end
      end
    end
  end

  def become_master(message_count)
    log "become_master\n"
    @role = :master
    @id = message_count + 1
    @quote = @id.to_s
    commander.become_master
  end

  def become_slave(message_count)
    log "become_slave\n"
    @role = :slave
    @id = message_count
    @quote = @id.to_s
    commander.become_slave
  end

  def become_alone
    log "become_alone\n"
    @role = :alone
    @id = 1
    @quote = @id.to_s
    commander.become_alone
  end

  def send_position_to_partner
    @broadcastMessage = "P" + @id.to_s + @currentPosition.encode
  end

  def send_target_to_partner
    @broadcastMessage = "T" + @id.to_s + gunner.desiredTarget.encode
  end

  def process_radar(robots_scanned)
    targets_scanned = Array.new
    if (robots_scanned != nil)
      robots_scanned.each do |target|
        targets_scanned << Sighting.new(@previousRadarHeading, radar_heading, target[0], radar.rotation.direction, currentPosition, time)
      end
    end
    radar.scanned targets_scanned
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
    log "perform_actions #{time}: t=#{driver.rotation} g=#{gunner.rotation} r=#{radar.rotation} a=#{driver.acceleration} f=#{loader.power} b=#{@broadcastMessage}\n"
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

  def stop
    driver.stop
  end

  def stopped
    commander.stopped
  end

  def start_quick_scan
    radar.scan
  end

  def quick_scan_successful(targets)
    commander.quick_scan_successful(targets)
  end

  def quick_scan_failed
    commander.quick_scan_failed
  end

  def target(target)
    log "polarIce.target #{target}\n"
    gunner.target(target)
    send_target_to_partner
  end

  def update_target(target)
    log "polarIce.update_target #{target}\n"
    commander.update_target(target)
  end

  def aim_at_position position
    gunner.aim_at_position position
  end

  def track(target)
    radar.track(target)
  end

  def target_lost
    commander.target_lost
  end

  def base_test
    commander.base_test
  end

  def lock
    driver.lock
  end

  def unlock
    driver.unlock
  end

  def initialize
    initialize_crew
    initialize_basic_operations
    initialize_role
    initialize_partner_communications
  end

  def initialize_crew
    @driver = Driver.new(self)
    @loader = Loader.new
    @gunner = Gunner.new(self)
    @radar = Radar.new(self)
    @commander = Commander.new(self)
  end

  def initialize_basic_operations
    @broadcastMessage = INITIAL_BROADCAST_MESSAGE
    @quote = INITIAL_QUOTE
  end

  def initialize_role
    @role = :unknown
    @id = 0
  end

  def initialize_partner_communications
    @currentPartnerPosition = Array.new
  end

  attr_reader(:currentPosition)

  attr_accessor(:commander)

  attr_accessor(:broadcastMessage)

  attr_accessor(:quote)
  attr_accessor(:lastHitTime)

  attr_accessor(:previousRadarHeading)
  attr_accessor(:previousPosition)

  attr_accessor(:currentPartnerPosition)

  attr_accessor(:role)
  attr_accessor(:id)
end
