class SpinnerRadar
  RADAR_SCAN_SIZE = 3..48
  attr_reader :radar_direction
  attr_accessor :radar_size
  
  def initialize spinner_bot
    @robot = spinner_bot
    @radar_direction = 1
    @radar_size = 60
  end

  def sweep_radar
    case
      when !@robot.bot_detected.nil? then reverse_and_narrow_radar_direction
      when lost_target? then reverse_and_expand_direction
    end
    @radar_size = [[@radar_size, RADAR_SCAN_SIZE.min ].max, RADAR_SCAN_SIZE.max].min
    radar_turn = (@radar_direction * @radar_size)
    radar_turn = drag_right(radar_turn)
    radar_turn = [[(0 - (@robot.desired_gun_turn + @robot.desired_turn)) + radar_turn, 60].min, -60].max
    radar_turn
  end

  def reverse_and_expand_direction
    @radar_size = @radar_size * 2  if @radar_size < RADAR_SCAN_SIZE.max
    reverse_radar_direction
  end

  def lost_target?
    return false if @robot.time_bot_detected.nil?
    time_since_detect = @robot.time - @robot.time_bot_detected
    [3,5,7,9].include?(time_since_detect) && @radar_size < RADAR_SCAN_SIZE.max
  end

  def reverse_and_narrow_radar_direction
    @radar_size = @radar_size /2  if @radar_size > RADAR_SCAN_SIZE.min
    reverse_radar_direction
  end

  def reverse_radar_direction
    @radar_direction = 0 - @radar_direction
  end

  def drag_right radar_turn
    radar_turn - 1
  end
end