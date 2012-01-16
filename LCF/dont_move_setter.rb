class DontMoveSetter < DestinationSetter
  def get_name
    return "Don't Move Setter'"
  end

  def calculate_destination bot
    return bot.x_location, bot.y_location
  end
end