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

      state :quick_scan do
        event :scanned, :sector_scanned, :add_targets
        event :tick, :quick_scan
      end

      state :sector_scanned do
        on_entry :count_sectors_scanned
        event :scan_incomplete, :quick_scan
        event :quick_scan_successful, :awaiting_orders
        event :quick_scan_failed, :awaiting_orders
      end

      state :rotate do
        event :tick, :wait_for_rotation
        event :scanned, :rotate
      end

      state :wait_for_rotation do
        on_entry :check_desired_heading
        event :arrived, :track, :start_track
        event :rotating, :rotate
      end

      state :track do
        event :scanned, :narrow_scan
        event :tick, :track
      end
      
      state :narrow_scan do
        on_entry :check_track_scan
        event :target_locked, :maintain_lock
        event :target_not_locked, :track
        event :target_lost, :awaiting_orders
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
        event :target_lost, :awaiting_orders
        event :tick, :broaden_scan
      end
      
      state :check_broaden_scan do
        on_entry :check_broaden_scan
        event :target_found, :track, :start_track
        event :target_locked, :maintain_lock
        event :target_not_found, :broaden_scan
        event :tick, :broaden_scan
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
    @targets.clear
    @desired_heading = (@current_heading + MAXIMUM_ROTATION).normalize_angle
  end

  def add_targets targets_scanned
    log "radar.add_targets #{targets_scanned}\n"
    @targets += targets_scanned if !targets_scanned.empty?
  end

  def count_sectors_scanned
    @sectors_scanned += 1
    log "radar.count_sectors_scanned #{@sectors_scanned}\n"
    if @sectors_scanned < 6
      quick_scan_incomplete
    elsif !@targets.empty?
      quick_scan_successful(@targets)
    else
      quick_scan_failed
    end
  end

  def restore_original_heading
    log "radar.restore_original_heading #{@original_heading}\n"
    @desired_heading = @original_heading
  end

  def scanned(targets_scanned)
#    log "radar.scanned #{targets_scanned}\n"
    @state_machine.scanned(targets_scanned)
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

  def quick_scan_successful(targets)
    log "radar.quick_scan_successful #{targets}\n"
    @state_machine.quick_scan_successful
    polarIce.quick_scan_successful(targets)
  end

  def track(target)
    log "radar.track #{target}\n"
    @state_machine.track(target)
  end

  def rotate_to_sector(target)
    log "radar.rotate_to_sector #{target}\n"
    @current_target = target
    @desired_heading = @current_target.start_angle
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
    @desired_heading = @current_target.bisector
  end

  def remove_partners_from_targets(targets)
    log "commander.remove_partners_from_targets\n"
    polarIce.current_partner_position.each{|partner| remove_partner_from_targets(partner, targets) if partner != nil}
  end

  def check_track_scan(targets)
    log "radar.check_track_scan #{targets}\n"
    remove_partners_from_targets(targets) if polarIce.current_partner_position != nil
    if (targets != nil) && (targets.empty?)
      target_not_found(Sighting.new(polarIce.previous_status.radar_heading, current_heading, 0, @rotation.direction, current_position, polarIce.time))
    else
      target_found(closest_target(targets))
    end
  end

  def target_not_found(target)
    log "radar.target_not_found #{target}\n"
    if (target.start_angle == @current_target.end_angle)
      end_angle = @current_target.start_angle
    else
      end_angle = @current_target.end_angle
    end

    @current_target = Sighting.new(end_angle, target.end_angle, @current_target.distance, target.direction, current_position, target.time)
    @desired_heading = @current_target.bisector
    check_target_locked(@current_target)
  end

  def target_found(target)
    log "radar.target_found new #{target}\n"
    @current_target = target
    @desired_heading = @current_target.bisector
    check_target_locked(target)
  end

  def check_target_locked(target)
    log "radar.check_target #{target} ==> "
    if target_in_locked_range(target)
      log "target_locked\n"
      target_locked(target)
    else
      log "target_not_locked\n"
      @state_machine.target_not_locked(target)
    end
  end

  def target_in_locked_range(target)
    target.arc_length <= polarIce.size
  end

  def maintain_lock(target)
    log "radar.maintain_lock\n"
    @desired_heading = target.start_angle
  end

  def check_maintain_lock(targets)
    log "radar.check_maintain_lock #{targets}\n"
    remove_partners_from_targets(targets) if (polarIce.current_partner_position != nil)
    if (targets == nil) || (targets.empty?)
      lock_target_not_found(Sighting.new(polarIce.previous_status.radar_heading, current_heading, 0, @rotation.direction, current_position, polarIce.time))
    else
      lock_target_found(closest_target(targets))
    end
  end

  def lock_target_found(target)
    log "radar.lock_target_found #{target}\n"
    @current_target = target
    @desired_heading = @current_target.start_angle
    @state_machine.target_locked(target)
  end

  def lock_target_not_found(target)
    log "radar.lock_target_not_found #{target}\n"
    @current_target = target
    @state_machine.target_not_locked
#    polarIce.target_lost
  end

  def broaden_scan
    @current_target.broaden(10)
    log "radar.broaden_scan #{@current_target}\n"

    if (@current_target.central_angle < 60)
      @desired_heading = @current_target.start_angle
    else
      @state_machine.target_lost
      polarIce.target_lost
    end
  end

  def check_broaden_scan(targets)
    log "radar.check_broaden_scan #{targets}\n"
    remove_partners_from_targets(targets) if (polarIce.current_partner_position != nil)
    if (targets != nil) && (targets.empty?)
      broaden_scan_target_not_found(Sighting.new(polarIce.previous_status.radar_heading, current_heading, 0, @rotation.direction, current_position, polarIce.time))
    else
      broaden_scan_target_found(closest_target(targets))
    end
  end

  def broaden_scan_target_not_found(target)
    log "radar.broaden_scan_target_not_found #{target}\n"
    @current_target = target
    @state_machine.target_not_found
  end

  def broaden_scan_target_found(target)
    @current_target = target
    log "radar.broaden_scan_target_found #{target}\n"
    if (target_in_locked_range(target))
      target_locked(target)
    else
      target_not_locked(target)
    end
  end

  def target_locked(target)
    polarIce.update_target(target)
    @state_machine.target_locked(target)
  end

  def target_not_locked(target)
    polarIce.update_target(target)
    @state_machine.target_found(target)
  end

  def initialize(polarIce)
    @max_rotation = MAXIMUM_ROTATION
    @rotation = INITIAL_ROTATION
    @desired_heading = INITIAL_DESIRED_HEADING
    @desired_target = INITIAL_DESIRED_TARGET
    @polarIce = polarIce
    @targets = Array.new
    initialize_state_machine
  end
  attr_accessor(:polarIce)
  attr_accessor(:targets)
  attr_accessor(:quick_scan_results)
end
module RadarAccessor
  def radar_rotation
    radar.rotation
  end

  def desired_radar_target= target
    radar.desired_target = target
  end

  def desired_radar_heading
    radar.desired_heading
  end
  def desired_radar_heading= heading
    radar.desired_heading = heading
  end
  attr_accessor(:radar)
end
