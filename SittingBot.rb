class SittingBot
  include Robot

  def tick events
    say "I'm at (#{x}, #{y})'"
  end
end