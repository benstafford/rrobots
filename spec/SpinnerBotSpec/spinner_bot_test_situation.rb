class SpinnerBotTestSituation
  def initialize
    @test_rounds = 1
    @x = 800
    @y = 800 + SpinnerDriver::MAINTAIN_DISTANCE.max + 100
    @heading = 90
    @time = 100
    @speed = 0
    @gun_heading = 90
    @gun_heat = 30
    @radar_heading = 270
    @ignore_broadcast = true
    @ignore_accelerate = true
    @ignore_turn = true
    @ignore_gun_turn = true
    @ignore_radar_turn = true
  end

  def get_spinner_bot
    spinner_bot = SpinnerBot.new
    spinner_bot.stub!(:x).and_return(@x)
    spinner_bot.stub!(:y).and_return(@y)
    spinner_bot.stub!(:heading).and_return(@heading)
    spinner_bot.stub!(:speed).and_return(@speed)
    spinner_bot.stub!(:time).and_return(@time)
    spinner_bot.stub!(:gun_heading).and_return(@gun_heading)
    spinner_bot.stub!(:gun_heat).and_return(@gun_heat)
    spinner_bot.stub!(:radar_heading).and_return(@radar_heading)

    spinner_bot.should_receive(:accelerate).exactly(@test_rounds).times unless @ignore_accelerate == false
    spinner_bot.should_receive(:broadcast).exactly(@test_rounds).times unless @ignore_broadcast == false
    spinner_bot.should_receive(:turn).exactly(@test_rounds).times unless @ignore_turn == false
    spinner_bot.should_receive(:turn_gun).exactly(@test_rounds).times unless @ignore_gun_turn == false
    spinner_bot.should_receive(:turn_radar).exactly(@test_rounds).times unless @ignore_radar_turn == false
    spinner_bot.should_receive(:say).exactly(@test_rounds).times
    spinner_bot.should_receive(:fire).exactly(@test_rounds).times
    spinner_bot
  end

  def set_x x
    @x = x
    self
  end

  def set_y y
    @y = y
    self
  end

  def set_heading heading
    @heading = heading
    self
  end

  def set_gun_heading heading
    @gun_heading = heading
    self
  end

  def set_radar_heading heading
    @radar_heading = heading
    self
  end

  def set_test_turn
    @ignore_turn = false
    self
  end

  def set_test_turn_gun
    @ignore_gun_turn = false
    self
  end

  def set_test_turn_radar
    @ignore_radar_turn = false
    self
  end

  def set_test_broadcast
    @ignore_broadcast = false
    self
  end

  def set_test_rounds rounds
    @test_rounds = rounds
    self
  end

  def set_speed speed
    @speed = speed
    self
  end
end