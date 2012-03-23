# Gunner turns the gun
class SimpleRadar
  MAX_TURN = 60

  def initialize
    @direction = 1
  end

  def turn_amount
    @direction * MAX_TURN
  end

  def reverse
    @direction *= -1
  end
end