class DestinationSetter
  attr_reader(:damage_taken)
  attr_reader(:ticks_used)

  def initialize battlefield_width, battlefield_height, clipping_offset
    @damage_taken = 0
    @ticks_used = 0
    @battlefield_width = battlefield_width
    @battlefield_height = battlefield_height
    @clipping_offset = clipping_offset
  end

  def get_name
    return "base setter"
  end

  def add_damage_for_this_tick damage
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

  def calculate_destination bot
    #all child classes need to implement this
    return bot.x_destination, bot.y_destination
  end
end