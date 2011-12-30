$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'NewInvader'

describe 'InvaderDriver' do
  before(:each) do
    @bot = NewInvader.new
    @bot.stub!(:time).and_return(0)
    @bot.stub!(:battlefield_width).and_return(1600)
    @bot.stub!(:battlefield_height).and_return(1600)
    @bot.stub!(:size).and_return(60)
    @driver = InvaderMovementEngine.new(@bot)
  end

  it 'Should immediately head to closest edge' do
    @bot.stub!(:x).and_return(80)
    @bot.stub!(:y).and_return(800)
    @bot.stub!(:heading).and_return(90)
    @driver.move
    @driver.turn.should == 10
    @driver.accelerate.should == 1
    @bot.heading_of_edge.should == 180
  end
  it 'Should immediately head to closest edge' do
    @bot.stub!(:x).and_return(800)
    @bot.stub!(:y).and_return(80)
    @bot.stub!(:heading).and_return(0)
    @driver.move
    @driver.turn.should == 10
    @driver.accelerate.should == 1
    @bot.heading_of_edge.should == 90
  end
  it 'Should immediately head to closest edge' do
    driver = InvaderDriverHeadToEdge.new(@bot, @driver)
    @bot.stub!(:x).and_return(1520)
    @bot.stub!(:y).and_return(800)
    @bot.stub!(:heading).and_return(270)
    driver.move
    @driver.turn.should == 10
    @driver.accelerate.should == 1
    @bot.heading_of_edge.should == 0
  end
  it 'Should immediately head to closest edge' do
    driver = InvaderDriverHeadToEdge.new(@bot, @driver)
    @bot.stub!(:x).and_return(800)
    @bot.stub!(:y).and_return(1520)
    @bot.stub!(:heading).and_return(180)
    driver.move
    @driver.turn.should == 10
    @driver.accelerate.should == 1
    @bot.heading_of_edge.should == 270
  end

  it 'Should select a different edge than its friend' do
    driver = InvaderDriverHeadToEdge.new(@bot, @driver)
    @bot.stub!(:x).and_return(800)
    @bot.stub!(:y).and_return(1520)
    @bot.stub!(:heading).and_return(180)
    @bot.friend_edge = 270
    driver.move
    @driver.turn.should == 10
    @driver.accelerate.should == 1
    @bot.heading_of_edge.should == 0
  end
end
