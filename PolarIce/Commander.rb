#The Commander is responsible for giving instructions to the other crew members.
class Commander
  X = 0
  Y = 1

  T = 0
  R = 1

  def initialize_state_machine
    commander = self
    @state_machine = Statemachine.build do
      context commander

      state :initializing do
        event :base_test, :base_test
        event :scan, :quick_scan
        event :await_comm, :await_comm
      end

      state :base_test do
        event :scan, :base_test
        event :await_comm, :base_test
      end

      state :await_comm do
        on_entry :await_comm
        event :become_alone, :quick_scan
        event :become_master, :quick_scan
        event :become_slave, :quick_scan
      end

      state :await_orders do
        on_entry :await_orders
        event :target, :await_orders, :target
        event :become_alone, :quick_scan
      end

      superstate :quick_scan do
        event :quick_scan_successful, :track, :add_targets

        state :stop_for_quick_scan do
          on_entry :stop_for_quick_scan
          event :stopped, :scanning
        end

        state :scanning do
          on_entry :start_quick_scan
          on_exit :end_quick_scan
          event :quick_scan_failed, :scanning, :start_quick_scan
          event :become_alone, :scanning
        end
      end

      state :track do
        on_entry :start_tracking
        event :target_lost, :quick_scan
        event :update_target, :track, :aim_at_target
        event :become_alone, :track
      end
    end
  end

  def tick
  end

  def base_test
    log "commander.base_test\n"
    @state_machine.base_test
  end

  def init
    log "commander.init\n"
    @state_machine.await_comm
  end

  def await_comm
    log "commander.await_comm\n"
  end

  def become_master
    log "commander.become_master\n"
    @state_machine.become_master
  end

  def become_slave
    log "commander.become_slave\n"
    @state_machine.become_slave
  end

  def become_alone
    log "commander.become_alone\n"
    @state_machine.become_alone
  end

  def await_orders
    log "commander.await_orders\n"
  end

  def target position
    @state_machine.target(position)
  end
  
  def stop_for_quick_scan
    log "commander.stop_for_quick_scan\n"
    polarIce.stop
  end

  def stopped
    log "commander.stopped\n"
    @state_machine.stopped
  end
  
  def start_quick_scan
    log "commander.start_quick_scan\n"
    @targets.clear
    polarIce.lock
    polarIce.start_quick_scan
  end

  def end_quick_scan
    polarIce.unlock
  end

  def quick_scan_failed
    log "commander.quick_scan_failed\n"
    @state_machine.quick_scan_failed
  end

  def quick_scan_successful(targets)
    log "commander.quick_scan_successful #{targets}\n"
    @state_machine.quick_scan_successful(targets)
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
      @state_machine.target_lost
    end
  end

  def choose_target
    log "commander.choose_target\n"
    remove_partners_from_targets if (polarIce.current_partner_position != nil)
    closest_target(@targets)
  end

  def remove_partners_from_targets
    log "commander.remove_partners_from_targets\n"
    polarIce.current_partner_position.each{|partner| remove_partner_from_targets(partner, @targets) if partner != nil}
  end

  def update_target(target)
    log "commander.update_target #{target}\n"
    @state_machine.update_target(target)
  end

  def aim_at_target(target)
    log "commander.aim_at_target #{target}\n"
    polarIce.target(target)
  end

  def target_lost
    @state_machine.target_lost
  end

  def initialize(polarIce)
    @targets = Array.new
    @polarIce = polarIce
    initialize_state_machine
  end

  attr_accessor(:polarIce)
end
