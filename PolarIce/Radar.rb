#The Radar is responsible for turning the radar and processing its scans.
class Radar
  include Rotator

  T = 0
  R = 1

  MAXIMUM_ROTATION = 60
  INITIAL_ROTATION = 0
  INITIAL_DESIRED_HEADING = nil
  INITIAL_DESIRED_TARGET = nil

  def tick
    @state_machine.tick
    rotator_tick
  end

  def update_state(position, heading)
    @current_position = position
    @current_heading = heading
  end

  def initialize_state_machine
    radar = self
    @state_machine = Statemachine.build do
      context radar

      state :awaiting_orders do
        on_entry :awaiting_orders
        event :scan, :quick_scan, :start_quick_scan
        event :track, :rotate, :rotate_to_sector
        event :scanned, :awaiting_orders
        event :tick, :awaiting_orders
      end

      superstate :quick_scan do
        event :quick_scan_successful, :awaiting_orders
        event :quick_scan_failed, :awaiting_orders

        state :scanning do
          event :scanned, :sector_scanned, :add_targets
          event :tick, :scanning
        end

        state :sector_scanned do
          on_entry :count_sectors_scanned
          event :scan_incomplete, :scanning
        end
      end

      superstate :track do
        event :target_lost, :awaiting_orders

        state :rotate do
          event :tick, :wait_for_rotation
          event :scanned, :rotate
        end

        state :wait_for_rotation do
          on_entry :check_desired_heading
          event :arrived, :tracking, :start_track
          event :rotating, :rotate
        end

        state :tracking do
          event :scanned, :narrow_scan
          event :tick, :tracking
        end

        state :narrow_scan do
          on_entry :check_track_scan
          event :target_locked, :maintain_lock
          event :target_not_locked, :tracking
          event :tick, :narrow_scan
          event :scanned, :narrow_scan
        end

        state :maintain_lock do
          on_entry :maintain_lock
          event :tick, :maintain_lock
          event :scanned, :check_maintain_lock
        end

        state :check_maintain_lock do
          on_entry :check_maintain_lock
          event :target_locked, :maintain_lock
          event :target_not_locked, :broaden_scan
          event :tick, :check_maintain_lock
        end

        state :broaden_scan do
          on_entry :broaden_scan
          event :scanned, :check_broaden_scan
          event :tick, :broaden_scan
        end

        state :check_broaden_scan do
          on_entry :check_broaden_scan
          event :target_found, :tracking, :start_track
          event :target_locked, :maintain_lock
          event :target_not_found, :broaden_scan
          event :tick, :broaden_scan
        end
      end
    end
  end

  def awaiting_orders
    log "radar.awaiting_orders\n"
  end

  def log_tick
  end

  def scan
    log "radar.scan\n"
    @state_machine.scan
  end

  def start_quick_scan
    log "radar.start_quick_scan\n"
    @original_heading = @current_heading
    setup_scan
  end

  def setup_scan
    log "radar.setup_scan oH=#{@original_heading} cH=#{@current_heading}\n"
    @sectors_scanned = 0
    @current_target = nil
    @sightings.clear
    @desired_heading = (@current_heading + MAXIMUM_ROTATION).normalize_angle
  end

  def add_targets sightings
    log "radar.add_targets #{sightings}\n"
    @sightings += sightings if !sightings.empty?
  end

  def count_sectors_scanned
    @sectors_scanned += 1
    log "radar.count_sectors_scanned #{@sectors_scanned}\n"
    if @sectors_scanned < 6
      quick_scan_incomplete
    elsif !@sightings.empty?
      quick_scan_successful(@sightings)
    else
      quick_scan_failed
    end
  end

  def restore_original_heading
    log "radar.restore_original_heading #{@original_heading}\n"
    @desired_heading = @original_heading
  end

  def scanned(sightings)
    @state_machine.scanned(sightings)
  end

  def quick_scan_incomplete
    @desired_heading = (@current_heading + MAXIMUM_ROTATION).normalize_angle
    @state_machine.scan_incomplete
  end

  def quick_scan_failed
    log "radar.quick_scan_failed\n"
    @state_machine.quick_scan_failed
    polarIce.quick_scan_failed
  end

  def quick_scan_successful(sightings)
    log "radar.quick_scan_successful #{sightings}\n"
    @state_machine.quick_scan_successful
    polarIce.quick_scan_successful(sightings)
  end

  def track(sighting)
    log "radar.track #{sighting}\n"
    @state_machine.track(sighting)
  end

  def rotate_to_sector(sighting)
    log "radar.rotate_to_sector #{sighting}\n"
    @current_target = sighting
    @desired_heading = @current_position.angle_to(@current_target.start_point)
  end

  def check_desired_heading
    log "radar.check_desired_heading current #{@current_heading} desired #{@desired_heading}\n"
    if (@current_heading == @desired_heading)
      @desired_heading = nil
      @state_machine.arrived
    else
      @state_machine.rotating
    end
  end

  def start_track
    log "radar.start_track #{@current_target}\n"
    @desired_heading = @current_position.angle_to(@current_target.midpoint)
  end

  def remove_partners_from_sightings(sightings)
    log "commander.remove_partners_from_targets\n"
    polarIce.current_partner_position.each{|partner| remove_partner_from_sightings(partner, sightings) if partner != nil}
  end

  def check_track_scan(sightings)
    log "radar.check_track_scan #{sightings}\n"
    remove_partners_from_sightings(sightings) if polarIce.current_partner_position != nil
    if (sightings != nil) && (sightings.empty?)
      target_not_found(Sighting.new(polarIce.previous_status.radar_heading, current_heading, @current_target.distance, @rotation.direction, current_position, polarIce.time))
    else
      target_found(closest_target(sightings))
    end
  end

  def target_not_found(sighting)
    log "radar.target_not_found #{sighting} #{@current_target}\n"
    if (sighting.start_angle == @current_target.end_angle)
      end_angle = @current_position.angle_to(@current_target.start_point)
    else
      end_angle = @current_position.angle_to(@current_target.end_point)
    end

    @current_target = Sighting.new(end_angle, @current_position.angle_to(sighting.end_point), @current_target.distance, sighting.direction, @current_position, sighting.time)
    @desired_heading = @current_position.angle_to(@current_target.midpoint)
    log "#{@desired_heading} #{@current_heading}\n"
    check_target_locked(@current_target)
  end

  def target_found(sighting)
    log "radar.target_found new #{sighting}\n"
    @current_target = sighting
    @desired_heading = @current_position.angle_to(@current_target.midpoint)
    check_target_locked(sighting)
  end

  def check_target_locked(sighting)
    log "radar.check_target #{sighting} ==> "
    if target_in_locked_range(sighting)
      log "target_locked\n"
      target_locked(sighting)
    else
      log "target_not_locked\n"
      @state_machine.target_not_locked(sighting)
    end
  end

  def target_in_locked_range(sighting)
    sighting.arc_length <= polarIce.size
  end

  def maintain_lock(sighting)
    log "radar.maintain_lock\n"
    @desired_heading = @current_position.angle_to(sighting.start_point)
  end

  def check_maintain_lock(sightings)
    log "radar.check_maintain_lock #{sightings}\n"
    remove_partners_from_sightings(sightings) if (polarIce.current_partner_position != nil)
    if (sightings == nil) || (sightings.empty?)
      lock_target_not_found(Sighting.new(polarIce.previous_status.radar_heading, current_heading, @current_target.distance, @rotation.direction, current_position, polarIce.time))
    else
      lock_target_found(closest_target(sightings))
    end
  end

  def lock_target_found(sighting)
    log "radar.lock_target_found #{sighting}\n"
    @current_target = sighting
    @desired_heading = @current_position.angle_to(sighting.start_point)
    @polarIce.update_target(sighting)
    @state_machine.target_locked(sighting)
  end

  def lock_target_not_found(sighting)
    log "radar.lock_target_not_found #{sighting}\n"
    @current_target = sighting
    @state_machine.target_not_locked
