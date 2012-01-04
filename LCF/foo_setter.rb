class FooSetter < DestinationSetter
  def get_name
    return "Foo Setter'"
  end

  def calculate_destination bot
    return bot.x_location, bot.y_location
  end
end