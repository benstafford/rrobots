class Commander
  X = 0
  Y = 1

  T = 0
  R = 1

  def initialize_state_machine
    commander = self
    @stateMachine = Statemachine.build do
      state :initializing do
        event :scan, :quick_scan
        event :base_test, :base_test
      end
      state :base_test do
        event :scan, :base_test
      end
      state :quick_scan do
        on_entry :start_quick_scan
        on_exit :end_quick_scan
        event :quick_scan_successful, :track, :add_targets
        event :quick_scan_failed, :quick_scan, :start_quick_scan
      end
      state :track do
        on_entry :start_tracking
        event :target_lost, :quick_scan
        event :update_target, :track, :aim_at_target
      end
      context commander
    end
  end

  def tick
  end

  def base_test
    log "commander.base_test\n"
    @stateMachine.base_test
  end

  def scan
    log "commander.scan\n"
    @stateMachine.scan
  end

  def start_quick_scan
    log "commander.start_quick_scan\n"
    @originalHeading = polarIce.heading
    @sectorsScanned = 0
    @targets.clear
    polarIce.start_quick_scan
    polarIce.lock
  end

  def end_quick_scan
    polarIce.unlock
  end

  def quick_scan_failed
    log "commander.quick_scan_failed\n"
    @stateMachine.quick_scan_failed
  end

  def quick_scan_successful(targets)
    log "commander.quick_scan_successful #{targets}\n"
    @stateMachine.quick_scan_successful(targets)
  end

  def add_targets targets_scanned
    log "commander.add_targets #{targets_scanned}\n"
    @targets += targets_scanned
  end

  def start_tracking
    log "commander.start_tracking\n"
    target = choose_target
    if target != nil
      aim_at_target(target)
      polarIce.track(target)
    else
      @stateMachine.target_lost
    end
  end

  def choose_target
    log "choose_target\n"
    remove_partner_from_targets if (polarIce.currentPartnerPosition != nil)
    closest_target
  end

  def remove_partner_from_targets
    log "remove_partner_from_targets\n"
    @targets.delete_if{|target| target.contains(polarIce.currentPartnerPosition)}
  end

  def closest_target
    closest = @targets[0]
    @targets.each {|target| closest = target if target.distance < closest.distance }
    closest
  end

  def update_target(target)
    log "commander.update_target #{target}"
    @stateMachine.update_target(target)
  end

  def aim_at_target(target)
    log "commander.aim_at_target #{target}"
    polarIce.target(target)
  end

  def target_lost
    @stateMachine.target_lost
  end

  def initialize(polarIce)
    @targets = Array.new
    @polarIce = polarIce
    initialize_state_machine
  end

  attr_accessor(:polarIce)
end
