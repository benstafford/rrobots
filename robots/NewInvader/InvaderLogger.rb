require 'InvaderMath'
require 'logger'

class InvaderLogger
  include InvaderMath

  def initialize
    @locations = {}
    @scans = {}
    initialize_logfile
  end

  def register id
    @locations[id] = []
    @scans[id] = []
  end

  def log id, time, location, heading_of_edge, found_enemy
    @locations[id]<<InvaderLogMessage.new(time, location, heading_of_edge)
    @scans[id]<<InvaderScanMessage.new(time, found_enemy) unless found_enemy.nil?
  end

  def getFriendLocation id
    @locations[id].last.location
  end

  def getFriendEdge id
    @locations[id].last.heading_of_edge
  end

  def getFoundEnemy id, time
    return nil if @scans[id].last.nil?
    return nil if @scans[id].last.time < time - 1
    @scans[id].last.found_enemy
  end

  def getFoundEnemySpeed id
    return 90,0 if @scans[id].count < 2
    last_message = @scans[id].pop
    last_location = last_message.found_enemy
    last_time = last_message.time
    prev_location = @scans[id].last.found_enemy
    prev_time = @scans[id].last.time
    return 90,0 if last_location.nil?
    return 90,0 if prev_location.nil?
    @classes[id]<<last_message
    direction = degree_from_point_to_point(prev_location, last_location)
    speed = distance_between_objects(prev_location, last_location)/(prev_time - last_time)
    return direction, speed
  end

  def LogStatusToFile robot
    @logger.debug(",#{robot.time}, #{robot.my_id}, #{robot.x}, #{robot.y}, #{robot.heading}, #{robot.gun_heading}, #{robot.radar_heading}, #{robot.speed}, #{robot.move_engine.turn}, #{robot.fire_engine.turn_gun}, #{robot.radar_engine.turn_radar}, #{robot.heading_of_edge}, #{robot.target.inspect}")
  end

  def initialize_logfile
    @logger = Logger.new('application.csv')
    @logger.debug(',time, id, x, y, heading, gun_heading, radar_heading, speed, body_turn, gun_turn, radar_turn, selected_edge, radar_target_found')
  end
end

class InvaderScanMessage
  attr_accessor :time
  attr_accessor :found_enemy

  def initialize time, found_enemy
    @time = time
    @found_enemy = found_enemy
  end
end

class InvaderLogMessage
  attr_accessor :location
  attr_accessor :heading_of_edge
  attr_accessor :time

  def initialize time, location, heading_of_edge
    @time = time
    @location = location
    @heading_of_edge = heading_of_edge
  end
end
