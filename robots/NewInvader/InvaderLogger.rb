require 'InvaderMath'

class InvaderLogger
  include InvaderMath

  def initialize
    @classes = {}
  end

  def register id
    @classes[id] = []
  end

  def log id, time, location, heading_of_edge, found_enemy
    @classes[id]<<InvaderLogMessage.new(time, location, heading_of_edge, found_enemy)
  end

  def getFriendLocation id
    @classes[id].last.location
  end

  def getFriendEdge id
    @classes[id].last.heading_of_edge
  end

  def getFoundEnemy id
   @classes[id].last.found_enemy
  end

  def getFoundEnemySpeed id
    return 90,0 if @classes[id].count < 2
    last_message = @classes[id].pop
    last_location = last_message.found_enemy
    last_time = last_message.time
    prev_location = @classes[id].last.found_enemy
    prev_time = @classes[id].last.time
    return 90,0 if last_location.nil?
    return 90,0 if prev_location.nil?
    @classes[id]<<last_message
    direction = degree_from_point_to_point(prev_location, last_location)
    speed = distance_between_objects(prev_location, last_location)/(prev_time - last_time)
    return direction, speed
  end
end

class InvaderLogMessage
  attr_accessor :location
  attr_accessor :heading_of_edge
  attr_accessor :time
  attr_accessor :found_enemy

  def initialize time, location, heading_of_edge, found_enemy
    @time = time
    @location = location
    @heading_of_edge = heading_of_edge
    @found_enemy = found_enemy
  end
end
