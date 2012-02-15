$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '.')
require 'spec_helper'
require 'SpinnerBot'
require 'spinner_bot_test_situation'
require 'test_case'

describe SpinnerBot do
  test_situations = [TestCase.new({"x"=>800 + SpinnerDriver::MAINTAIN_DISTANCE.max + 100,"y"=>800,"heading"=>90,"desired_turn"=>10}),
                     TestCase.new({"x"=>800,"y"=>800 + SpinnerDriver::MAINTAIN_DISTANCE.max + 100,"heading"=>180,"desired_turn"=>-10})]
  test_situations.each do |test_case|
    it "at #{test_case.x}, #{test_case.y} headed #{test_case.heading} should turn towards the target when too far away" do
      spinner_bot =  SpinnerBotTestSituation.new.set_x(test_case.x).set_y(test_case.y).set_heading(test_case.heading)
        .set_test_turn.get_spinner_bot
      spinner_bot.should_receive(:turn).with(test_case.desired_turn)
      spinner_bot.tick nil
    end
  end

  test_situations = [TestCase.new({"x"=>800 + SpinnerDriver::MAINTAIN_DISTANCE.min - 50,"y"=>800,"heading"=>90,"desired_turn"=>-10}),
                     TestCase.new({"x"=>800,"y"=>800 + SpinnerDriver::MAINTAIN_DISTANCE.min - 50,"heading"=>180,"desired_turn"=>10})]
  test_situations.each do |test_case|
    it "at #{test_case.x}, #{test_case.y} headed #{test_case.heading} should turn away from the target when too close" do
      spinner_bot =  SpinnerBotTestSituation.new.set_x(test_case.x).set_y(test_case.y).set_heading(test_case.heading)
        .set_test_turn.get_spinner_bot
      spinner_bot.should_receive(:turn).with(test_case.desired_turn)
      spinner_bot.tick nil
    end
  end

  test_situations = [TestCase.new({"x"=>800 + SpinnerDriver::MAINTAIN_DISTANCE.min + 5,"y"=>800,"heading"=>180,"desired_turn"=>10}),
                     TestCase.new({"x"=>800,"y"=>800 + SpinnerDriver::MAINTAIN_DISTANCE.min + 5,"heading"=>90,"desired_turn"=>10})]
  test_situations.each do |test_case|
    it "at #{test_case.x}, #{test_case.y} headed #{test_case.heading} should turn right angle from the target when in range" do
      spinner_bot =  SpinnerBotTestSituation.new.set_x(test_case.x).set_y(test_case.y).set_heading(test_case.heading)
        .set_test_turn.get_spinner_bot
      spinner_bot.should_receive(:turn).with(test_case.desired_turn)
      spinner_bot.tick nil
    end
  end

  it 'should broadcast its location' do
    spinner_bot =  SpinnerBotTestSituation.new.set_test_broadcast.get_spinner_bot
    spinner_bot.should_receive(:broadcast).with("800,#{800 + SpinnerDriver::MAINTAIN_DISTANCE.max + 100 - 1}")
    spinner_bot.tick nil
  end

  it 'should record its partners broadcast location' do
    spinner_bot = SpinnerBotTestSituation.new.get_spinner_bot
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0"]]})
    spinner_bot.partner_location.x.should == 800.0
    spinner_bot.partner_location.y.should == 809.0
  end

  it 'should determine one partner to be submissive' do
    spinner_bot = SpinnerBotTestSituation.new.get_spinner_bot
    spinner_bot.stub!(:time).and_return(1)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0"]]})
    spinner_bot.dominant.should == false
  end

  it 'should determine one partner to be dominant' do
    spinner_bot = SpinnerBotTestSituation.new.get_spinner_bot
    spinner_bot.stub!(:time).and_return(1)
    spinner_bot.tick({"broadcasts"=>[]})
    spinner_bot.dominant.should == true
  end

  it 'submissive partner should let dominant partner move away' do
    spinner_bot = SpinnerBotTestSituation.new.set_speed(8).get_spinner_bot
    spinner_bot.stub!(:time).and_return(1)
    spinner_bot.should_receive(:stop)
    spinner_bot.tick({"broadcasts"=>[["800.0,#{800 + SpinnerDriver::MAINTAIN_DISTANCE.max + 100 - 1}"]]})
  end

  it 'should turn gun toward target' do
    spinner_bot = SpinnerBotTestSituation.new.set_gun_heading(180).set_test_turn_gun.get_spinner_bot
    spinner_bot.should_receive(:turn_gun).with(-30)
    spinner_bot.tick({"broadcasts"=>[]})
  end

  it 'should scan for enemies' do
    spinner_bot = SpinnerBotTestSituation.new.set_test_turn_radar.get_spinner_bot
    spinner_bot.should_receive(:turn_radar).with(SpinnerRadar::RADAR_SCAN_SIZE.max - 1)
    spinner_bot.tick({"broadcasts"=>[],"robot_scanned"=>[]})
  end

  it 'should not detect partner as an enemy' do
    spinner_bot = SpinnerBotTestSituation.new.set_test_turn_radar.set_radar_heading(120).get_spinner_bot
    spinner_bot.old_radar_heading=60
    spinner_bot.should_receive(:turn_radar).with(SpinnerRadar::RADAR_SCAN_SIZE.max - 1)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0"]], "robot_scanned"=>[[500]]})
  end

  it 'should scan back at smaller scan size when it finds an enemy' do
    spinner_bot = SpinnerBotTestSituation.new.set_test_turn_radar.set_radar_heading(120).get_spinner_bot
    spinner_bot.old_radar_heading=60
    spinner_bot.should_receive(:turn_radar)#.with(-30)
    spinner_bot.tick({"broadcasts"=>[["1100.0,1100.0"]], "robot_scanned"=>[[300]]})
  end

  it 'should narrow focus repeatedly to a minimum sufficient accuracy' do
    spinner_bot = SpinnerBotTestSituation.new.set_radar_heading(120).set_test_rounds(5).get_spinner_bot
    spinner_bot.old_radar_heading=60
    spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[[500]]})
    spinner_bot.stub!(:radar_heading).and_return(90)
    spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[[500]]})
    spinner_bot.stub!(:radar_heading).and_return(105)
    spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[[500]]})
    spinner_bot.stub!(:radar_heading).and_return(98)
    spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[[500]]})
    spinner_bot.stub!(:radar_heading).and_return(101)
    spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[[500]]})
    spinner_bot.get_radar_size.should == 3
  end

  #fragile test
  #it 'should repeat narrow focus twice while searching back' do
  #  spinner_bot = SpinnerBotTestSituation.new.set_test_turn_radar.set_radar_heading(120).set_test_rounds(3).get_spinner_bot
  #  spinner_bot.old_radar_heading=60
  #  spinner_bot.should_receive(:turn_radar).with(-31)
  #  spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[[500]]})
  #  spinner_bot.should_receive(:turn_radar).with(-31)
  #  spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[]})
  #  spinner_bot.should_receive(:turn_radar).with(-31)
  #  spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[]})
  #end

  #fragile test
  #it 'should widen search and reverse direction if narrow search fails to find enemy twice' do
  #  spinner_bot = SpinnerBotTestSituation.new.set_test_turn_radar.set_radar_heading(120).set_test_rounds(4).get_spinner_bot
  #  spinner_bot.old_radar_heading=60
  #  spinner_bot.should_receive(:turn_radar).with(9)
  #  spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[[500]]})
  #  spinner_bot.stub!(:time).and_return(101)
  #  spinner_bot.stub!(:radar_heading).and_return(90)
  #  spinner_bot.should_receive(:turn_radar).with(-31)
  #  spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[]})
  #  spinner_bot.stub!(:time).and_return(102)
  #  spinner_bot.stub!(:radar_heading).and_return(SpinnerRadar::RADAR_SCAN_SIZE.max)
  #  spinner_bot.should_receive(:turn_radar)
  #  spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[]})
  #  spinner_bot.stub!(:time).and_return(103)
  #  spinner_bot.stub!(:radar_heading).and_return(30 - 1)
  #  spinner_bot.should_receive(:turn_radar).with(SpinnerRadar::RADAR_SCAN_SIZE.max - 1)
  #  spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[]})
  #end

  it 'should broadcast a target when located' do
    spinner_bot = SpinnerBotTestSituation.new.set_radar_heading(91.5).set_test_broadcast.get_spinner_bot
    spinner_bot.old_radar_heading=88.5
    spinner_bot.set_radar_size(3)
    spinner_bot.should_receive(:broadcast).with("800,#{800 + SpinnerDriver::MAINTAIN_DISTANCE.max + 100 - 1},826,800, 1.5")
    spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[[500]]})
  end

  it 'servant should change target to master target' do
    spinner_bot = SpinnerBotTestSituation.new.get_spinner_bot
    spinner_bot.tick({"broadcasts"=>[["1100,1109,800,600"]], "robot_scanned"=>[]})
    spinner_bot.target.x.should == 800
    spinner_bot.target.y.should == 600
  end

  it 'servant should rotate its radar to orient on masters target', :failing=>true do
    spinner_bot = SpinnerBotTestSituation.new.set_radar_heading(0).set_test_rounds(2).set_test_turn_radar.get_spinner_bot()
    spinner_bot.should_receive(:turn_radar).with(60)
    spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0,800.0,600.0"]], "robot_scanned"=>[]})
    spinner_bot.stub!(:radar_heading).and_return(60)
    spinner_bot.should_receive(:turn_radar).with(28)
    spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0"]], "robot_scanned"=>[]})
  end

  it 'servant should know when its radar is already close enough to masters target' do
    spinner_bot = SpinnerBotTestSituation.new.set_radar_heading(88).set_test_turn_radar.get_spinner_bot()
    spinner_bot.should_receive(:turn_radar).with(SpinnerRadar::RADAR_SCAN_SIZE.min - 1)
    spinner_bot.tick({"broadcasts"=>[["1100.0,1109.0,800.0,600.0"]], "robot_scanned"=>[]})
  end
end

