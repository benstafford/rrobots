$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '.')
require 'spec_helper'
require 'SpinnerBot'
require 'test_case'

describe 'SpinnerBot' do
  describe SpinnerBot do
    before :each do
      @spinnerbot = SpinnerBot.new
    end

    test_situations = [TestCase.new({"x"=>970,"y"=>800,"heading"=>90,"desired_turn"=>10}),
                       TestCase.new({"x"=>800,"y"=>970,"heading"=>180,"desired_turn"=>-10})]
    test_situations.each do |test_case|
      it "at #{test_case.x}, #{test_case.y} headed #{test_case.heading} should turn towards the target when too far away" do
        spinnerbot = SpinnerBot.new
        set_location(spinnerbot, [test_case.x,test_case.y],test_case.heading)
        spinnerbot.should_receive(:turn).with(test_case.desired_turn)
        spinnerbot.should_receive(:accelerate).with(1)
        spinnerbot.tick nil
      end
    end

    test_situations = [TestCase.new({"x"=>850,"y"=>800,"heading"=>90,"desired_turn"=>-10}),
                       TestCase.new({"x"=>800,"y"=>850,"heading"=>180,"desired_turn"=>10})]
    test_situations.each do |test_case|
      it "at #{test_case.x}, #{test_case.y} headed #{test_case.heading} should turn away from the target when too close" do
        spinnerbot = SpinnerBot.new
        set_location(spinnerbot, [test_case.x,test_case.y],test_case.heading)
        spinnerbot.should_receive(:turn).with(test_case.desired_turn)
        spinnerbot.should_receive(:accelerate).with(1)
        spinnerbot.tick nil
      end
    end

    test_situations = [TestCase.new({"x"=>925,"y"=>800,"heading"=>180,"desired_turn"=>10}),
                       TestCase.new({"x"=>800,"y"=>925,"heading"=>90,"desired_turn"=>10})]
    test_situations.each do |test_case|
      it "at #{test_case.x}, #{test_case.y} headed #{test_case.heading} should turn right angle from the target when in range" do
        spinnerbot = SpinnerBot.new
        set_location(spinnerbot, [test_case.x,test_case.y],test_case.heading)
        spinnerbot.should_receive(:turn).with(test_case.desired_turn)
        spinnerbot.should_receive(:accelerate).with(1)
        spinnerbot.tick nil
      end
    end

    def set_location spinnerbot, location, heading
      spinnerbot.stub!(:x).and_return(location[0])
      spinnerbot.stub!(:y).and_return(location[1])
      spinnerbot.stub!(:heading).and_return(heading)
      spinnerbot.stub(:speed).and_return(0)
    end
  end
end