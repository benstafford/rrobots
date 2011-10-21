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

  it 'should move a bullet on a tick' do
    @bullet.tick
    @bullet.x.should == 1.7071067811865475
    @bullet.y.should == 1.2928932188134525
  end
end