require 'Invader'

class SpaceInvader < Invader
  def initialize
    @intent_heading = 180
    super
  end

  def tick events
    record_position y, x, battlefield_width, 90, 180, 0
    process_tick events, 'SpaceInvader'
  end

end