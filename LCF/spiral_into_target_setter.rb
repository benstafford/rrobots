class SpiralIntoTargetSetter < DestinationSetter
  def get_name
    return "Spiral Into Target'"
  end

  def calculate_destination bot
    #puts "SpeedDiff#{(bot.my_speed - bot.distance_between_points(bot.x_location, bot.y_location, bot.last_x_location, bot.last_y_location)).abs.to_i}|speed #{bot.my_speed}|calculated speed #{bot.distance_between_points(bot.x_location, bot.y_location, bot.last_x_location, bot.last_y_location)}" unless bot.last_x_location.nil?
    @angle_direction = -1 if @angle_direction.nil?
    @tick_changed_direction = 0 if @tick_changed_direction.nil?
    unless bot.last_x_location.nil?
      if ((bot.my_speed - bot.distance_between_points(bot.x_location, bot.y_location, bot.last_x_location, bot.last_y_location)).abs.to_i != 0) &&
          ((bot.my_time - @tick_changed_direction) > 18)
        #puts "changed direction"
        @angle_direction *= -1
        @tick_changed_direction = bot.my_time
      end
    end
    angle = 112 + bot.last_last_lead_shot

    return bot.return_cord bot.x_location, bot.y_location, bot.my_gun_heading + (angle * @angle_direction), -100
  end
end