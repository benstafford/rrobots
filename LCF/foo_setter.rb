class FooSetter < DestinationSetter
  def get_name
    return "Foo Setter'"
  end

  def calculate_destination bot
    @angle_direction = -1 if @angle_direction.nil?
    angle = 90
    @angle_direction *= -1 if (@ticks_used % 25) == 0

    return bot.return_cord bot.x_location, bot.y_location, bot.my_gun_heading + (angle * @angle_direction), -100
  end
end