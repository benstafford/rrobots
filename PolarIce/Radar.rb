class Radar
  include Rotator

  T = 0
  R = 1

  MAXIMUM_ROTATION = 60
  INITIAL_ROTATION = 0
  INITIAL_DESIRED_HEADING = nil
  INITIAL_DESIRED_TARGET = nil

  def tick
    @stateMachine.tick
    rotator_tick
  end

  def initialize_state_machine
    radar = self
    @stateMachine = Statemachine.build do
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
    @stateMachine.scan
  end

  def start_quick_scan
    log "radar.start_quick_scan\n"
    @originalHeading = @currentHeading
    setup_scan
  end

  def setup_scan
    log "radar.setup_scan oH=#{@originalHeading} cH=#{@currentHeading}\n"
    @sectorsScanned = 0
    @currentTarget = nil
    @targets.clear
    @desiredHeading = (@currentHeading + MAXIMUM_ROTATION).normalize_angle
  end

  def add_targets targets_scanned
    log "radar.add_targets #{targets_scanned}\n"
    @targets += targets_scanned if !targets_scanned.empty?
  end

  def count_sectors_scanned
    @sectorsScanned += 1
    log "radar.count_sectors_scanned #{@sectorsScanned}\n"
    if @sectorsScanned < 6
      @desiredHeading = (@currentHeading + MAXIMUM_ROTATION).normalize_angle
      @stateMachine.scan_incomplete
    elsif !@targets.empty?
      quick_scan_successful(@targets)
    else
      quick_scan_failed
    end
  end

  def restore_original_heading
    log "radar.restore_original_heading #{@originalHeading}\n"
    @desiredHeading = @originalHeading
  end

  def scanned(targets_scanned)
#    log "radar.scanned #{targets_scanned}\n"
    @stateMachine.scanned(targets_scanned)
  end

  def quick_scan_failed
    log "radar.quick_scan_failed\n"
    @stateMachine.quick_scan_failed
    polarIce.quick_scan_failed
  end

  def quick_scan_successful(targets)
    log "radar.quick_scan_successful #{targets}\n"
    @stateMachine.quick_scan_successful
    polarIce.quick_scan_successful(targets)
  end

  def track(target)
    log "radar.track #{target}\n"
    @stateMachine.track(target)
  end

  def rotate_to_sector(target)
    log "radar.rotate_to_sector #{target}\n"
    @currentTarget = target
    @desiredHeading = @currentTarget.start_angle
  end

  def check_desired_heading
    log "radar.check_desired_heading current #{@currentHeading} desired #{@desiredHeading}\n"
    if (@currentHeading == @desiredHeading)
      @desiredHeading = nil
      @stateMachine.arrived
    else
      @stateMachine.rotating
    end
  end

  def start_track
    log "radar.start_track #{@currentTarget}\n"
    @desiredHeading = @currentTarget.bisector
  end

  def remove_partners_from_targets(targets)
    log "commander.remove_partners_from_targets\n"
    polarIce.currentPartnerPosition.each{|partner| remove_partner_from_targets(partner, targets) if partner != nil}
  end

  def remove_partner_from_targets(partner, targets)
    targets.delete_if { |target| target.contains(partner) }
  end

  def check_track_scan(targets)
    log "radar.check_track_scan #{targets}\n"
    remove_partners_from_targets(targets) if polarIce.currentPartnerPosition != nil
    if (targets != nil) && (targets.empty?)
      target_not_found(Sighting.new(polarIce.previousRadarHeading, currentHeading, 0, @rotation.direction, currentPosition, polarIce.time))
    else
      target_found(closest_target(targets))
    end
  end

  def target_not_found(target)
    log "radar.target_not_found #{target}\n"
    if (target.start_angle == @currentTarget.end_angle)
      end_angle = @currentTarget.start_angle
    else
      end_angle = @currentTarget.end_angle
    end

    @currentTarget = Sighting.new(end_angle, target.end_angle, @currentTarget.distance, target.direction, currentPosition, target.time)

    @desiredHeading = @currentTarget.bisector

    log "radar.not_found.currentTarget = #{@currentTarget}\n"
    log "radar.not_found.desiredHeading = #{@desiredHeading}\n"

    check_target_locked(@currentTarget)
  end

  def target_found(target)
    log "radar.target_found new #{target}\n"

    @currentTarget = target
    @desiredHeading = @currentTarget.bisector

    log "radar.found.currentTarget = #{@currentTarget}\n"
    log "radar.found.desiredHeading = #{@desiredHeading}\n"
    check_target_locked(target)
  end

  def check_target_locked(target)
    log "radar.check_target #{target} ==> "
    if target_in_locked_range(target)
      log "target_locked\n"
      @stateMachine.target_locked(target)
      polarIce.update_target(target)
    else
      log "target_not_locked\n"
      @stateMachine.target_not_locked(target)
    end
  end

  def target_in_locked_range(target)
    target.arc_length <= polarIce.size
  end

  def maintain_lock(target)
    log "radar.maintain_lock\n"
    @desiredHeading = target.start_angle
  end

  def check_maintain_lock(targets)
    log "radar.check_maintain_lock #{targets}\n"
    remove_partners_from_targets(targets) if (polarIce.currentPartnerPosition != nil)
    if (targets == nil) || (targets.empty?)
      lock_target_not_found(Sighting.new(polarIce.previousRadarHeading, currentHeading, 0, @rotation.direction, currentPosition, polarIce.time))
    else
      lock_target_found(closest_target(targets))
    end
  end


  def lock_target_found(target)
    log "radar.lock_target_found #{target}\n"
    @currentTarget = target
    @desiredHeading = @currentTarget.start_angle
    @stateMachine.target_locked(target)
  end

  def lock_target_not_found(target)
    log "radar.lock_target_not_found #{target}\n"
    @currentTarget = target
    @stateMachine.target_not_locked
#    polarIce.target_lost
  end

  def broaden_scan
    @currentTarget.broaden(10)
    log "radar.broaden_scan #{@currentTarget}\n"

    if (@currentTarget.central_angle < 60)
      @desiredHeading = @currentTarget.start_angle
    else
      @stateMachine.target_lost
      polarIce.target_lost
    end
  end

  def check_broaden_scan(targets)
    log "radar.check_broaden_scan #{targets}\n"
    remove_partners_from_targets(targets) if (polarIce.currentPartnerPosition != nil)
    if (targets != nil) && (targets.empty?)
      broaden_scan_target_not_found(Sighting.new(polarIce.previousRadarHeading, currentHeading, 0, @rotation.direction, currentPosition, polarIce.time))
    else
      broaden_scan_target_found(closest_target(targets))
    end
  end

  def broaden_scan_target_not_found(target)
    log "radar.broaden_scan_target_not_found #{target}\n"
    @currentTarget = target
    @stateMachine.target_not_found
  end

  def broaden_scan_target_found(target)
    @currentTarget = target
    log "radar.broaden_scan_target_found #{target}\n"
    if (target_in_locked_range(target))
      polarIce.update_target(target)
      @stateMachine.target_locked(target)
    else
      polarIce.update_target(target)
      @stateMachine.target_found(target)
    end
  end

  def closest_target(targets)
    closest = targets[0]
    targets.each {|target| closest = target if target.distance < closest.distance }
    log "closest_target #{closest}\n"
    closest
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
  attr_accessor(:quick_scan_results)
end
module RadarAccessor
  def radarRotation
    radar.rotation
  end

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
