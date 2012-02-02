$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '.')
require 'spec_helper'
require 'SpinnerBot'
require 'test_case'

describe 'SpinnerBot' do
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

    it 'should turn gun away from circle target' do
      spinner_bot = SpinnerBotTestSituation.new.set_gun_heading(180).set_test_turn_gun.get_spinner_bot
      spinner_bot.should_receive(:turn_gun).with(30)
      spinner_bot.tick({"broadcasts"=>[]})
    end
  end
end


class SpinnerBotTestSituation
  def initialize
    @x = 800
    @y = 1100
    @heading = 90
    @time = 100
    @speed = 0
    @gun_heading = 270
    @ignore_broadcast = true
    @ignore_accelerate = true
    @ignore_turn = true
    @ignore_gun_turn = true
  end

  def get_spinner_bot
    spinner_bot = SpinnerBot.new
    spinner_bot.stub!(:x).and_return(@x)
    spinner_bot.stub!(:y).and_return(@y)
    spinner_bot.stub!(:heading).and_return(@heading)
    spinner_bot.stub!(:speed).and_return(@speed)
    spinner_bot.stub!(:time).and_return(@time)
    spinner_bot.stub!(:gun_heading).and_return(@gun_heading)

    spinner_bot.should_receive(:accelerate) unless @ignore_accelerate == false
    spinner_bot.should_receive(:broadcast) unless @ignore_broadcast == false
    spinner_bot.should_receive(:turn) unless @ignore_turn == false
    spinner_bot.should_receive(:turn_gun) unless @ignore_gun_turn == false
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

  def set_test_turn
    @ignore_turn = false
    self
  end

  def set_test_turn_gun
    @ignore_gun_turn = false
    self
  end

  def set_test_broadcast
    @ignore_broadcast = false
    self
  end
end