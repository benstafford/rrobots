class SpinnerCommunicator
  def initialize spinnerBot
    @robot = spinnerBot
  end

  def send_broadcast
    location_next_turn = @robot.my_location_next_turn
    message = "#{location_next_turn.x.to_i},#{location_next_turn.y.to_i}"
    if !@robot.bot_detected.nil?
      message += ",#{@robot.bot_detected.x.to_i},#{@robot.bot_detected.y.to_i}, #{@robot.target_range}"
    end
    message
  end

  def process_broadcast broadcast_event
    @robot.partner_location = nil
    @robot.partner_target = nil
    if broadcast_event.count > 0
      message = broadcast_event[0][0]
      message_parcels = message.split(",")
      @robot.partner_location = SpinnerBot::Point.new(message_parcels[0].to_f, message_parcels[1].to_f)
      @robot.partner_target = SpinnerBot::Point.new(message_parcels[2].to_f, message_parcels[3].to_f) if message_parcels.count > 2
      @robot.target = @robot.partner_target if !@robot.dominant && !@robot.partner_target.nil?
      @robot.target_range = message_parcels[4].to_f if !@robot.dominant && !@robot.partner_target.nil? && message_parcels.count > 4
    else
      @robot.dominant = true if @robot.time == 1
    end
  end
end