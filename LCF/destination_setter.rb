class DestinationSetter
  def initialize battlefield_width, battlefield_height, clipping_offset
    @damage_taken = 0
    @ticks_used = 0
    @battlefield_width = battlefield_width
    @battlefield_height = battlefield_height
    @clipping_offset = clipping_offset
  end

  def add_damage damage
    @damage_taken += damage
  end

  def add_tick
    @ticks_used += 1
  end

  def average_damage_per_tick
    if @ticks_used == 0
      return 0
    else
      return @damage_taken.to_f/@ticks_used.to_f
    end
  end

  def calculate_destination x_destination, y_destination
    #all child classes need to implement this
  end
end