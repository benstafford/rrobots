class GoToNextCornerSetter < DestinationSetter
  def get_name
    return "Go To Next Corner Setter'"
  end

  def calculate_destination bot
    x_return = bot.x_destination
    y_return = bot.y_destination
    if is_in_a_corner(bot.x_location, bot.y_location) == 1
      #puts "bw#{@battlefield_width}, bh#{@battlefield_height}, co#{@clipping_offset}"
      #puts "start|#{x_destination}, #{y_destination}"
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
    #puts "end|#{x_return}, #{y_return}"
    return x_return, y_return
  end

  def is_in_a_corner x_location, y_location
    if (x_location == @clipping_offset) && (y_location == @clipping_offset)
      return_val = 1
    elsif (x_location == (@battlefield_width - @clipping_offset)) && (y_location == @clipping_offset)
      return_val = 1
    elsif (x_location == (@battlefield_width - @clipping_offset)) && (y_location == (@battlefield_height - @clipping_offset))
      return_val = 1
    elsif (x_location == @clipping_offset) && (y_location == (@battlefield_height - @clipping_offset))
      return_val = 1
    end
    return_val
  end
end