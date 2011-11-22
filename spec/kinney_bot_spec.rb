$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')

require 'KinneyBot'
require 'robot'

describe KinneyBot do
  before(:each) do
    @bot = KinneyBot.new
    @events = {'broadcasts' => [["loc|5|10", "east"]], 'robot_scanned' => [[10.0]]}
  end

  it 'should recalculate y to a usable trig number' do
  end

  describe 'Eat it Sucka' do
    it 'should be able to find the approximate point for an enemy scanned' do
    end

    it 'should be able to find the approximate point for an enemy scanned below me' do
    end
  end

  describe 'Move your ass' do
    it 'should be able to find the middle of the map when the width and height are even numbers' do
    end
    
    it 'should be able to find the middle of the map when the width and height are odd numbers' do
    end

    it 'should get the opposite angle from two points' do
    end

    it 'should get the angle directly away from center' do
    end

    it 'should turn the tank 10 degrees if the difference between current heading and new heading are more than 10 degrees apart' do
    end

    it 'should turn the tank 8 degrees if the difference between current heading and new heading are 8 degrees apart' do
    end
  end

  describe 'Do not Shoot your partner' do
    it 'should be able to process events for my partners location' do
    end

    it 'should find the angle of between 2 points when point 1 is 5,5 and point 2 is 5,10' do
    end

    it 'should find the angle of between 2 points when point 1 is 5,5 and point 2 is 10,5' do
    end

    it 'should find the angle of between 2 points when point 1 is 5,5 and point 2 is 5,0' do
    end

    it 'should find the angle of between 2 points when point 1 is 5,5 and point 2 is 0,5' do
    end

    it 'should return true if 2 angles are withing 15 degrees of each other' do
    end

    it 'should return false if 2 angles are more than 15 degrees of each other' do
    end

    it 'should return true if 2 angles are exactly 15 degrees of each other' do
    end

    it 'should set KinneyBots x and y values in the beginning of a tick' do
    end

    it 'should set the angle to my partner in the beginning of a tick' do
    end

    it 'should not fire if partner angle and gun heading are within 15 degrees' do
    end

    it 'should fire if my partner angle and gun heading are not within 15 degrees' do
    end
  end
end