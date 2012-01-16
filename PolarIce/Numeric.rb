#Numeric defines extra functions for use with Numeric values
class Numeric
  def clamp(maximum)
    [[-maximum, self].max, maximum].min
  end

  def normalize_angle
    (self + 360) % 360
  end

  def direction
    if self == 0
      1
    else
      (self / self.abs).round
    end
  end

  def encode
    self.round.to_s(36)
  end
end
