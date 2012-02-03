$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '.')
require 'spec_helper'
require 'SpinnerBot'
require 'spinner_bot_test_situation'
require 'test_case'

describe SpinnerBot do
  test_situations = [TestCase.new({"x"=>970,"y"=>800,"heading"=>90,"desired_turn"=>10}),
                     TestCase.new({"x"=>800,"y"=>970,"heading"=>180,"desired_turn"=>-10})]
  test_situations.each do |test_case|
    it "at #{test_case.x}, #{test_case.y} headed #{test_case.heading} should turn towards the target when too far away" do
      spinner_bot =  SpinnerBotTestSituation.new.set_x(test_case.x).set_y(test_case.y).set_heading(test_case.heading)
        .set_test_turn.get_spinner_bot
      spinner_bot.should_receive(:turn).with(test_case.desired_turn)
      spinner_bot.tick nil
    end
  end

  test_situations = [TestCase.new({"x"=>850,"y"=>800,"heading"=>90,"desired_turn"=>-10}),
                     TestCase.new({"x"=>800,"y"=>850,"heading"=>180,"desired_turn"=>10})]
  test_situations.each do |test_case|
    it "at #{test_case.x}, #{test_case.y} headed #{test_case.heading} should turn away from the target when too close" do
      spinner_bot =  SpinnerBotTestSituation.new.set_x(test_case.x).set_y(test_case.y).set_heading(test_case.heading)
        .set_test_turn.get_spinner_bot
      spinner_bot.should_receive(:turn).with(test_case.desired_turn)
      spinner_bot.tick nil
    end
  end

  test_situations = [TestCase.new({"x"=>925,"y"=>800,"heading"=>180,"desired_turn"=>10}),
                     TestCase.new({"x"=>800,"y"=>925,"heading"=>90,"desired_turn"=>10})]
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
    spinner_bot.should_receive(:broadcast).with("800.0,1099.0,90.0,1")
    spinner_bot.tick nil
  end

  it 'should record its partners broadcast location' do
    spinner_bot = SpinnerBotTestSituation.new.get_spinner_bot
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]]})
    spinner_bot.partner_location.x.should == 800.0
    spinner_bot.partner_location.y.should == 809.0
  end

  it 'should determine one partner to be submissive' do
    spinner_bot = SpinnerBotTestSituation.new.get_spinner_bot
    spinner_bot.stub!(:time).and_return(1)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]]})
    spinner_bot.dominant.should == false
  end

  it 'should determine one partner to be dominant' do
    spinner_bot = SpinnerBotTestSituation.new.get_spinner_bot
    spinner_bot.stub!(:time).and_return(1)
    spinner_bot.tick({"broadcasts"=>[]})
    spinner_bot.dominant.should == true
  end

  it 'submissive partner should let dominant partner move away' do
    spinner_bot = SpinnerBotTestSituation.new.get_spinner_bot
    spinner_bot.stub!(:time).and_return(1)
    spinner_bot.should_receive(:stop)
    spinner_bot.tick({"broadcasts"=>[["800.0,1099.0,90.0,1"]]})
  end

  it 'should turn gun toward target' do
    spinner_bot = SpinnerBotTestSituation.new.set_gun_heading(180).set_test_turn_gun.get_spinner_bot
    spinner_bot.should_receive(:turn_gun).with(-30)
    spinner_bot.tick({"broadcasts"=>[]})
  end

  it 'should scan for enemies' do
    spinner_bot = SpinnerBotTestSituation.new.set_test_turn_radar.get_spinner_bot
    spinner_bot.should_receive(:turn_radar).with(60)
    spinner_bot.tick({"broadcasts"=>[],"robot_scanned"=>[]})
  end

  it 'should not detect partner as an enemy' do
    spinner_bot = SpinnerBotTestSituation.new.set_test_turn_radar.set_radar_heading(120).get_spinner_bot
    spinner_bot.set_old_radar_heading(60)
    spinner_bot.should_receive(:turn_radar).with(60)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[500]})
  end

  it 'should scan back at smaller scan size when it finds an enemy' do
    spinner_bot = SpinnerBotTestSituation.new.set_test_turn_radar.set_radar_heading(0).get_spinner_bot
    spinner_bot.set_old_radar_heading(300)
    spinner_bot.should_receive(:turn_radar).with(-30)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[500]})
  end

  it 'should narrow focus repeatedly to a minimum sufficient accuracy' do
    spinner_bot = SpinnerBotTestSituation.new.set_test_turn_radar.set_radar_heading(0).set_test_rounds(5).get_spinner_bot
    spinner_bot.set_old_radar_heading(300)
    spinner_bot.should_receive(:turn_radar).with(-30)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[500]})
    spinner_bot.stub!(:radar_heading).and_return(330)
    spinner_bot.should_receive(:turn_radar).with(15)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[500]})
    spinner_bot.stub!(:radar_heading).and_return(345)
    spinner_bot.should_receive(:turn_radar).with(-7)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[500]})
    spinner_bot.stub!(:radar_heading).and_return(338)
    spinner_bot.should_receive(:turn_radar).with(3)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[500]})
    spinner_bot.stub!(:radar_heading).and_return(341)
    spinner_bot.should_receive(:turn_radar).with(-3)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[500]})
  end

  it 'should repeat narrow focus twice while searching back' do
    spinner_bot = SpinnerBotTestSituation.new.set_test_turn_radar.set_radar_heading(0).set_test_rounds(3).get_spinner_bot
    spinner_bot.set_old_radar_heading(300)
    spinner_bot.should_receive(:turn_radar).with(-30)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[500]})
    spinner_bot.should_receive(:turn_radar).with(-30)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[]})
    spinner_bot.should_receive(:turn_radar).with(-30)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[]})
  end

  it 'should widen search and reverse direction if narrow search fails to find enemy twice' do
    spinner_bot = SpinnerBotTestSituation.new.set_test_turn_radar.set_radar_heading(0).set_test_rounds(4).get_spinner_bot
    spinner_bot.set_old_radar_heading(300)
    spinner_bot.should_receive(:turn_radar).with(-30)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[500]})
    spinner_bot.stub!(:time).and_return(101)
    spinner_bot.should_receive(:turn_radar).with(-30)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[]})
    spinner_bot.stub!(:time).and_return(102)
    spinner_bot.should_receive(:turn_radar).with(-30)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[]})
    spinner_bot.stub!(:time).and_return(103)
    spinner_bot.should_receive(:turn_radar).with(60)
    spinner_bot.tick({"broadcasts"=>[["800.0,809.0,90.0,1"]], "robot_scanned"=>[]})
  end
end

