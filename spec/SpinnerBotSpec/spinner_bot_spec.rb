$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')
require 'spec_helper'
require 'SpinnerBot'

describe 'SpinnerBot' do
  describe SpinnerBot do
    before :each do
      @spinnerbot = SpinnerBot.new
    end

    test_situations = [{"x"=>150,"y"=>0,"heading"=>90,"desired_turn"=>10},
                       {"x"=>50,"y"=>50,"heading"=>180,"desired_turn"=>-10}]
    test_situations.each do |values|
      it "at #{values['x']}, #{values['y']} headed #{values['heading']} should turn towards the target at 50,0" do
        spinnerbot = SpinnerBot.new
        spinnerbot.target = [50,0]
        set_location(spinnerbot, [values["x"],values["y"]],values["heading"])
        spinnerbot.should_receive(:turn).with(values["desired_turn"])
        spinnerbot.tick nil
      end
    end

    def set_location spinnerbot, location, heading
      spinnerbot.stub!(:x).and_return(location[0])
      spinnerbot.stub!(:y).and_return(location[1])
      spinnerbot.stub!(:heading).and_return(heading)
    end
  end
end