$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'spec_helper'

describe Bullet do
  before :each do
    @battlefield = Battlefield.new 60, 60, 1000, 60
    @x_location = 1
    @y_location = 1
    @heading = 45
    @speed = 1
    @energy = 5
    @origin = 'robot'
    @bullet = Bullet.new @battlefield, @x_location, @y_location, @heading, @speed, @energy, @origin
  end

  it 'should create a new bullet' do
    @bullet.class.should == Bullet
  end
end