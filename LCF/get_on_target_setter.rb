class GetOnTargetSetter < DestinationSetter
  def get_name
    return "Get On Target Setter"
  end

  def calculate_destination bot
    @turn_direction = 1 if @turn_direction.nil?
    bot_turn = 90
    x_return = bot.x_destination
    y_return = bot.y_destination

    @turn_direction *= -1 if ((bot.x_location <= @clipping_offset) || (bot.x_location >= (@battlefield_width - @clipping_offset)) ||
                              (bot.y_location <= @clipping_offset) || (bot.y_location >= (@battlefield_height - @clipping_offset))) && (@turn_direction == 1)

    if (bot.x_target != -1) && (bot.y_target != -1)
      #x_return, y_return = bot.return_cord bot.x_target, bot.y_target, (0 + bot.my_gun_heading), 120
      x_return, y_return = bot.return_cord bot.x_location, bot.y_location, (@turn_direction * bot_turn + bot.my_gun_heading), 120
      #x_return = bot.x_target
      #y_return = bot.y_target
    end

    return x_return, y_return
  end
end