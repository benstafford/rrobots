class SittingBot
  include Robot

  def tick events
    say "I'm at (#{x}, #{y})'"
    #print "SittingBot: Position = Vector[#{x},#{y}]\n" if time == 0
  end
end