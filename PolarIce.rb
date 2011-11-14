require 'robot'
require 'Matrix'

class PolarIce
   include Robot

  def tick events
     init_on_tick
  end

  def init_on_tick
    @currentPosition = Vector[x, y]
  end

  def currentPosition
    @currentPosition
  end

  def currentPosition=(position)
    @currentPosition = position
  end
end