#Vector adds useful functionality to the Vector class.
class Vector
  X = 0
  Y = 1

  T = 0
  R = 1

  def angle_to(position)
    (Math.atan2(self[Y] - position[Y], position[X] - self[X]).to_deg.normalize_angle).round
  end

  def distance_to(desired_target)
    Math.hypot(desired_target[X] - self[X], desired_target[Y] - self[Y])
  end

  def to_cartesian
    radius, angle = self[R], self[T].to_rad
    Vector[(radius * Math.cos(angle)).round, (-radius * Math.sin(angle)).round]
  end

  def polar_vector_to(position)
    Vector[angle_to(position), distance_to(position)]
  end

  def encode
    self[X].encode + "," + self[Y].encode
  end
end

def decode_vector(message)
  message_x, message_y = message.split(',').map { |string| string.to_i(36) }
  Vector[message_x,message_y]
end
