require 'logger'

class SpinnerLogger
  def initialize
    begin
      file = open('SpinnerBot.log', File::WRONLY | File::APPEND | File::CREAT)
      @logger = Logger.new(file)
      @logger.debug(',time, x, y, heading, gun_heading, radar_heading, speed, broadcast_received, accelerate, body_turn, gun_turn, radar_turn, broadcast_sent, target, bot_detected')
    rescue Exception => e
      puts "error trying to initialize log file: #{e.inspect}"
    end
  end

  def LogStatusToFile robot
    @logger.debug(",#{robot.time}, #{robot.x}, #{robot.y}, #{robot.heading}, #{robot.gun_heading}, #{robot.radar_heading}, #{robot.speed}, #{robot.events['broadcasts']}, 1, #{robot.desired_turn}, #{robot.desired_gun_turn}, #{robot.desired_radar_turn}, #{robot.broadcast_sent}, #{robot.target.inspect}, #{robot.bot_detected.inspect}")
  end
end