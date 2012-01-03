class SideWalkerSetter < DestinationSetter
  def get_name
    return "Side Walker"
  end

  def calculate_destination bot
    x_return = bot.x_destination
    y_return = bot.y_destination

    if is_in_a_corner(bot.x_destination, bot.y_destination) != 1
      if (is_in_a_corner(bot.pair_x_destination, bot.pair_y_destination) != 1)
        x_return, y_return = go_to_nearest_corner bot
      else
        x_return, y_return = find_catty_corner bot
      end
    else
      x_return, y_return = go_to_next_corner bot
    end

    return x_return, y_return
  end

  def go_to_nearest_corner bot
    x_return = bot.x_destination
    y_return = bot.y_destination

    if @battlefield_width.to_i / 2 < bot.x_location then
      x_return = @battlefield_width - @clipping_offset
    else
      x_return = 0 + @clipping_offset
    end

    if @battlefield_height.to_i / 2 < bot.y_location then
      y_return = @battlefield_height - @clipping_offset
    else
      y_return = 0 + @clipping_offset
    end

    return x_return, y_return
  end

  def find_catty_corner bot
    x_return = bot.x_destination
    y_return = bot.y_destination

    if (bot.pair_x_destination.to_i == @clipping_offset) && (bot.pair_y_destination.to_i == @clipping_offset) #upper_left
      x_return = @battlefield_width - @clipping_offset
      y_return = @battlefield_height - @clipping_offset
    elsif (bot.pair_x_destination.to_i == @battlefield_width - @clipping_offset) && (bot.pair_y_destination.to_i == @clipping_offset) #upper_right
      x_return = @clipping_offset
      y_return = @battlefield_height - @clipping_offset
    elsif (bot.pair_x_destination.to_i == @battlefield_width - @clipping_offset) && (bot.pair_y_destination.to_i == @battlefield_height - @clipping_offset) #lower_right
      x_return = @clipping_offset
      y_return = @clipping_offset
    elsif (bot.pair_x_destination.to_i == @clipping_offset) && (bot.pair_y_destination.to_i == @battlefield_height - @clipping_offset) #lower_left
      x_return = @battlefield_width - @clipping_offset
      y_return = @clipping_offset
    end

    return x_return, y_return
  end

  def go_to_next_corner bot
    x_return = bot.x_destination
    y_return = bot.y_destination

    if ((bot.x_location - bot.x_destination).abs < 1) && ((bot.y_location - bot.y_destination).abs < 1)
      if (bot.x_destination == @clipping_offset) && (bot.y_destination == @clipping_offset)
        x_return = @battlefield_width - @clipping_offset
        y_return = @clipping_offset
      elsif (bot.x_destination == (@battlefield_width - @clipping_offset)) && (bot.y_destination == @clipping_offset)
        x_return = @battlefield_width - @clipping_offset
        y_return = @battlefield_height - @clipping_offset
      elsif (bot.x_destination == (@battlefield_width - @clipping_offset)) && (bot.y_destination == (@battlefield_height - @clipping_offset))
        x_return = @clipping_offset
        y_return = @battlefield_height - @clipping_offset
      elsif (bot.x_destination == @clipping_offset) && (bot.y_destination == (@battlefield_height - @clipping_offset))
        x_return = @clipping_offset
        y_return = @clipping_offset
      end
    end

    return x_return, y_return
  end

  def is_in_a_corner x_location, y_location
    return_val = 0
    corner_ff = 1
    if ((x_location - @clipping_offset).abs < corner_ff) && ((y_location - @clipping_offset).abs < corner_ff)
      return_val = 1
    elsif ((x_location - (@battlefield_width - @clipping_offset)).abs < corner_ff) && ((y_location - @clipping_offset).abs < corner_ff)
      return_val = 1
    elsif ((x_location - (@battlefield_width - @clipping_offset)).abs < corner_ff) && ((y_location - (@battlefield_height - @clipping_offset)).abs < corner_ff)
      return_val = 1
    elsif ((x_location - @clipping_offset).abs < corner_ff) && ((y_location - (@battlefield_height - @clipping_offset)).abs < corner_ff)
      return_val = 1
    end
    return_val
  end
end