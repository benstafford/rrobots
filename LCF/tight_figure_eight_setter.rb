class TightFigureEightSetter < DestinationSetter
  def get_name
    return "Tight Figure Eight"
  end

  def calculate_destination bot
    @current_deg = 0  if @current_deg.nil?
    @turn_direction = 1 if @turn_direction.nil?
    bot_turn = 10
    if @current_deg.abs > 360
      @current_deg = 0
      @turn_direction *= -1
    end
    @current_deg += (@turn_direction * bot_turn)
    #bot.return_cord(bot.x_location, bot.y_location, (@turn_direction * 10 + bot.my_heading), 0.1) #speed 0
    bot.return_cord(bot.x_location, bot.y_location, (@turn_direction * bot_turn + bot.my_heading), 65) #speed 8
  end
end