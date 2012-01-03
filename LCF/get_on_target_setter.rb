class GetOnTargetSetter < DestinationSetter
  def get_name
    return "Get On Target Setter"
  end

  def calculate_destination bot
    x_return = bot.x_destination
    y_return = bot.y_destination

    if (bot.x_target != -1) && (bot.y_target != -1)
      #x_return, y_return = bot.return_cord bot.x_target, bot.y_target, (0 + bot.my_gun_heading), 120
      #x_return, y_return = bot.return_cord bot.x_location, bot.y_location, (90 + bot.my_gun_heading), 120
      x_return = bot.x_target
      y_return = bot.y_target
    end

    return x_return, y_return
  end
end