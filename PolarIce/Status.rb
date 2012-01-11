#Status stores the status information for a tick
class Status
  def initialize(position, heading, gun_heading, radar_heading, speed)
    @position = position
    @heading = heading
    @gun_heading = gun_heading
    @radar_heading = radar_heading
    @speed = speed
  end

  attr_accessor(:position)
  attr_accessor(:heading)
  attr_accessor(:gun_heading)
  attr_accessor(:radar_heading)
  attr_accessor(:speed)
end