require 'robot'
require 'Matrix'
require 'Numeric'
require 'statemachine'

# NOTE: If you fail to load due to state machine, execute the following line in the ruby command prompt:
#
#                   gem install Statemachine

require 'PolarIce/Logging'
require 'PolarIce/Targets'
require 'PolarIce/Numeric'
require 'PolarIce/Vector'
require 'PolarIce/Sighting'
require 'PolarIce/Rotator'
require 'PolarIce/Driver'
require 'PolarIce/Gunner'
require 'PolarIce/Radar'
require 'PolarIce/Loader'
require 'PolarIce/Commander'
require 'PolarIce/Status'

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
    log_tick_info

    update_state
    store_current_status
    process_events(events) if events != nil
    fire_the_gun
    commander.tick
    move_the_bot
    turn_the_gun
    turn_the_radar
    perform_actions
    store_previous_status
  end

  def process_events(events)
    process_damage(events['got_hit'])
    process_intel(events['broadcasts'])
    process_radar(events['robot_scanned'])
  end

  def update_state
    @current_position = Vector[x,y]

    driver.update_state(current_position, heading, speed)
    gunner.update_state(current_position, gun_heading)
    radar.update_state(current_position, radar_heading)

    initialize_first_tick if !@initialized
  end

  def log_tick_info
    log "time #{time}: x=#{x} y=#{y} h=#{heading} g=#{gun_heading} r=#{radar_heading} s=#{speed}\n"
  end

  def initialize_first_tick
    @initialized = true
    initialize_state_machine
  end

  def process_damage(hits)
    if hits != nil
      log "process_damage #{hits[0]}\n"
      @last_hit_time = time
    end
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

  def process_partner_position_message(message_source, message_data)
    @current_partner_position[message_source] = decode_vector(message_data)
  end

  def process_partner_message(message)
    log "process_partner_message #{message}\n"
    message_string = message[0]
    message_type = message_string[0]
    message_source = message_string[1].to_i
    message_data = message_string[2..-1]

    if message_type == "P"
      process_partner_position_message(message_source, message_data)
      log "current_partner_position = #{@current_partner_position}\n"
    elsif message_type == "T"
#      gunner.desiredTarget = decode_vector(message_data)
    end
  end

  def determine_role(message_count)
    log "determine_role #{message_count}\n"
    if (message_count > 0)
      determine_role_from_messages(message_count)
    else
      determine_role_from_no_messages
    end
  end

  def determine_role_from_messages(message_count)
    if ((@role == :unknown) || (@role == :alone))
      case time
        when 1 then
          become_slave(message_count)
        when 2 then
          become_master(message_count)
      end
    end
  end

  def determine_role_from_no_messages
    if (time >= 2)
      if (@role != :alone)
        become_alone
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
    @broadcast_message = "P" + @id.to_s + @current_position.encode
  end

  def send_target_to_partner
    @broadcast_message = "T" + @id.to_s + gunner.desired_target.encode
  end

  def process_radar(robots_scanned)
    targets_scanned = Array.new
    if (robots_scanned != nil)
      robots_scanned.each do |target|
        targets_scanned << Sighting.new(@previous_status.radar_heading, radar_heading, target[0], radar.rotation.direction, current_position, time)
      end
    end
    radar.scanned targets_scanned
  end

  def move_the_bot
    driver.tick
    update_states_for_hull_movement
  end

  def update_states_for_hull_movement
    @current_position = driver.new_position
    rotation = driver.rotation
    gunner.update_state(@current_position, (gunner.current_heading + rotation) % 360)
    radar.update_state(@current_position, (radar.current_heading + rotation) % 360)
  end

  def turn_the_gun
    gunner.tick
    update_states_for_gun_movement
  end

  def update_states_for_gun_movement
    radar.current_heading = (radar.current_heading + gunner.rotation) % 360
  end

  def turn_the_radar
    radar.tick
  end

  def perform_actions
    log_actions
    turn driver.rotation
    accelerate driver.acceleration
    turn_gun gunner.rotation
    fire loader.power
    turn_radar radar.rotation
    broadcast @broadcast_message
    say @quote
  end

  def log_actions
    log "perform_actions #{time}: t=#{driver.rotation} g=#{gunner.rotation} r=#{radar.rotation} a=#{driver.acceleration} f=#{loader.power} b=#{@broadcast_message}\n"
  end

  def store_current_status
    @current_status = Status.new(@current_position, heading, gun_heading, radar_heading, speed)
  end

  def store_previous_status
    @previous_status = @current_status
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
    @current_status = Status.new(nil, 0, 0, 0, 0)
    @previous_status = Status.new(nil, 0, 0, 0, 0)
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
    @broadcast_message = INITIAL_BROADCAST_MESSAGE
    @quote = INITIAL_QUOTE
  end

  def initialize_role
    @role = :unknown
    @id = 0
  end

  def initialize_partner_communications
    @current_partner_position = Array.new
  end

  attr_reader(:current_position)

  attr_accessor(:commander)

  attr_accessor(:broadcast_message)

  attr_accessor(:quote)
  attr_accessor(:last_hit_time)

  attr_accessor(:current_status)
  attr_accessor(:previous_status)

  attr_accessor(:current_partner_position)

  attr_accessor(:role)
  attr_accessor(:id)
end
