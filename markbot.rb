require 'robot'

class MarkBot
  include Robot
  attr_accessor :degrees

  def initialize
    @degrees = 5
  end

  def process_hit(events)
    if !events["got_hit"].empty?
      say "You hit me!"
    end
  end

  def process_scan(events)
    scans = events["robot_scanned"]
    if !scans.empty?
      say "#{scans.inspect}"
      fire(2)
      turn(0-@degrees)
    else
      turn(@degrees)
    end
  end

  def tick events
    process_hit(events)
    process_scan(events)
  end
end