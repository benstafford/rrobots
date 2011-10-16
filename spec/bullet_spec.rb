$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'spec_helper'

describe Bullet do
  before :each do
    @battlefield = Battlefield.new 60, 60, 1000, 60
    @x_location = 20
    @y_location = 21
    @heading = 180
    @speed = 2
    @energy = 5
    @origin = 'robot'
  end

  it 'should create a new bullet' do
    bullet = Bullet.new @battlefield, @x_location, @y_location, @heading, @speed, @energy, @origin
    bullet.class.should == Bullet
  end
end