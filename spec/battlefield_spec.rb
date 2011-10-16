$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'spec_helper'

describe Battlefield do
  before :each do
    @battlefield = Battlefield.new 60, 60, 1000, 60
    @bullet = Bullet.new @battlefield, 20, 21, 180, 2, 5, 'robot'
  end

  it 'should create a new battlefield' do
    @battlefield.width.should == 60
    @battlefield.height.should == 60
    @battlefield.timeout.should == 1000
    @battlefield.seed.should == 60
  end

  it 'should be able to use the << operator to add a bullet' do
    @battlefield << @bullet
    @battlefield.bullets[0].should == @bullet
  end

  #Need to test << opperator
  #def << object
  #  case object
  #  when RobotRunner
  #    @robots << object
  #    @teams[object.team] << object
  #  when Bullet - DONE
  #    @bullets << object
  #  when Explosion
  #    @explosions << object
  #  end
  #end

  #specs to tst the following attributes
  # attr_reader :robots
  # attr_reader :teams
  # attr_reader :bullets
  # attr_reader :explosions
  # attr_reader :time
  # attr_reader :game_over
end