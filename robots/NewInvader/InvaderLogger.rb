require 'InvaderMath'

class InvaderLogger
  include InvaderMath


  def initialize
    puts "logger created."
    @classes = {}
  end

  def register id
    @classes[id] = []
    puts "registered #{id}"
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

