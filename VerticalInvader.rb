require 'Invader'

class VerticalInvader < Invader
  def initialize
    @intent_heading = 90
    super
  end

  def tick events
    record_position x, y, battlefield_height, 180, 90, 270
    process_tick events, 'VerticalInvader'
  end

end