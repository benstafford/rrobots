class Numeric
  def clamp(maximum)
    [[-maximum, self].max, maximum].min
  end

  def trim(decimal_places = 2)
    if decimal_places > 0
      (self * 10**decimal_places).round.to_f / 10**decimal_places
    else
      self.round.to_f
    end
  end

  def normalize_angle
    (self + 360) % 360
  end

  def direction
    if self == 0
      1
    else
      (self / self.abs).to_i
    end
  end

  def encode
    (self * 100).round.to_s(36)
  end
end
