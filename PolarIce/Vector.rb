class Vector
  X = 0
  Y = 1

  T = 0
  R = 1

  def angle_to(position)
    (Math.atan2(self[Y] - position[Y], position[X] - self[X]).to_deg.normalize_angle).trim
  end

  def distance_to(desiredTarget)
    Math.hypot(desiredTarget[X] - self[X], desiredTarget[Y] - self[Y])
  end

  def to_cartesian
    Vector[(self[R] * Math.cos(self[T] * Math::PI/180)).trim, (-self[R] * Math.sin(self[T] * Math::PI/180)).trim]
  end

  def polar_vector_to(position)
    log "polar_vector_to #{self} Vector[#{angle_to(position)},#{distance_to(position)}]\n"
    Vector[angle_to(position), distance_to(position)]
  end

  def encode
    self[X].encode + "," + self[Y].encode
  end
end
