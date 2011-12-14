class GoToNextCornerSetter < DestinationSetter
  def calculate_destination x_destination, y_destination
    if (x_destination == @clipping_offset) && (y_destination == @clipping_offset)
      x_destination = @battlefield_width - @clipping_offset
      y_destination = @clipping_offset
    elsif (x_destination == (@battlefield_width - @clipping_offset)) && (y_destination == @clipping_offset)
      x_destination = @battlefield_width - @clipping_offset
      y_destination = @battlefield_height - @clipping_offset
    elsif (x_destination == (@battlefield_width - @clipping_offset)) && (y_destination == (@battlefield_height - @clipping_offset))
      x_destination = @clipping_offset
      y_destination = @battlefield_height - @clipping_offset
    elsif (x_destination == @clipping_offset) && (y_destination == (@battlefield_height - @clipping_offset))
      x_destination = @clipping_offset
      y_destination = @clipping_offset
    else
      #do some default
    end
  end
end