#    polarIce.target_lost
  end

  def broaden_scan
    @current_target.broaden(10)
    log "radar.broaden_scan #{@current_target}\n"

    if (@current_target.central_angle < 60)
      @desired_heading = @current_position.angle_to(@current_target.start_point)
    else
      @state_machine.target_lost
      polarIce.target_lost
    end
  end

  def check_broaden_scan(sightings)
    log "radar.check_broaden_scan #{sightings}\n"
    remove_partners_from_sightings(sightings) if (polarIce.current_partner_position != nil)
    if (sightings != nil) && (sightings.empty?)
      broaden_scan_target_not_found(Sighting.new(polarIce.previous_status.radar_heading, current_heading, @current_target.distance, @rotation.direction, current_position, polarIce.time))
    else
      broaden_scan_target_found(closest_target(sightings))
    end
  end

  def broaden_scan_target_not_found(sighting)
    log "radar.broaden_scan_target_not_found #{sighting}\n"
    @current_target = sighting
    @state_machine.target_not_found
  end

  def broaden_scan_target_found(sighting)
    @current_target = sighting
    log "radar.broaden_scan_target_found #{sighting}\n"
    if (target_in_locked_range(sighting))
      target_locked(sighting)
    else
      target_not_locked(sighting)
    end
  end

  def target_locked(sighting)
    polarIce.update_target(sighting)
    @state_machine.target_locked(sighting)
  end

  def target_not_locked(sighting)
    polarIce.update_target(sighting)
    @state_machine.target_found(sighting)
  end

  def initialize(polarIce)
    @max_rotation = MAXIMUM_ROTATION
    @rotation = INITIAL_ROTATION
    @desired_heading = INITIAL_DESIRED_HEADING
    @desired_target = INITIAL_DESIRED_TARGET
    @polarIce = polarIce
    @sightings = Array.new
    initialize_state_machine
  end
  attr_accessor(:polarIce)
  attr_accessor(:sightings)
  attr_accessor(:quick_scan_results)
end

