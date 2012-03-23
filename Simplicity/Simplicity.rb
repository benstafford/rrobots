#Simplicity Robot
require 'robot'

class Simplicity
  DEFAULT_FIRE_POWER = 0.3
  include Robot

  def initialize
    @radar = SimpleRadar.new
    @gunner = SimpleRadar.new
  end

  def tick(events)
    process_the_radar(events['robot_scanned'])
    fire DEFAULT_FIRE_POWER
    turn_gun @gunner.turn_amount
    turn_radar @radar.turn_amount
  end

  private
  def process_the_radar(scan)
    process_scanned_robots if !scan.empty?
  end

  def process_scanned_robots
    @radar.reverse
  end
end